// What a transaction is to one address, for the Messages and Wallet filters.
// A transaction can fall under several filters (a reply to yourself is both
// sent and received); it's shown if any of its filters is on.

import '../protocol/models.dart';
import 'node_client.dart';

/// Messages tab: messages only, never plain transfers.
enum MessageFilter {
  /// Threads this address started.
  threads,

  /// Replies it sent.
  sent,

  /// Replies to it.
  received,

  /// Flags it raised.
  flagsSent,

  /// Flags against its messages.
  flagsReceived;

  /// Flags are off until the user turns them on.
  static const defaults = {threads, sent, received};
}

/// Wallet tab: token movements.
enum WalletFilter {
  transfersSent,
  transfersReceived,

  /// Amounts paid to authors by replying.
  repliesPaid,

  /// Amounts earned from replies to this address's messages.
  repliesEarned,

  /// Fee and burn of each thread started.
  threadCosts,

  /// Fees paid for flags.
  flagCosts;

  static const defaults = {transfersSent, transfersReceived};
}

Set<MessageFilter> messageFiltersOf(TxView v, String me, MurmurClient client) {
  final tx = v.tx;
  final mine = tx.fromAddress == me;
  return switch (tx.kind) {
    TxKind.orphan => {if (mine) MessageFilter.threads},
    TxKind.reply => {
        if (mine) MessageFilter.sent,
        // In one of the wallet's threads, or an answer to one of its
        // replies in someone else's.
        if (client.creditedBy(tx) == me || (!mine && client.answersTo(tx, me))) MessageFilter.received,
      },
    TxKind.flag => {
        if (mine) MessageFilter.flagsSent,
        if (tx.referenceId != null && client.authorOf(tx.referenceId!) == me) MessageFilter.flagsReceived,
      },
    TxKind.raw || TxKind.name => const {},
  };
}

Set<WalletFilter> walletFiltersOf(TxView v, String me, MurmurClient client) {
  final tx = v.tx;
  final mine = tx.fromAddress == me;
  final toMe = client.creditedBy(tx) == me;
  return switch (tx.kind) {
    TxKind.raw => {if (mine) WalletFilter.transfersSent, if (toMe) WalletFilter.transfersReceived},
    TxKind.reply => {if (mine) WalletFilter.repliesPaid, if (toMe) WalletFilter.repliesEarned},
    TxKind.orphan || TxKind.name => {if (mine) WalletFilter.threadCosts},
    TxKind.flag => {if (mine) WalletFilter.flagCosts},
  };
}
