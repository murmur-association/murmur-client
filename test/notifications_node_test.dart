// Android's background check for news (ui/notifications_background_io.dart)
// against the real node: a run of its own, from the device's settings, that
// tells the wallet of what came, and tells it once. See node_test.dart for
// the node these tests use.

import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/crypto/wallet.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/models.dart';
import 'package:murmur_client/services/key_vault.dart' show encodeStored;
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/notifications_background_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/notifier.dart';
import 'support/test_node.dart';

void main() {
  test('a background run tells a wallet of a reply in its thread and of a mention, once', () async {
    final miner = await MurmurWallet.generate();
    final me = await MurmurWallet.generate();
    Uint8List utf(String s) => MurmurClient.encodeText(s);
    bool mined(MurmurClient c, Transaction tx) => c.lookupTx(tx.id)?.confirmed ?? false;

    final node = await TestNode.build(300, mineTo: miner.address);
    await node.start(mineTo: miner.address);
    final writer = await node.connect(MurmurClient());
    await until(writer, () => writer.availableTo(miner.addressHex) != null);
    final fund = await writer.submit(
        wallet: miner, kind: TxKind.raw, to: me.address, amount: 10 * unitsPerToken, fee: minFee);
    await until(writer, what: 'the wallet funded', () => mined(writer, fund) && (writer.availableTo(me.addressHex) ?? 0) > 0);
    final thread = await writer.submit(wallet: me, kind: TxKind.orphan, fee: minFee, message: utf('my thread'));
    await until(writer, what: 'its thread mined', () => mined(writer, thread));

    // The device: its wallet, the node, and notifications switched on now.
    SharedPreferences.setMockInitialValues({
      'node_host': '127.0.0.1',
      'node_port': node.port,
      'notify_topics': ['replies', 'mentions'],
      'notified_until': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    FlutterSecureStorage.setMockInitialValues({
      'murmur_wallet': encodeStored({'protection': 'passphrase', 'address': me.addressHex, 'publicKey': toHex(me.publicKey)}),
    });

    final reply = await writer.submit(
        wallet: miner, kind: TxKind.reply, amount: minFee, fee: minFee, message: utf('a reply for you'), reference: thread.id);
    final mention = await writer.submit(
        wallet: miner, kind: TxKind.orphan, fee: minFee, message: utf('hello @you'), mentions: [me.addressHex]);
    await until(writer, what: 'the reply and the mention mined', () => mined(writer, reply) && mined(writer, mention));

    final notifier = RecordingNotifier();
    expect(await checkNewsInBackground(notifier: notifier), 2);
    final l = lookupAppLocalizations(const Locale('en'));
    final who = shortHex(miner.addressHex);
    expect({for (final s in notifier.shown) s.body: s.title}, {
      'a reply for you': l.notifyReply(who),
      'hello @you': l.notifyMention(who),
    });

    // The next run has nothing new to tell.
    expect(await checkNewsInBackground(notifier: notifier), 0);
    expect(notifier.shown, hasLength(2));
  }, skip: nodeSkip, timeout: const Timeout(Duration(minutes: 4)));
}
