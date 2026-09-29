// Localization helpers. Every user-facing text lives in the ARB files in
// lib/l10n (ICU message format, compiled by Flutter's gen-l10n); numbers and
// dates are formatted for the current locale with intl.

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../protocol/wire.dart' show protocolVersion;
import '../services/node_client.dart';

export '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The languages offered, each named in itself (as language menus do).
const languageNames = {
  'en': 'English',
  'es': 'Español',
  'it': 'Italiano',
  'pt': 'Português',
  'de': 'Deutsch',
  'nl': 'Nederlands',
  'ar': 'العربية',
  'zh': '中文',
  'ja': '日本語',
};

/// A whole number with the locale's digit grouping: 1,234,567 in English,
/// 1.234.567 in Spanish.
String formatAmount(BuildContext context, int value) =>
    NumberFormat.decimalPattern(context.l10n.localeName).format(value);

/// An amount with its sign, for balance changes.
String formatSigned(BuildContext context, int value) =>
    value >= 0 ? '+${formatAmount(context, value)}' : '-${formatAmount(context, -value)}';

String formatTime(BuildContext context, int unixSecs) {
  final locale = context.l10n.localeName;
  return DateFormat.yMd(locale).add_Hms().format(DateTime.fromMillisecondsSinceEpoch(unixSecs * 1000));
}

/// A local time of day, with the date only when it isn't today.
String formatClock(BuildContext context, int unixSecs) {
  final locale = context.l10n.localeName;
  final t = DateTime.fromMillisecondsSinceEpoch(unixSecs * 1000);
  final now = DateTime.now();
  final today = t.year == now.year && t.month == now.month && t.day == now.day;
  return (today ? DateFormat.Hms(locale) : DateFormat.yMd(locale).add_Hms()).format(t);
}

/// When something happened, for lists: "just now", "5 min ago", "3 h ago",
/// "2 d ago", and the date once it's a month old. Detail pages show the
/// full time ([formatTime]).
String formatAgo(BuildContext context, int unixSecs) {
  final l = context.l10n;
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final secs = now > unixSecs ? now - unixSecs : 0; // miners' clocks run slightly ahead
  if (secs < 60) return l.timeJustNow;
  if (secs < 3600) return l.timeMinutesAgo(secs ~/ 60);
  if (secs < 86400) return l.timeHoursAgo(secs ~/ 3600);
  if (secs < 30 * 86400) return l.timeDaysAgo(secs ~/ 86400);
  return DateFormat.yMd(l.localeName).format(DateTime.fromMillisecondsSinceEpoch(unixSecs * 1000));
}

/// How long ago `unixSecs` was, in its two largest units ("5 min 12 s ago").
String formatElapsed(BuildContext context, int unixSecs) {
  final l = context.l10n;
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  // Block times come from the miner's clock, so they can be slightly ahead.
  // (No `1 << 40`-style bound here: on the web, shifts are 32-bit.)
  final secs = now > unixSecs ? now - unixSecs : 0;
  final (d, h, m, s) = (secs ~/ 86400, secs ~/ 3600 % 24, secs ~/ 60 % 60, secs % 60);
  if (d > 0) return l.agoDays(d, h);
  if (h > 0) return l.agoHours(h, m);
  if (m > 0) return l.agoMinutes(m, s);
  return l.agoSeconds(s);
}

String linkErrorText(AppLocalizations l, LinkError e) => switch (e.kind) {
      LinkErrorKind.unreachable => l.errUnreachable(e.detail),
      LinkErrorKind.bridgeUnreachable => l.errBridgeUnreachable(e.detail),
      LinkErrorKind.connection => l.errConnection(e.detail),
      LinkErrorKind.closed => l.errClosed,
      LinkErrorKind.timeout => l.errTimeout,
      LinkErrorKind.protocol => l.errProtocol(e.detail),
      LinkErrorKind.version => l.errVersion(e.nodeVersion, protocolVersion),
      LinkErrorKind.syncFailed =>
        l.errSyncFailed(e.cause == null ? e.detail : linkErrorText(l, e.cause!)),
      LinkErrorKind.ignoredBlock => l.errIgnoredBlock(e.detail),
      LinkErrorKind.tampered => l.errTampered,
      LinkErrorKind.stateMismatch => l.errStateMismatch(e.height),
      LinkErrorKind.checkpointMismatch => l.errCheckpointMismatch(e.height),
      LinkErrorKind.other => e.detail,
    };

String txProblemText(AppLocalizations l, TxProblem p) => switch (p.kind) {
      TxProblemKind.feeTooLow => l.probFeeTooLow,
      TxProblemKind.malformed => l.probMalformed,
      TxProblemKind.needsMessage => l.probNeedsMessage,
      TxProblemKind.needsRecipient => l.probNeedsRecipient,
      TxProblemKind.amountBelowFee => l.probAmountBelowFee(p.a),
      TxProblemKind.replyParentNotMined => l.probReplyParentNotMined,
      TxProblemKind.replyWrongRecipient => l.probReplyWrongRecipient,
      TxProblemKind.flagNotMessage => l.probFlagNotMessage,
      TxProblemKind.alreadyFlagged => l.probAlreadyFlagged,
      TxProblemKind.messageTooLong => l.probMessageTooLong(p.a, p.b),
      TxProblemKind.insufficientBalance => l.probInsufficientBalance(p.a, p.b),
      TxProblemKind.checkingBalance => l.checkingBalance,
      TxProblemKind.notLive => l.probNotLive,
      TxProblemKind.connectionLost => l.probConnectionLost,
      TxProblemKind.duplicate => l.probDuplicate,
    };
