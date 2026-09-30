import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../crypto/wallet.dart' show WalletId;
import '../protocol/alias.dart';
import '../protocol/bytes.dart';
import '../protocol/models.dart';
import '../services/node_client.dart';
import 'brand.dart';
import 'common.dart';
import 'thread_page.dart';
import 'tx_page.dart';
import 'unlock.dart';
import 'glyphs.dart';

/// Builds, signs and sends a transaction: a new thread (an Orphan) or a
/// transfer, as `kind` says. With `replyTo` it sends a Reply to that message,
/// and with `flagTarget` a Flag reporting that message. Replies and flags
/// name their target by txid (`reference`, PROTOCOL.md Section 2.3). With
/// `alias` it publishes the wallet's alias (an Orphan with a fixed message,
/// Section 7.8; empty clears it).
///
/// Ctrl+Enter (Cmd+Enter on Apple devices) sends, like the button. Either
/// way a summary of everything signed comes first, as the last confirmation.
class ComposePage extends StatefulWidget {
  const ComposePage({super.key, this.kind = TxKind.orphan, this.to, this.flagTarget, this.replyTo, this.alias});

  final TxKind kind;
  final String? to;
  final TxView? flagTarget;
  final TxView? replyTo;

  /// The alias to publish; already checked (`aliasProblem`).
  final String? alias;

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _formKey = GlobalKey<FormState>();
  late final TxKind _kind = widget.replyTo != null
      ? TxKind.reply
      : widget.flagTarget != null
          ? TxKind.flag
          : (widget.kind == TxKind.raw ? TxKind.raw : TxKind.orphan);
  late final _to = TextEditingController(text: widget.replyTo?.tx.fromAddress ?? widget.to ?? '');
  final _amount = TextEditingController(text: '1');
  final _fee = TextEditingController(text: '1');
  final _message = TextEditingController();
  bool _sending = false;
  FeeInfo? _feeInfo;
  bool _feeLoading = false;

  /// Once the user types a fee or amount, suggestions stop overwriting it.
  bool _feeEdited = false;
  bool _amountEdited = false;

  /// The summary is open: the shortcut mustn't open a second one.
  bool _confirming = false;

  bool get _isFlag => widget.flagTarget != null;
  bool get _isReply => widget.replyTo != null;

  /// Replies and transfers pay someone; threads and flags don't.
  bool get _hasRecipient => _kind == TxKind.reply || _kind == TxKind.raw;

