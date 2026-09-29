// Invitation codes: what a card carries, and forgiving typing.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/bytes.dart';
import 'package:murmur_client/protocol/invite.dart';
import 'package:murmur_client/protocol/network.dart';
import 'package:murmur_client/services/fees.dart';
import 'package:murmur_client/services/invitations.dart';
import 'package:murmur_client/services/storage.dart';

/// Crockford base32, as the codes use it (for building a version 1 code).
String _base32(List<int> bytes) {
  const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  final bits = bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join();
  final padded = bits.padRight((bits.length + 4) ~/ 5 * 5, '0');
  return [for (var i = 0; i < padded.length; i += 5) alphabet[int.parse(padded.substring(i, i + 5), radix: 2)]].join();
}

void main() {
  final genesis = NetworkInfo.whitepaper.genesisHeader().hash;
  final seed = Uint8List.fromList(List.generate(32, (i) => i * 7));

  test('a card remembers the wallet that funded it; older records still load without it', () {
    final funder = 'ab' * 32;
    final saved = InviteRecord(code: 'C', amount: 5, serial: 1, batch: 2, funder: funder).toJson();
    expect(InviteRecord.fromJson(jsonDecode(jsonEncode(saved)))!.funder, funder);
    final old = InviteRecord.fromJson({'code': 'C', 'amount': 5, 'serial': 1, 'batch': 2, 'tookBack': true})!;
    expect((old.funder, old.tookBack), (null, true));
  });
  final invite = Invite(network: Uint8List.fromList(genesis.sublist(0, 4)), seed: seed);

  test('a code carries network and key, and reads back', () {
    final code = invite.code;
    expect(code.replaceAll('-', ''), hasLength(66));
    expect(code, matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{5}(-[0-9A-HJKMNP-TV-Z]{1,5})+$')));
    final back = Invite.parse(code)!;
    expect(back.seed, seed);
    expect(back.isFor(genesis), isTrue);
    expect(back.isFor(NetworkInfo.demo.genesisHeader().hash), isFalse);
  });

  test('version 1 codes, which carried an expiry day, still read', () {
    final body = [1, ...genesis.sublist(0, 4), 0x51, 0x2c, ...seed];
    final v1 = _base32([...body, ...sha256Bytes(body).sublist(0, 4)]);
    expect(Invite.parse(v1)?.seed, seed);
  });

  test('typing is forgiven: case, spaces, dashes, O for 0, I or L for 1, a whole link', () {
    final code = invite.code;
    for (final typed in [
      code.toLowerCase(),
      code.replaceAll('-', ' '),
      code.replaceAll('-', ''),
      code.replaceAll('0', 'O').replaceAll('1', 'I'),
      inviteLink('https://app.murmur.info', code),
    ]) {
      expect(Invite.parse(typed)?.seed, seed, reason: typed);
    }
  });

  test('a mistyped character is caught by the checksum', () {
    final code = invite.code;
    final i = code.indexOf(RegExp('[2-9]'), 20);
    final wrong = code.replaceRange(i, i + 1, code[i] == '2' ? '3' : '2');
    expect(Invite.parse(wrong), isNull);
    expect(Invite.parse('not a code'), isNull);
    expect(Invite.parse(''), isNull);
  });

  test('a card holds five threads and its claim fee', () {
    final fees = estimateFees(pending: const [], maxBlockBytes: 2000000, recentBlockMins: const []);
    final costs = invitationCosts(fees);
    // At the minimum fee of 1: five threads at 11 each, plus 1 to claim.
    expect((costs.perCard, costs.fundingFee, costs.claimFee), (56, 1, 1));
    expect(inviteInRoute('/invite/${invite.code}'), invite.code);
    expect(inviteInRoute('/thread/abc'), isNull);
  });
}
