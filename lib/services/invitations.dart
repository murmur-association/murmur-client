// Making, claiming and cancelling invitations (protocol/invite.dart). A
// card is a wallet of its own: the inviter funds it with an ordinary
// transfer, and claiming (or cancelling, which takes the tokens back) moves
// everything on it to another wallet in one transfer, whose fee comes out
// of the card. Cards don't expire. Nothing here needs a protocol change.

import 'dart:math';
import 'dart:typed_data';

import '../crypto/wallet.dart';
import '../protocol/bytes.dart';
import '../protocol/invite.dart';
import '../protocol/models.dart';
import 'node_client.dart';
import 'storage.dart';

/// Threads a card pays for.
const inviteThreads = 5;

/// The message size a card's threads are priced for: a few sentences.
const _typicalMessage = 280;

/// What a card needs to hold, and what funding it costs, at `fees`.
({int perCard, int fundingFee, int claimFee}) invitationCosts(FeeInfo fees) {
  final threadFee = fees.suggested(txWeight(saltLength + _typicalMessage));
  final transferFee = max(minFee, fees.suggested(txBaseBytes));
  return (
    perCard: inviteThreads * threadFee * (orphanBurnMultiple + 1) + transferFee,
    fundingFee: transferFee,
    claimFee: transferFee,
  );
}

/// Makes `count` cards funded by `wallet`, `perCard` each. The cards'
/// records and codes (which hold their keys) are handed to `keep` (normally
/// `InviteStore.add`, which stores the codes encrypted) before anything is
/// paid to them, so a funded key is never lost; if `keep` throws, nothing
/// is paid. Returns their records.
Future<List<InviteRecord>> createInvitations({
  required MurmurClient client,
  required MurmurWallet wallet,
  required Future<void> Function(List<InviteRecord> records, List<String> codes) keep,
  required int count,
  required int perCard,
  required int fundingFee,
}) async {
  final genesis = client.genesis;
  if (genesis == null) throw const TxProblem(TxProblemKind.notLive);
  final rng = Random.secure();
  final records = <InviteRecord>[], codes = <String>[];
  for (var i = 0; i < count; i++) {
    final invite = Invite(
      network: Uint8List.fromList(genesis.sublist(0, 4)),
      seed: Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256))),
    );
    codes.add(invite.code);
    records.add(InviteRecord(
      address: (await cardWallet(invite)).addressHex,
      amount: perCard,
      serial: i + 1,
      batch: count,
      funder: wallet.addressHex,
    ));
  }
  await keep(records, codes);
  for (final r in records) {
    await client.submit(wallet: wallet, kind: TxKind.raw, to: fromHex(r.address), amount: perCard, fee: fundingFee);
  }
  return records;
}

/// The card's own wallet.
Future<MurmurWallet> cardWallet(Invite invite) => MurmurWallet.fromSeed(invite.seed);

/// Moves everything on the card to `to` (the newcomer's wallet, or the
/// inviter's when cancelling it). Needs the card's balance proven.
Future<Transaction> sweepInvitation({
  required MurmurClient client,
  required Invite invite,
  required Uint8List to,
}) async {
  final card = await cardWallet(invite);
  final available = client.availableTo(card.addressHex);
  if (available == null) throw const TxProblem(TxProblemKind.checkingBalance);
  final fee = max(minFee, (await client.feeInfo()).suggested(txBaseBytes));
  if (available - fee < fee) throw TxProblem(TxProblemKind.insufficientBalance, fee * 2, available);
  return client.submit(wallet: card, kind: TxKind.raw, to: to, amount: available - fee, fee: fee);
}

/// The address that funded the card: the inviter, once their transfer is
/// known (the card's history is followed through its filter). The oldest
/// transfer in, since anyone may send more to a card later.
String? inviterOf(MurmurClient client, String cardAddress) {
  String? oldest;
  for (final v in client.activityOf(cardAddress)) {
    if (v.tx.toAddress == cardAddress && v.tx.fromAddress != cardAddress) oldest = v.tx.fromAddress;
  }
  return oldest;
}

/// Where a card stands, from its proven balance.
enum InviteState { checking, waiting, claimed, cancelled }

InviteState inviteState(MurmurClient client, InviteRecord r) {
  final cardAddress = r.address;
  if (r.tookBack) return InviteState.cancelled;
  final balance = client.availableTo(cardAddress);
  if (balance == null) return InviteState.checking;
  // Funded, or still being funded (the transfer is pending).
  final funding = client.activityOf(cardAddress).any((v) => !v.confirmed && v.tx.toAddress == cardAddress);
  return balance > 0 || funding ? InviteState.waiting : InviteState.claimed;
}

/// The link a card's QR code holds.
String inviteLink(String base, String code) => '$base/#/invite/$code';

/// The code a route name (a link's `#/invite/<code>`) carries, if any.
String? inviteInRoute(String? name) => RegExp(r'^/invite/([0-9A-Za-z-]+)$').firstMatch(name ?? '')?.group(1);