  @override
  void initState() {
    super.initState();
    // Fees are per byte, so the suggestion follows the message's length.
    _message.addListener(() => setState(() {
          if (_feeInfo != null) _applyFee(_feeInfo!.suggested(_weight));
        }));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadFee();
    });
  }

  Future<void> _loadFee() async {
    setState(() => _feeLoading = true);
    final info = await AppScope.of(context).client.feeInfo();
    if (!mounted) return;
    setState(() {
      _feeInfo = info;
      _feeLoading = false;
      _applyFee(info.suggested(_weight));
    });
  }

  /// Puts `fee` in the fee field (unless the user typed their own), and
  /// keeps an untouched amount at the `amount >= fee` floor that replies
  /// and transfers must meet.
  void _applyFee(int fee, {bool force = false}) {
    if (force || !_feeEdited) {
      _fee.text = '$fee';
      if (force) _feeEdited = false;
    }
    final amount = _parseAmount(_amount.text) ?? 0;
    final current = _parseAmount(_fee.text) ?? fee;
    if (!_amountEdited && amount < current) _amount.text = '$current';
  }

  @override
  void dispose() {
    _to.dispose();
    _amount.dispose();
    _fee.dispose();
    _message.dispose();
    super.dispose();
  }

  Uint8List? _messageBytes() {
    if (_kind == TxKind.flag || _kind == TxKind.raw) return null;
    if (widget.alias != null) return aliasMessage(widget.alias!);
    return MurmurClient.encodeText(_message.text);
  }

  /// What the message says, for the summary.
  String _messageShown(BuildContext context) {
    final alias = widget.alias;
    if (alias == null) return _message.text;
    return alias.isEmpty ? context.l10n.aliasCleared : context.l10n.aliasSetTo(alias);
  }

  /// What this transaction will weigh: 264 bytes plus its content (the
  /// 16-byte salt and the message).
  int get _weight {
    final message = _messageBytes();
    return txWeight(message == null ? 0 : saltLength + message.length);
  }

  /// Whole numbers, with or without the locale's digit grouping. Only its
  /// own group separator is dropped, so "1.5" in English is refused rather
  /// than read as 15.
  int? _parseAmount(String s) {
    final group = NumberFormat.decimalPattern(context.l10n.localeName).symbols.GROUP_SEP;
    final v = int.tryParse(s.trim().replaceAll(group, '').replaceAll(RegExp(r"[\s'’_]"), ''));
    return (v == null || v < 0) ? null : v;
  }

  /// Whether sending is possible now: what the button's enabled state and
  /// the shortcut both follow.
  bool _canSend(MurmurClient client, WalletId wallet) =>
      !_sending &&
      !_confirming &&
      client.state == LinkState.live &&
      client.availableTo(wallet.addressHex) != null &&
      (!_isFlag || client.provenFlagged(wallet.addressHex, widget.flagTarget!.tx.id) != null);

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final scope = AppScope.of(context);
    final l = context.l10n;
    // What will be signed, fixed now: the summary shows exactly this.
    final from = scope.wallets.wallet!.addressHex;
    final to = _hasRecipient ? fromHex(_to.text.trim()) : null;
    final fee = _parseAmount(_fee.text)!;
    final amount = _hasRecipient ? _parseAmount(_amount.text)! : (_kind == TxKind.orphan ? orphanBurn(fee) : 0);
    final message = _messageBytes();
    final reference = widget.replyTo?.tx.id ?? widget.flagTarget?.tx.id;
    // What can't be sent is said before the summary and the unlock. The
    // summary checks again as blocks and transactions arrive.
    TxProblem? check(MurmurClient client) => client.state != LinkState.live
        ? const TxProblem(TxProblemKind.notLive)
        : client.checkTransaction(
            fromAddress: from, kind: _kind, to: to, amount: amount, fee: fee, message: message, reference: reference);
    final problem = check(scope.client);
    if (problem != null) {
      showSnack(context, txProblemText(l, problem));
      return;
    }
    // Rebuilt both ways, so the button follows (a new block may rebuild the
    // page while the summary is open).
    setState(() => _confirming = true);
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => _SendSummary(
        kind: _kind,
        typeName: widget.alias != null ? l.publicName : null,
        from: from,
        to: to == null ? null : toHex(to),
        target: widget.replyTo ?? widget.flagTarget,
        message: message == null ? null : _messageShown(context),
        weight: _weight,
        fee: fee,
        burn: _kind == TxKind.orphan ? amount : null,
        paid: _hasRecipient ? amount : null,
        check: check,
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (sure != true) return;
    setState(() => _sending = true);
    try {
      // The key, for this one transaction: the device's check or the
      // passphrase, every time.
      final wallet = await unlockWallet(context, reason: l.authReasonSend);
      if (wallet == null) return;
      final tx = await scope.client.submit(
        wallet: wallet,
        kind: _kind,
        to: to,
        amount: amount,
        fee: fee,
        message: message,
        reference: reference,
      );
      if (!mounted) return;
      // Show a new thread or reply in its thread; anything else on its own page.
      final rootId = _isFlag || _kind == TxKind.raw || widget.alias != null
          ? null
          : (_isReply ? scope.client.threadRootOf(widget.replyTo!)?.tx.id : tx.id);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => rootId == null ? TxPage(txid: tx.id) : ThreadPage(rootTxid: rootId, focusTxid: tx.id),
      ));
    } on TxProblem catch (e) {
      if (mounted) showSnack(context, txProblemText(l, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppBuilder(builder: (context, client, wallets) {
      final wallet = wallets.wallet;
      if (wallet == null) {
        return Scaffold(
          appBar: AppBar(title: Text(l.newTransaction)),
          body: EmptyState(icon: Glyph.keyOff, text: l.createWalletFirst),
        );
      }
      // Balance and nonce, proven against the tip; null until the proof arrives.
      final available = client.availableTo(wallet.addressHex);
      // A flag also needs proof this wallet hasn't flagged the message before.
      final flagChecked =
          !_isFlag || client.provenFlagged(wallet.addressHex, widget.flagTarget!.tx.id) != null;
      final ready = available != null && flagChecked;
      final canSend = _canSend(client, wallet);
      final msgBytes = MurmurClient.encodeText(_message.text).length;
      final fee = _parseAmount(_fee.text);
      final apple = {TargetPlatform.iOS, TargetPlatform.macOS}.contains(Theme.of(context).platform);

      return CallbackShortcuts(
        bindings: {
          SingleActivator(LogicalKeyboardKey.enter, control: !apple, meta: apple): () {
            if (_canSend(client, wallet)) _send();
          },
        },
        child: Scaffold(
        appBar: AppBar(
          title: Text(_isFlag
              ? l.flagMessage
              : _isReply
                  ? l.kindReply
                  : widget.alias != null
                      ? l.publicName
                      : (_kind == TxKind.orphan ? l.newThread : l.newTransaction)),
        ),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (_isFlag)
              Card(
                child: ListTile(
                  leading: const MurmurIcon(Glyph.flag),
                  title: Text(
                    messageOrUnavailable(context, widget.flagTarget!).replaceAll('\n', ' '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Flagging one's own message withdraws it (see the Threads tab).
                  subtitle: Text(widget.flagTarget!.tx.fromAddress == wallet.addressHex
                      ? l.flagOwnInfo
                      : l.flaggingInfo(nameOf(context, widget.flagTarget!.tx.fromAddress))),
                ),
              )
            else if (_isReply)
              Card(
                child: ListTile(
                  leading: const MurmurIcon(Glyph.reply),
                  title: Text(
                    messageOrUnavailable(context, widget.replyTo!).replaceAll('\n', ' '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(l.replyingTo(nameOf(context, widget.replyTo!.tx.fromAddress))),
                ),
              )
            else if (widget.alias != null)
              Card(
                child: ListTile(
                  leading: AddressAvatar(wallet.addressHex),
                  title: Text(_messageShown(context)),
                  subtitle: widget.alias!.isEmpty
                      ? null
                      : Text(publicNameOf(widget.alias!, wallet.addressHex), style: mono),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              switch (_kind) {
                TxKind.flag => '',
                TxKind.orphan when widget.alias != null => l.explainAlias(orphanBurnMultiple + 1, orphanBurnMultiple),
                TxKind.orphan => l.explainThread(orphanBurnMultiple + 1, orphanBurnMultiple),
                TxKind.reply => l.explainReply,
                TxKind.raw => l.explainTransfer,
              },
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (_kind == TxKind.raw) ...[
              TextFormField(
                controller: _to,
                style: mono,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l.recipientAddress, border: const OutlineInputBorder()),
                validator: (v) => tryParseHash32(v ?? '') == null ? l.enterAddress : null,
              ),
              const SizedBox(height: 12),
            ],
            _FeeCard(
              info: _feeInfo,
              weight: _weight,
              loading: _feeLoading,
              onRefresh: _loadFee,
              onUse: (fee) => setState(() => _applyFee(fee, force: true)),
            ),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_hasRecipient) ...[
                Expanded(
                  child: TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _kind == TxKind.reply ? l.payToAuthor : l.amount,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _amountEdited = true),
                    validator: (v) {
                      final a = _parseAmount(v ?? '');
                      if (a == null) return l.wholeNumber;
                      if (fee != null && a < fee) return l.atLeastFee(fee);
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextFormField(
                  controller: _fee,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.feeToMiner,
                    border: const OutlineInputBorder(),
                    helperText: _feeInfo == null ? null : l.suggestedFee(_feeInfo!.suggested(_weight)),
                  ),
                  onChanged: (_) => setState(() => _feeEdited = true),
                  validator: (v) {
                    final f = _parseAmount(v ?? '');
                    return (f == null || f < 1) ? l.atLeastOne : null;
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (_kind != TxKind.raw && !_isFlag && widget.alias == null)
              TextFormField(
                controller: _message,
                minLines: 4,
                maxLines: 12,
                decoration: InputDecoration(
                  labelText: l.message,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                  helperText: l.bytesOf(msgBytes, maxMessageSize),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l.probNeedsMessage;
                  if (msgBytes > maxMessageSize) return l.tooLong(msgBytes);
                  return null;
                },
              ),
            const SizedBox(height: 16),
            _CostSummary(
              fee: fee ?? 0,
              burn: _kind == TxKind.orphan ? orphanBurn(fee ?? 0) : null,
              paid: _hasRecipient ? (_parseAmount(_amount.text) ?? 0) : null,
              available: available,
            ),
            if (client.state != LinkState.live)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.sendingNeedsLive),
              )
            else if (!ready)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.checkingBalance),
              ),
            const SizedBox(height: 16),
            Tooltip(
              message: l.signAndSendShortcut(apple ? '⌘ Enter' : 'Ctrl+Enter'),
              child: FilledButton.icon(
                onPressed: canSend ? _send : null,
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const MurmurIcon(Glyph.send),
                label: Text(l.signAndSend),
              ),
            ),
          ]),
        ),
      ),
      );
    });
  }
}

/// The last word before signing: everything the transaction says, in full.
class _SendSummary extends StatelessWidget {
  const _SendSummary({
    required this.kind,
    this.typeName,
    required this.from,
    required this.to,
    required this.target,
    required this.message,
    required this.weight,
    required this.fee,
    required this.burn,
    required this.paid,
    required this.check,
  });

  final TxKind kind;

  /// What to call the type, where the kind alone doesn't say (an alias).
  final String? typeName;
  final String from;

  /// The recipient of a reply or transfer.
  final String? to;

  /// The message replied to or flagged.
  final TxView? target;
  final String? message;
  final int weight;
  final int fee;
  final int? burn;
  final int? paid;

  /// What stops it being sent now, if anything: asked again whenever the
  /// client changes (a new block, a transaction), with the balance.
  final TxProblem? Function(MurmurClient client) check;

  @override
  Widget build(BuildContext context) => AppBuilder(
      builder: (context, client, _) => _build(context, client.availableTo(from), check(client)));

  Widget _build(BuildContext context, int? available, TxProblem? problem) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final label = theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final total = fee + (burn ?? 0) + (paid ?? 0);

    Widget row(String name, Widget value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: label),
            const SizedBox(height: 2),
            value,
          ]),
        );

    Widget who(String address) => Row(children: [
          AddressAvatar(address, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nameOf(context, address), style: theme.textTheme.titleSmall),
              Text(address, style: mono.copyWith(fontSize: 11), textDirection: TextDirection.ltr),
            ]),
          ),
        ]);

    Widget amount(Glyph glyph, String name, int value, {bool strong = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            MurmurIcon(glyph, size: 18, color: color ?? theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: strong ? theme.textTheme.titleSmall : null)),
            Text(formatAmount(context, value),
                style: (strong ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)
                    ?.copyWith(fontWeight: strong ? FontWeight.w700 : FontWeight.w500, color: color)),
          ]),
        );

    final remaining = available == null ? null : available - total;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(children: [
              MurmurIcon(Glyph.send, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(l.confirmSendTitle, style: theme.textTheme.headlineSmall)),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                row(l.type, Text(typeName ?? kindLabel(context, kind), style: theme.textTheme.titleMedium)),
                row(l.from, who(from)),
                if (to != null) row(l.to, who(to!)),
                if (target != null)
                  row(
                    kind == TxKind.flag ? l.reports : l.inReplyTo,
                    Text(messageOrUnavailable(context, target!), maxLines: 4, overflow: TextOverflow.ellipsis),
                  ),
                if (message != null)
                  row(
                    l.message,
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(message!, style: theme.textTheme.bodyLarge),
                    ),
                  ),
                row(l.weight, Text(l.weightValue(weight, (fee / weight).toStringAsFixed(4)))),
                const Divider(height: 20),
                amount(Glyph.fee, l.costFee, fee),
                if (burn != null) amount(Glyph.burn, l.costBurn(orphanBurnMultiple), burn!),
                if (paid != null) amount(Glyph.transfer, l.costPaid, paid!),
                amount(Glyph.receipt, l.costTotal, total, strong: true),
                if (available != null && remaining != null) ...[
                  const SizedBox(height: 6),
                  amount(Glyph.wallet, l.costAvailable, available),
                  amount(Glyph.coins, l.costRemaining, remaining,
                      color: remaining < 0 ? theme.colorScheme.error : null),
                ],
                const SizedBox(height: 12),
                // Something changed since it was checked (the balance, the
                // link): signing waits until it can be sent again.
                if (problem != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      MurmurIcon(Glyph.warning, size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(txProblemText(l, problem),
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                      ),
                    ]),
                  ),
                Text(l.confirmSendFinal, style: theme.textTheme.bodySmall),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
              FilledButton.icon(
                icon: const MurmurIcon(Glyph.send),
                label: Text(l.signAndSend),
                onPressed: problem != null ? null : () => Navigator.pop(context, true),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// What sending costs, in symbols: fee (+ burn or amount paid) = total, and
/// available → what remains. Each symbol names itself on hover or long press,
/// and to screen readers.
class _CostSummary extends StatelessWidget {
  const _CostSummary({required this.fee, required this.burn, required this.paid, required this.available});

  final int fee;

  /// A thread's burn, 10 x the fee; null for other kinds.
  final int? burn;

  /// What a reply or transfer pays its recipient; null for other kinds.
  final int? paid;

  /// Null while balances are still being counted.
  final int? available;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final total = fee + (burn ?? 0) + (paid ?? 0);
    final remaining = available == null ? null : available! - total;
    final short = remaining != null && remaining < 0;
    final operator = theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget item(Glyph glyph, int? value, String name, {Color? color}) {
      final shown = value == null ? '…' : formatAmount(context, value);
      return Tooltip(
        message: name,
        child: Semantics(
          label: '$name: $shown',
          excludeSemantics: true,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            MurmurIcon(glyph, size: 20, color: color ?? theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(shown, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      );
    }

    Widget op(String symbol) => ExcludeSemantics(child: Text(symbol, style: operator));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            item(Glyph.fee, fee, l.costFee),
            if (burn != null) ...[op('+'), item(Glyph.burn, burn!, l.costBurn(orphanBurnMultiple))],
            if (paid != null) ...[op('+'), item(Glyph.transfer, paid!, l.costPaid)],
            op('='),
            item(Glyph.receipt, total, l.costTotal),
            const SizedBox(width: 12),
            item(Glyph.wallet, available, l.costAvailable),
            ExcludeSemantics(child: MurmurIcon(Glyph.arrowForward, size: 16, color: theme.colorScheme.outline)),
            item(Glyph.coins, remaining, l.costRemaining, color: short ? theme.colorScheme.error : null),
          ],
        ),
      ),
    );
  }
}

