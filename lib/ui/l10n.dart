// Localization helpers. Every user-facing text lives in the ARB files in
// lib/l10n (ICU message format, compiled by Flutter's gen-l10n); numbers and
// dates are formatted for the current locale with intl.

import 'package:flutter/services.dart' show TextEditingValue, TextInputFormatter;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../protocol/models.dart' show unitsPerToken;
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
  'fr': 'Français',
  'it': 'Italiano',
  'pt': 'Português',
  'de': 'Deutsch',
  'nl': 'Nederlands',
  'ar': 'العربية',
  'zh': '中文',
  'ja': '日本語',
  'ko': '한국어',
};

/// A whole number with the locale's digit grouping: 1,234,567 in English,
/// 1.234.567 in Spanish. For counts and heights; amounts go through
/// [formatAmount].
String formatCount(BuildContext context, int value) =>
    NumberFormat.decimalPattern(context.l10n.localeName).format(value);

/// An amount, given in units as the chain holds it, in tokens as people read
/// it: the locale's digit grouping and up to six decimals, without trailing
/// zeros (1,234.5 in English, 1.234,5 in Spanish). Units are never shown.
String formatAmount(BuildContext context, int units) => formatAmountIn(context.l10n.localeName, units);

/// [formatAmount] where only the locale is at hand. Whole and fraction are
/// formatted apart, as integers: no amount goes through a floating-point
/// number.
String formatAmountIn(String locale, int units) {
  if (units < 0) return '-${formatAmountIn(locale, -units)}';
  final format = NumberFormat.decimalPattern(locale);
  final whole = format.format(units ~/ unitsPerToken);
  var fraction = units % unitsPerToken;
  if (fraction == 0) return whole;
  var digits = 6;
  while (fraction % 10 == 0) {
    fraction ~/= 10;
    digits--;
  }
  return '$whole${format.symbols.DECIMAL_SEP}${NumberFormat('0' * digits, locale).format(fraction)}';
}

/// An amount as a field holds it, for the user to edit: tokens with the
/// locale's decimal separator, plain digits, no grouping.
String amountText(BuildContext context, int units) {
  final separator = NumberFormat.decimalPattern(context.l10n.localeName).symbols.DECIMAL_SEP;
  final fraction = (units % unitsPerToken).toString().padLeft(6, '0').replaceFirst(RegExp(r'0+$'), '');
  return '${units ~/ unitsPerToken}${fraction.isEmpty ? '' : '$separator$fraction'}';
}

/// The characters an amount field takes as its decimal separator: a point
/// and a comma in every language, and the locale's own. A phone's numeric
/// keyboard has only its region's (a Spanish one no point), whatever the
/// app's language, so either must do; fields never hold digit grouping
/// ([amountText]), which leaves neither ambiguous.
final _decimalMarks = RegExp('[.,٫]');

/// What the user typed as an amount, in units, or null if it isn't one:
/// tokens with up to six decimals after one decimal separator, a point or a
/// comma whatever the language ([_decimalMarks]). Digit grouping isn't taken:
/// "1.234" is one token and a fraction in every language, and "1,234.5" is
/// refused rather than guessed.
int? parseAmount(BuildContext context, String typed) {
  final text = typed.trim().replaceAll(RegExp(r"[\s'’_]"), '');
  final parts = text.split(_decimalMarks);
  if (parts.length > 2) return null;
  final whole = parts[0];
  final fraction = parts.length == 2 ? parts[1] : '';
  // Fifteen digits of tokens are far more than exist, and stay exact.
  if (!RegExp(r'^\d{1,9}$').hasMatch(whole) || !RegExp(r'^\d{0,6}$').hasMatch(fraction)) return null;
  return int.parse(whole) * unitsPerToken + int.parse(fraction.padRight(6, '0'));
}

/// Writes a point or a comma typed in an amount field as the locale's
/// decimal separator, so the field reads as the language does whichever
/// key the keyboard had ([parseAmount] takes either).
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter(BuildContext context)
      : _separator = NumberFormat.decimalPattern(context.l10n.localeName).symbols.DECIMAL_SEP;

  final String _separator;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(_decimalMarks, _separator);
    // One character for one: the cursor and selection stay where they were.
    return text == newValue.text || _separator.length != 1 ? newValue : newValue.copyWith(text: text);
  }
}

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
      LinkErrorKind.badSignature => l.errBadSignature(e.height),
      LinkErrorKind.other => e.detail,
    };

String txProblemText(AppLocalizations l, TxProblem p) => switch (p.kind) {
      TxProblemKind.feeTooLow => l.probFeeTooLow,
      TxProblemKind.malformed => l.probMalformed,
      TxProblemKind.needsMessage => l.probNeedsMessage,
      TxProblemKind.needsRecipient => l.probNeedsRecipient,
      TxProblemKind.amountBelowFee => l.probAmountBelowFee(formatAmountIn(l.localeName, p.a)),
      TxProblemKind.replyParentNotMined => l.probReplyParentNotMined,
      TxProblemKind.flagNotMessage => l.probFlagNotMessage,
      TxProblemKind.alreadyFlagged => l.probAlreadyFlagged,
      TxProblemKind.messageTooLong => l.probMessageTooLong(p.a, p.b),
      TxProblemKind.insufficientBalance =>
        l.probInsufficientBalance(formatAmountIn(l.localeName, p.a), formatAmountIn(l.localeName, p.b)),
      TxProblemKind.checkingBalance => l.checkingBalance,
      TxProblemKind.notLive => l.probNotLive,
      TxProblemKind.connectionLost => l.probConnectionLost,
      TxProblemKind.duplicate => l.probDuplicate,
    };
