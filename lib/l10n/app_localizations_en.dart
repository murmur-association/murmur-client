// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => 'Thread';

  @override
  String get kindReply => 'Reply';

  @override
  String get kindTransfer => 'Transfer';

  @override
  String get kindFlag => 'Flag';

  @override
  String get contentUnavailable =>
      '(content not available: the node doesn\'t have it)';

  @override
  String get contentWithdrawn => '(withdrawn by its author)';

  @override
  String get contentLoading => '(loading the message…)';

  @override
  String get pending => 'pending';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String replyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString replies',
      one: '1 reply',
      zero: 'No replies',
    );
    return '$_temp0';
  }

  @override
  String flagCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString flags',
      one: '1 flag',
      zero: 'No flags',
    );
    return '$_temp0';
  }

  @override
  String transferOf(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Transfer of $amountString';
  }

  @override
  String flagOn(String text) {
    return 'Flag on “$text”';
  }

  @override
  String flagOnTx(String txid) {
    return 'Flag on $txid';
  }

  @override
  String get replyNotThreaded => 'Reply (not in a thread)';

  @override
  String routeFrom(String address) {
    return 'from $address';
  }

  @override
  String routeFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String errUnreachable(String detail) {
    return 'Could not reach the node: $detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return 'Could not reach the WebSocket bridge at $url. Start it with: dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return 'Connection error: $detail';
  }

  @override
  String get errClosed => 'The node closed the connection.';

  @override
  String get errTimeout => 'The node did not respond in time.';

  @override
  String errProtocol(String detail) {
    return 'Protocol error: $detail';
  }

  @override
  String errVersion(int node, int ours) {
    return 'The node speaks protocol $node; this client speaks protocol $ours.';
  }

  @override
  String errSyncFailed(String cause) {
    return 'Sync failed: $cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return 'Ignored a relayed block: $detail';
  }

  @override
  String get probFeeTooLow => 'The fee must be at least 1.';

  @override
  String get probMalformed => 'This transaction is not well formed.';

  @override
  String get probNeedsMessage => 'Write a message.';

  @override
  String get probNeedsRecipient => 'Enter a recipient.';

  @override
  String probAmountBelowFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'The amount must be at least the fee ($feeString).';
  }

  @override
  String get probReplyParentNotMined =>
      'You can only reply to a thread or reply that is already in a block.';

  @override
  String get probReplyWrongRecipient =>
      'A reply must pay the author of the message it answers.';

  @override
  String get probFlagNotMessage => 'Only threads and replies can be flagged.';

  @override
  String get probAlreadyFlagged =>
      'This wallet has already flagged that message.';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'The message is $lengthString bytes; the limit is $limitString.';
  }

  @override
  String probInsufficientBalance(int needed, int available) {
    final intl.NumberFormat neededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String neededString = neededNumberFormat.format(needed);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return 'Insufficient balance: $neededString needed, $availableString available (confirmed balance minus pending transactions).';
  }

  @override
  String get probNotLive => 'Wait until the client is connected and synced.';

  @override
  String get probConnectionLost => 'Lost the connection to the node.';

  @override
  String get probDuplicate =>
      'An identical transaction was already sent this second.';

  @override
  String get tabThreads => 'Threads';

  @override
  String get tabMessages => 'Messages';

  @override
  String get tabWallet => 'Wallet';

  @override
  String get tabChain => 'Chain';

  @override
  String get newThread => 'New thread';

  @override
  String get createWalletFirst => 'Create or import a wallet first.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get changeNode => 'Change node';

  @override
  String get unknownNetwork =>
      'This node is on a network the client does not recognize. Its difficulty adjustments can\'t be checked, and block rewards are counted with whitepaper values, so miner balances may be off.';

  @override
  String get linkOffline => 'Offline';

  @override
  String get linkConnecting => 'Connecting…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return 'Syncing $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Live · $heightString';
  }

  @override
  String get connectToNode => 'Connect to a node';

  @override
  String nodeAt(String address) {
    return 'Node $address';
  }

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get node => 'Node';

  @override
  String get connectHelpBridge =>
      'In the browser, the client connects over WebSocket: to a node\'s WebSocket address (such as node.murmur.info, port 443, over TLS), or to a local bridge (dart run tool/ws_bridge.dart, port 7880).';

  @override
  String get connectHelpNative =>
      'The peer-to-peer address of a murmur-node (its --port, 7878 by default). The control port (7879) will not work.';

  @override
  String get host => 'Host';

  @override
  String get port => 'Port';

  @override
  String get required => 'Required';

  @override
  String get enterPort => 'Enter a port number';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get cancel => 'Cancel';

  @override
  String get connect => 'Connect';

  @override
  String get syncingChain => 'Syncing the chain…';

  @override
  String get noThreads => 'No threads yet. Start one with New thread.';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'As of block $heightString ($time, $elapsed)';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString new blocks since',
      one: '1 new block since',
      zero: 'up to date',
    );
    return '$_temp0';
  }

  @override
  String agoSeconds(int s) {
    return '$s s ago';
  }

  @override
  String agoMinutes(int m, int s) {
    return '$m min $s s ago';
  }

  @override
  String agoHours(int h, int m) {
    return '$h h $m min ago';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return '$dString d $h h ago';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String threadStarted(String time) {
    return 'started $time';
  }

  @override
  String threadLastReply(String time) {
    return 'last reply $time';
  }

  @override
  String get messagesNeedWallet =>
      'Create or import a wallet in the Wallet tab to see your messages.';

  @override
  String get noMessages => 'No messages match these filters.';

  @override
  String get filterThreads => 'My threads';

  @override
  String get filterRepliesSent => 'Replies sent';

  @override
  String get filterRepliesReceived => 'Replies received';

  @override
  String get filterFlagsSent => 'Flags raised';

  @override
  String get filterFlagsReceived => 'Flags received';

  @override
  String get balance => 'Balance';

  @override
  String pendingCommitted(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString committed to pending transactions';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString blocks mined',
      one: '1 block mined',
      zero: 'No blocks mined',
    );
    return '$_temp0';
  }

  @override
  String get address => 'Address';

  @override
  String get showSeed => 'Show seed';

  @override
  String get removeWallet => 'Remove wallet';

  @override
  String get history => 'History';

  @override
  String get filters => 'Filters';

  @override
  String get noHistory => 'No transactions match these filters.';

  @override
  String get walletFilterTransfersSent => 'Transfers sent';

  @override
  String get walletFilterTransfersReceived => 'Transfers received';

  @override
  String get walletFilterRepliesPaid => 'Paid for replies';

  @override
  String get walletFilterRepliesEarned => 'Earned from replies';

  @override
  String get walletFilterThreadCosts => 'Thread costs';

  @override
  String get walletFilterFlagCosts => 'Flag fees';

  @override
  String get seedTitle => 'Wallet seed';

  @override
  String get seedWarning =>
      'Anyone with this seed can spend this wallet. It is the same format as a key file made with murmur-node keygen.';

  @override
  String get done => 'Done';

  @override
  String get removeWalletTitle => 'Remove wallet?';

  @override
  String get removeWalletBody =>
      'The seed will be deleted from this device. Without a copy of it, any balance at this address is lost.';

  @override
  String get remove => 'Remove';

  @override
  String get importWallet => 'Import wallet';

  @override
  String get importHelp =>
      'Paste a 64-character hex seed, for example the contents of a key file made with murmur-node keygen (murmur.key), to use the rewards mined to its address.';

  @override
  String get seed => 'Seed';

  @override
  String get import => 'Import';

  @override
  String get seedInvalid => 'A seed is exactly 64 hex characters.';

  @override
  String get walletIntro =>
      'A wallet signs the transactions you send. Its key stays on this device.';

  @override
  String get createWallet => 'Create new wallet';

  @override
  String get importSeed => 'Import seed';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return 'No block at height $heightString (the tip is $tipString).';
  }

  @override
  String get searchInvalid =>
      'Enter a block height, or a 64-character txid, block hash or address.';

  @override
  String get searchHint => 'Search height, txid, block hash or address';

  @override
  String get noBlocks => 'No blocks yet.';

  @override
  String blockTitle(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Block $heightString';
  }

  @override
  String txShortCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tx',
      one: '1 tx',
    );
    return '$_temp0';
  }

  @override
  String minerIs(String miner) {
    return 'miner $miner';
  }

  @override
  String get statNetwork => 'Network';

  @override
  String get statHeight => 'Height';

  @override
  String get statNodeHeight => 'Node height';

  @override
  String get statNextReward => 'Next block reward';

  @override
  String rewardPlusFees(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString + fees';
  }

  @override
  String get statBurnPool => 'Burn pool';

  @override
  String get statCirculating => 'Circulating';

  @override
  String get tip => 'Tip';

  @override
  String get previousBlock => 'Previous block';

  @override
  String get nextBlock => 'Next block';

  @override
  String get blockGone => 'This block is no longer on the best chain.';

  @override
  String get hash => 'Hash';

  @override
  String get previous => 'Previous';

  @override
  String get time => 'Time';

  @override
  String get confirmations => 'Confirmations';

  @override
  String get miner => 'Miner';

  @override
  String get reward => 'Reward';

  @override
  String rewardBreakdown(int subsidy, int payout, int fees) {
    final intl.NumberFormat subsidyNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String subsidyString = subsidyNumberFormat.format(subsidy);
    final intl.NumberFormat payoutNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String payoutString = payoutNumberFormat.format(payout);
    final intl.NumberFormat feesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feesString = feesNumberFormat.format(fees);

    return '$subsidyString subsidy + $payoutString from the burn pool + $feesString fees';
  }

  @override
  String get merkleRoot => 'Merkle root';

  @override
  String get target => 'Target';

  @override
  String get nonce => 'Nonce';

  @override
  String txCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString transactions',
      one: '1 transaction',
      zero: 'No transactions',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => 'Your address';

  @override
  String get noTransactions => 'No transactions.';

  @override
  String get sendToAddress => 'Send to this address';

  @override
  String get threadGone => 'This thread is no longer on the chain.';

  @override
  String paidToParent(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'paid $amountString to the parent\'s author';
  }

  @override
  String get actionReply => 'Reply';

  @override
  String get actionFlag => 'Flag';

  @override
  String get flagged => 'Flagged';

  @override
  String get details => 'Details';

  @override
  String get txTitle => 'Transaction';

  @override
  String get txNotFound =>
      'Transaction not found. It may have been dropped from the pending set or removed by a reorg.';

  @override
  String refNotLocal(String txid) {
    return 'Transaction $txid (not on the local chain)';
  }

  @override
  String get flaggedMessage => 'Flagged message';

  @override
  String get inReplyTo => 'In reply to';

  @override
  String get notThreadedExplain =>
      'Names this parent, but isn\'t part of its thread: the parent must be a mined thread or reply, and this reply must pay its author. It counts only as a payment.';

  @override
  String get message => 'Message';

  @override
  String get openThread => 'Open thread';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get type => 'Type';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get burned => 'Burned';

  @override
  String burnedValue(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString (returned to miners through the burn pool)';
  }

  @override
  String get amount => 'Amount';

  @override
  String get fee => 'Fee';

  @override
  String get signedAt => 'Signed at';

  @override
  String get contentHash => 'Content hash';

  @override
  String get contentSize => 'Content size';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString bytes (a $salt-byte salt and a $messageString-byte message)';
  }

  @override
  String get reports => 'Reports';

  @override
  String get repliesTo => 'Replies to';

  @override
  String get weight => 'Weight';

  @override
  String weightValue(int weight, String perByte) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString bytes ($perByte fee per byte)';
  }

  @override
  String get publicKey => 'Public key';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Confirmed in block $heightString';
  }

  @override
  String confirmationCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString confirmations',
      one: '1 confirmation',
    );
    return '$_temp0';
  }

  @override
  String notConfirmedAfter(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Not confirmed after $countString blocks',
      one: 'Not confirmed after 1 block',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused =>
      'The node may have refused it (for example, the balance changed before it was mined). It gives no feedback on refused transactions.';

  @override
  String get sentWaiting => 'Sent, waiting for a block';

  @override
  String get submittedHere => 'Submitted from this device.';

  @override
  String get pendingTitle => 'Pending';

  @override
  String get relayedPending => 'Relayed by the node, not yet in a block.';

  @override
  String get viewBlock => 'View block';

  @override
  String get newTransaction => 'New transaction';

  @override
  String get flagMessage => 'Flag message';

  @override
  String flaggingInfo(String author) {
    return 'Flagging this message by $author. Each wallet can flag a message once. Clients decide what to do with flags.';
  }

  @override
  String replyingTo(String author) {
    return 'Replying to $author';
  }

  @override
  String explainThread(int total, int burn) {
    return 'Starts a new thread. It costs $total × the fee: the fee goes to the miner, and $burn × the fee is burned. Burned tokens go back to miners over the following blocks.';
  }

  @override
  String get explainReply =>
      'Your reply pays the author of the message at least the fee (you can tip more), plus the fee to the miner.';

  @override
  String get explainTransfer =>
      'A plain token transfer with no message. The amount must be at least the fee.';

  @override
  String get recipientAddress => 'Recipient address';

  @override
  String get enterAddress => 'Enter a 64-character hex address';

  @override
  String get payToAuthor => 'Pay to author';

  @override
  String get wholeNumber => 'Whole number';

  @override
  String atLeastFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'At least the fee ($feeString)';
  }

  @override
  String get feeToMiner => 'Fee (to the miner)';

  @override
  String suggestedFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Suggested: $feeString';
  }

  @override
  String get atLeastOne => 'At least 1';

  @override
  String bytesOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString bytes';
  }

  @override
  String tooLong(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Too long: $countString bytes';
  }

  @override
  String get sendingNeedsLive =>
      'Sending is available once the client is connected and synced.';

  @override
  String get signAndSend => 'Sign and send';

  @override
  String get costFee => 'Fee, to the miner';

  @override
  String costBurn(int multiple) {
    return 'Burned: $multiple × the fee';
  }

  @override
  String get costPaid => 'Paid to the recipient';

  @override
  String get costTotal => 'Total cost';

  @override
  String get costAvailable => 'Available: balance minus pending transactions';

  @override
  String get costRemaining => 'Left after sending';

  @override
  String get checkingFees => 'Checking network fees…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Estimated from what this client has seen ($countString pending since it connected); the node\'s own fee report was not available.';
  }

  @override
  String get use => 'Use';

  @override
  String get checkAgain => 'Check again';

  @override
  String balanceBeforeAfter(int before, int after) {
    final intl.NumberFormat beforeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String beforeString = beforeNumberFormat.format(before);
    final intl.NumberFormat afterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String afterString = afterNumberFormat.format(after);

    return '$beforeString → $afterString';
  }

  @override
  String balanceBeforeAfterTooltip(int before, int after) {
    final intl.NumberFormat beforeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String beforeString = beforeNumberFormat.format(before);
    final intl.NumberFormat afterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String afterString = afterNumberFormat.format(after);

    return 'Balance: $beforeString before, $afterString after';
  }

  @override
  String chainCounted(int counted, int total) {
    final intl.NumberFormat countedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countedString = countedNumberFormat.format(counted);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$countedString of $totalString blocks counted';
  }

  @override
  String get loadingOlder => 'Loading older blocks…';

  @override
  String get blockLoading => 'Loading this block…';

  @override
  String get txSearching =>
      'Looking for this transaction in the blocks still loading…';

  @override
  String get storageBanner =>
      'Keep a copy of the chain on this device? Later visits then open in seconds instead of downloading everything again. It stays here and is never sent to anyone: no cookies, no tracking. Your wallet key and settings are always kept on this device, as the app needs them to work.';

  @override
  String get storageAllow => 'Allow necessary storage';

  @override
  String get storageReject => 'Reject (slower)';

  @override
  String get storageOn => 'Local copy of the chain: on';

  @override
  String get storageOff =>
      'Local copy of the chain: off (every visit downloads it again)';

  @override
  String get storageTurnOn => 'Turn on';

  @override
  String get storageTurnOff => 'Turn off and delete';

  @override
  String get checkingBalance => 'Checking with the node…';

  @override
  String get errTampered =>
      'The connection was altered or cut: a message failed its integrity check.';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'The node\'s committed state at block $heightString doesn\'t match this client\'s own count of the chain. Don\'t trust this node: connect to another.';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'From the node: $countString pending transactions.',
      one: 'From the node: 1 pending transaction.',
      zero: 'From the node: nothing pending.',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => 'Accepted by the node and relayed.';

  @override
  String get statusRefused => 'Refused by the node';

  @override
  String get statusInvalid => 'Rejected as invalid';

  @override
  String nodeReason(String reason) {
    return 'The node says: $reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'The chain doesn\'t lead to this release\'s checkpoint at block $heightString: either the release or every node reached is wrong. Stopped; nothing from it can be trusted.';
  }

  @override
  String staleTip(String elapsed) {
    return 'The newest block is from $elapsed: this node may be behind, or cut off from the network. What you see may be out of date.';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return 'Started from the checkpoint at block $heightString; checking the headers back to genesis ($doneString so far).';
  }

  @override
  String get licenses => 'Licenses';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => 'Testnet: tokens have no value';

  @override
  String get linkNodeRepo => 'Node and protocol source';

  @override
  String get linkWhitepaper => 'Whitepaper';

  @override
  String checkingHeaders(int done, int total) {
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Checking block headers: $doneString of $totalString';
  }

  @override
  String reconnectingIn(int seconds) {
    return 'Trying again in $seconds s.';
  }

  @override
  String get languagesFilter => 'Languages';

  @override
  String get languageUndetected => 'Undetected';

  @override
  String get hideFlaggedThreads => 'Hide threads I flagged';

  @override
  String get star => 'Star';

  @override
  String get unstar => 'Remove star';

  @override
  String get starredOnly => 'Only starred threads';

  @override
  String get localNodeRun => 'Run a Murmur node on this computer';

  @override
  String get localNodeExplain =>
      'Your computer checks the chain itself, helps relay it, and keeps your own messages available. It keeps nobody else\'s messages beyond the one-hour check.';

  @override
  String get localNodeStarting => 'Starting the node…';

  @override
  String get localNodeRunning => 'The node is running, and the app uses it.';

  @override
  String localNodeFailed(String reason) {
    return 'The node stopped: $reason';
  }

  @override
  String get localNodeFailedUnknown => 'The node stopped unexpectedly.';

  @override
  String get localNodeMine => 'Mine with this computer';

  @override
  String get localNodeMineNote =>
      'Mining pays your wallet\'s address, uses electricity and makes your computer work harder. On the testnet, tokens are for testing only.';

  @override
  String get localNodeMineNeedsWallet =>
      'Create a wallet first: mining pays its address.';

  @override
  String localNodeCpu(int pct) {
    return 'Up to $pct% of one processor core';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count threads hidden',
      one: '1 thread hidden',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => 'Search loaded threads';

  @override
  String get noMatches => 'No loaded thread matches.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n d ago';
  }

  @override
  String get nameAddress => 'Name';

  @override
  String get aliasTitle => 'Name this address';

  @override
  String get aliasHelp =>
      'The name is kept on this device only. Leave it empty to remove it.';

  @override
  String get save => 'Save';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get mutedNote =>
      'Muted: its threads and replies are hidden on this device.';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies from muted addresses hidden',
      one: '1 reply from a muted address hidden',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new replies',
      one: '1 new reply',
    );
    return '$_temp0';
  }

  @override
  String get invitations => 'Invitations';

  @override
  String get createInvitations => 'Create invitations';

  @override
  String get inviteHowMany => 'How many cards';

  @override
  String get inviteFund => 'Fund the cards';

  @override
  String get inviteCardTitle => 'Murmur invitation';

  @override
  String inviteCardSerial(int n, int total) {
    return '$n of $total';
  }

  @override
  String inviteCardFrom(String name) {
    return 'From $name';
  }

  @override
  String get inviteCardHow => 'Scan the code or open the link to join Murmur.';

  @override
  String get inviteClaimed => 'Claimed';

  @override
  String get inviteChecking => 'Checking…';

  @override
  String get claimTitle => 'You\'re invited';

  @override
  String claimInvitedBy(String name) {
    return 'Invited by $name';
  }

  @override
  String claimHolds(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'This invitation holds $amountString: enough to start your first threads.';
  }

  @override
  String get claimCreateWallet => 'Create my wallet and claim';

  @override
  String get claimIntoWallet => 'Claim into my wallet';

  @override
  String get claimDone =>
      'Claimed. The tokens reach your wallet with the next block.';

  @override
  String get claimEmpty =>
      'This invitation has already been claimed, or taken back.';

  @override
  String get claimWrongNetwork =>
      'This invitation is for another network than the node you\'re connected to.';

  @override
  String get claimInvalid => 'That isn\'t a valid invitation code.';

  @override
  String get haveInvitation => 'I have an invitation';

  @override
  String get inviteCodeField => 'Invitation code or link';

  @override
  String get claim => 'Claim';

  @override
  String get cancelInvitation => 'Cancel invitation';

  @override
  String get inviteCancelled => 'Cancelled';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cancel $count invitations?',
      one: 'Cancel this invitation?',
    );
    return '$_temp0';
  }

  @override
  String get cancelInviteBody =>
      'Its tokens come back to your wallet, and whoever has the card can no longer claim it.';

  @override
  String get keepInvitation => 'Keep it';

  @override
  String get printOne => 'Print';

  @override
  String inviteDoneSection(int count) {
    return 'Claimed or cancelled ($count)';
  }

  @override
  String get inviteEachLabel => 'Each card';

  @override
  String get inviteEachCaption =>
      'Five threads at today\'s fee, plus the fee to claim it.';

  @override
  String get inviteTotalLabel => 'You pay';

  @override
  String get inviteTotalCaption => 'In all, fees included.';

  @override
  String get inviteWaitingState => 'Waiting to be claimed';

  @override
  String get inviteCardSlogan => 'Your voice has a seat here.';

  @override
  String get inviteCardJoin => 'Scan to join';

  @override
  String get share => 'Share…';

  @override
  String get inviteDetailFunded => 'Funded';

  @override
  String get inviteDetailClaimedBy => 'Claimed by';

  @override
  String get inviteDetailReceived => 'Received';

  @override
  String get inviteDetailCancelled =>
      'Cancelled: the tokens came back to your wallet';

  @override
  String get inviteDetailReturned => 'Returned';

  @override
  String get inviteDetailOnItsWay => 'On its way to a block';

  @override
  String get seedConfirmTitle => 'Show your seed?';

  @override
  String get seedConfirmBody =>
      'Anyone who sees the seed can spend from this wallet. Make sure nobody else can see your screen.';

  @override
  String get showAction => 'Show';

  @override
  String get authReasonSeed => 'Confirm it\'s you to see the wallet seed';

  @override
  String get authReasonRemove => 'Confirm it\'s you to remove this wallet';

  @override
  String get authFailed => 'Not confirmed: nothing was shown or changed.';

  @override
  String get passphraseNewTitle => 'Choose a passphrase';

  @override
  String get passphraseNewBody =>
      'It encrypts your wallet key on this device. You\'ll type it to send, to show the seed or to remove the wallet. If you forget it, only your seed backup can bring the wallet back.';

  @override
  String get passphraseField => 'Passphrase';

  @override
  String get passphraseRepeat => 'Repeat the passphrase';

  @override
  String passphraseTooShort(int min) {
    return 'At least $min characters';
  }

  @override
  String get passphraseMismatch => 'The two don\'t match';

  @override
  String get passphraseTitle => 'Passphrase';

  @override
  String get wrongPassphrase => 'Wrong passphrase: nothing was shown or sent.';

  @override
  String get unlock => 'Unlock';

  @override
  String get authReasonSend => 'Confirm it\'s you to sign and send';

  @override
  String get authReasonNewWallet => 'Protect your wallet key on this device';

  @override
  String get authReasonInvite => 'Confirm it\'s you to fund the cards';

  @override
  String get removeAnywayTitle => 'Remove without confirming?';

  @override
  String get removeAnywayBody =>
      'The wallet couldn\'t be unlocked. Removing it deletes its key from this device: only your seed backup can bring it back.';

  @override
  String get protectionDevice => 'Key encrypted with this device\'s lock';

  @override
  String get protectionPasskey => 'Key encrypted with a passkey on this device';

  @override
  String get protectionPassphrase => 'Key encrypted with your passphrase';

  @override
  String get protectionLegacy =>
      'Key not encrypted yet: it will be at the next unlock';

  @override
  String get confirmSendTitle => 'Check before signing';

  @override
  String get confirmSendFinal =>
      'Signing sends this to the node. It can\'t be taken back: once mined, it stays on the chain.';

  @override
  String signAndSendShortcut(String keys) {
    return 'Sign and send ($keys)';
  }

  @override
  String get threadWithdrawnMine =>
      'You withdrew it: hidden from others, and its text deleted from Murmur apps';

  @override
  String get threadWithdrawnMineNote =>
      'You flagged your own thread, which withdraws it. Murmur apps no longer show it to others and delete its text, on this device too; nodes may stop keeping its text and replies.';

  @override
  String get threadWithdrawnNote =>
      'Its author flagged this thread, which withdraws it. Murmur apps no longer list it and delete its text, and nodes may stop keeping its text and replies.';

  @override
  String get flagOwnInfo =>
      'This is your own message. Flagging it withdraws it: Murmur apps stop showing it to others and delete its text, on this device too, and nodes may stop keeping its text and replies. It can\'t be undone.';

  @override
  String get inviteFromTitle => 'Name on the cards';

  @override
  String get inviteFromBody =>
      'Each card says who it\'s from. The cards were funded by the inviting wallet, which may not be the one on this device now.';

  @override
  String get inviteFromOriginal => 'Inviting wallet\'s address';

  @override
  String get inviteFromOriginalAlias => 'Your name for the inviting wallet';

  @override
  String get inviteFromOriginalPublic => 'Inviting wallet\'s public name';

  @override
  String get inviteFromCurrent => 'This wallet\'s address';

  @override
  String get inviteFromCurrentAlias => 'Your name for this wallet';

  @override
  String get inviteFromCurrentPublic => 'This wallet\'s public name';

  @override
  String get inviteFromCustom => 'Other text';

  @override
  String get inviteFromCustomHint => 'Leave it empty to print no name';

  @override
  String get inviteFromNotSet => 'No name given on this device';

  @override
  String get inviteFromMixed => 'Differs between the selected cards';

  @override
  String get inviteFromChecking => 'Still being looked up on the chain';

  @override
  String get cancelReturnTo => 'Send the tokens to';

  @override
  String get cancelToFunder => 'The wallet that funded it';

  @override
  String get cancelToCurrent => 'This wallet';

  @override
  String get publicName => 'Public name';

  @override
  String get publicNameNone => 'None known';

  @override
  String get publicNameSet => 'Set public name';

  @override
  String get publicNameField => 'Name';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return 'At most $maxString bytes';
  }

  @override
  String get aliasBadCharacter =>
      'Invisible or control characters aren\'t allowed';

  @override
  String get aliasEdgeSpace => 'No spaces at the start or end';

  @override
  String aliasSetTo(String name) {
    return 'Public name: $name';
  }

  @override
  String get aliasCleared => 'Public name cleared';

  @override
  String get nonTextMessage => '(not text: data for an app convention)';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return 'Publishes your public name. Like a new thread, it costs $totalString × the fee: the fee goes to the miner, and $burnString × the fee is burned.';
  }

  @override
  String get inviteFromNoPublic => 'No public name known';

  @override
  String get starredTitle => 'Starred';

  @override
  String get noStarred =>
      'Nothing starred yet. Star a thread or a message from its page, and it shows up here.';

  @override
  String get starredGone => 'No longer on the chain';

  @override
  String get feeSuggestedLabel => 'Suggested fee';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return 'for $weightString bytes';
  }

  @override
  String get feeRoom => 'Blocks have room';

  @override
  String get feeFull => 'Blocks are full';

  @override
  String get feeNextBlock => 'Next block';

  @override
  String get feePoolEntry => 'To enter the pool';

  @override
  String get feeMinimum => 'Minimum';

  @override
  String get feeWhy => 'Why this fee';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**Fees are per byte**: $baseString bytes plus your message. Longer messages cost more when blocks are full.';
  }

  @override
  String feeRecentPoint(int lowest, int median) {
    final intl.NumberFormat lowestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lowestString = lowestNumberFormat.format(lowest);
    final intl.NumberFormat medianNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String medianString = medianNumberFormat.format(median);

    return '**Recent blocks** took fees as low as **$lowestString** (median $medianString).';
  }

  @override
  String get feeRecentNonePoint => '**Recent blocks** had no transactions.';

  @override
  String get inviteNoExpiryPoint =>
      '**No expiry**: a card works until someone claims it.';

  @override
  String get inviteCancelPoint => '**Cancel any time**: its tokens come back.';

  @override
  String get invitePublicPoint =>
      '**Public**: the chain shows you funded each card, and which wallet claimed it.';

  @override
  String get inviteCashPoint =>
      '**Whoever has the code** can claim the card. Keep cards private until you hand them over.';

  @override
  String get inviteLocalPoint =>
      '**Kept only on this device.** If its data is cleared or the app is removed, the codes are **lost for good**, and so are the tokens on cards not yet handed over.';

  @override
  String get publicNameIntro =>
      'Your public name appears **next to your address** in Murmur apps.';

  @override
  String publicNameShownAs(String name) {
    return 'Appears as **$name**';
  }

  @override
  String get publicNameNotUnique =>
      '**Not unique**: anyone can pick the same name. The address beside it tells people apart.';

  @override
  String get publicNameCost =>
      '**Costs as much as a new thread**, each time you set or change it.';

  @override
  String get publicNameRemovable =>
      '**A message on the chain**: any node may delete it, and then it\'s gone.';

  @override
  String get publicNameClear => '**Leave it empty** to clear it.';

  @override
  String get passkeyNoPrfTitle =>
      'This passkey manager can\'t protect the wallet';

  @override
  String get passkeyNoPrfWhy =>
      '**It can\'t encrypt.** To lock your wallet key, a passkey manager has to derive a key from the passkey (WebAuthn PRF). The one you picked doesn\'t.';

  @override
  String get passkeyNoPrfTry =>
      '**Try another manager**, such as Apple Passwords or Google Password Manager, or protect the wallet with a **passphrase**.';

  @override
  String get passkeyNoPrfLeftover =>
      'The passkey it just saved (**Murmur wallet**) unlocks nothing: you can delete it from that manager.';

  @override
  String get passkeyTryAnother => 'Try another passkey manager';

  @override
  String get passkeyUsePassphrase => 'Use a passphrase';
}