/// The suggested fee for this transaction's weight, at a glance: the number,
/// whether blocks have room, and the three bars it's drawn from. Why fees
/// work this way is folded away beneath.
class _FeeCard extends StatelessWidget {
  const _FeeCard(
      {required this.info, required this.weight, required this.loading, required this.onRefresh, required this.onUse});

  final FeeInfo? info;
  final int weight;
  final bool loading;
  final VoidCallback onRefresh;
  final ValueChanged<int> onUse;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
    final info = this.info;
    final refresh = IconButton(
      tooltip: l.checkAgain,
      onPressed: loading ? null : onRefresh,
      icon: loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const MurmurIcon(Glyph.refresh),
    );
    if (info == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
          child: Row(children: [
            MurmurIcon(Glyph.fee, size: 20, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(l.checkingFees, style: theme.textTheme.bodyMedium)),
            refresh,
          ]),
        ),
      );
    }
    final suggested = info.suggested(weight);
    final status = StatusColors.of(context);
    final statusColor = info.congested ? status.pending : status.success;

    // One of the bars the suggestion comes from: a small label, a bold value.
    Widget bar(String label, int value) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: muted),
            Text(formatAmount(context, value), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            MurmurIcon(Glyph.fee, size: 24, color: scheme.primary),
            const SizedBox(width: 12),
            // The number that matters, big and in copper.
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.feeSuggestedLabel, style: muted),
                Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 6, children: [
                  Text(formatAmount(context, suggested),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(l.feeForBytes(weight), style: theme.textTheme.bodySmall),
                  ),
                ]),
              ]),
            ),
            TextButton(onPressed: () => onUse(suggested), child: Text(l.use)),
            refresh,
          ]),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(52, 8, 16, 4),
          child: Wrap(runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            // Whether blocks have room.
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  MurmurIcon(Glyph.blocks, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(info.congested ? l.feeFull : l.feeRoom,
                      style: theme.textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            bar(l.feeNextBlock, info.nextBlockFee(weight)),
            bar(l.feePoolEntry, info.poolEntryFee(weight)),
            bar(l.feeMinimum, minFee),
          ]),
        ),
        // Why: folded away, for whoever wants it.
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            dense: true,
            tilePadding: const EdgeInsetsDirectional.fromSTEB(52, 0, 16, 0),
            childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
            title: Text(l.feeWhy, style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
            children: [
              InfoPoint(Glyph.fee, l.feePerBytePoint(txBaseBytes)),
              InfoPoint(
                Glyph.blocks,
                info.recentLowest != null
                    ? l.feeRecentPoint(info.recentLowest!, info.recentMedian!)
                    : l.feeRecentNonePoint,
              ),
              InfoPoint(Glyph.node, info.source == FeeSource.node ? l.feeFromNode(info.pending) : l.feeLocal(info.pending),
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ]),
    );
  }
}
