import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pt'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Murmur'**
  String get appTitle;

  /// No description provided for @kindThread.
  ///
  /// In en, this message translates to:
  /// **'Thread'**
  String get kindThread;

  /// No description provided for @kindReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get kindReply;

  /// No description provided for @kindTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get kindTransfer;

  /// No description provided for @kindFlag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get kindFlag;

  /// No description provided for @contentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'(content not available: the node doesn\'t have it)'**
  String get contentUnavailable;

  /// Shown instead of a message whose own author flagged it (withdrew it): its text is deleted.
  ///
  /// In en, this message translates to:
  /// **'(withdrawn by its author)'**
  String get contentWithdrawn;

  /// Shown while a message's content is still being fetched from the node
  ///
  /// In en, this message translates to:
  /// **'(loading the message…)'**
  String get contentLoading;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get pending;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @replyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No replies} =1{1 reply} other{{count} replies}}'**
  String replyCount(int count);

  /// No description provided for @flagCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No flags} =1{1 flag} other{{count} flags}}'**
  String flagCount(int count);

  /// No description provided for @transferOf.
  ///
  /// In en, this message translates to:
  /// **'Transfer of {amount}'**
  String transferOf(String amount);

  /// No description provided for @flagOn.
  ///
  /// In en, this message translates to:
  /// **'Flag on “{text}”'**
  String flagOn(String text);

  /// No description provided for @flagOnTx.
  ///
  /// In en, this message translates to:
  /// **'Flag on {txid}'**
  String flagOnTx(String txid);

  /// No description provided for @replyNotThreaded.
  ///
  /// In en, this message translates to:
  /// **'Reply (not in a thread)'**
  String get replyNotThreaded;

  /// No description provided for @routeFrom.
  ///
  /// In en, this message translates to:
  /// **'from {address}'**
  String routeFrom(String address);

  /// No description provided for @routeFromTo.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String routeFromTo(String from, String to);

  /// No description provided for @errUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the node: {detail}'**
  String errUnreachable(String detail);

  /// No description provided for @errBridgeUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the WebSocket bridge at {url}. Start it with: dart run tool/ws_bridge.dart'**
  String errBridgeUnreachable(String url);

  /// No description provided for @errConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection error: {detail}'**
  String errConnection(String detail);

  /// No description provided for @errClosed.
  ///
  /// In en, this message translates to:
  /// **'The node closed the connection.'**
  String get errClosed;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The node did not respond in time.'**
  String get errTimeout;

  /// No description provided for @errProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol error: {detail}'**
  String errProtocol(String detail);

  /// No description provided for @errVersion.
  ///
  /// In en, this message translates to:
  /// **'The node speaks protocol {node}; this client speaks protocol {ours}.'**
  String errVersion(int node, int ours);

  /// No description provided for @errSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {cause}'**
  String errSyncFailed(String cause);

  /// No description provided for @errIgnoredBlock.
  ///
  /// In en, this message translates to:
  /// **'Ignored a relayed block: {detail}'**
  String errIgnoredBlock(String detail);

  /// No description provided for @probFeeTooLow.
  ///
  /// In en, this message translates to:
  /// **'The fee is below the network\'s minimum.'**
  String get probFeeTooLow;

  /// No description provided for @probMalformed.
  ///
  /// In en, this message translates to:
  /// **'This transaction is not well formed.'**
  String get probMalformed;

  /// No description provided for @probNeedsMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message.'**
  String get probNeedsMessage;

  /// No description provided for @probNeedsRecipient.
  ///
  /// In en, this message translates to:
  /// **'Enter a recipient.'**
  String get probNeedsRecipient;

  /// No description provided for @probAmountBelowFee.
  ///
  /// In en, this message translates to:
  /// **'The amount must be at least the fee ({fee}).'**
  String probAmountBelowFee(String fee);

  /// No description provided for @probReplyParentNotMined.
  ///
  /// In en, this message translates to:
  /// **'You can only reply to a thread or reply that is already in a block.'**
  String get probReplyParentNotMined;

  /// No description provided for @probFlagNotMessage.
  ///
  /// In en, this message translates to:
  /// **'Only threads and replies can be flagged.'**
  String get probFlagNotMessage;

  /// No description provided for @probAlreadyFlagged.
  ///
  /// In en, this message translates to:
  /// **'This wallet has already flagged that message.'**
  String get probAlreadyFlagged;

  /// No description provided for @probMessageTooLong.
  ///
  /// In en, this message translates to:
  /// **'The message is {length} bytes; the limit is {limit}.'**
  String probMessageTooLong(int length, int limit);

  /// No description provided for @probInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance: {needed} needed, {available} available (confirmed balance minus pending transactions).'**
  String probInsufficientBalance(String needed, String available);

  /// No description provided for @probNotLive.
  ///
  /// In en, this message translates to:
  /// **'Wait until the client is connected and synced.'**
  String get probNotLive;

  /// No description provided for @probConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Lost the connection to the node.'**
  String get probConnectionLost;

  /// No description provided for @probDuplicate.
  ///
  /// In en, this message translates to:
  /// **'An identical transaction was already sent this second.'**
  String get probDuplicate;

  /// No description provided for @tabThreads.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get tabThreads;

  /// No description provided for @tabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get tabMessages;

  /// No description provided for @tabWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get tabWallet;

  /// No description provided for @tabChain.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get tabChain;

  /// No description provided for @newThread.
  ///
  /// In en, this message translates to:
  /// **'New thread'**
  String get newThread;

  /// No description provided for @createWalletFirst.
  ///
  /// In en, this message translates to:
  /// **'Create or import a wallet first.'**
  String get createWalletFirst;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @changeNode.
  ///
  /// In en, this message translates to:
  /// **'Change node'**
  String get changeNode;

  /// No description provided for @unknownNetwork.
  ///
  /// In en, this message translates to:
  /// **'This node is on a network the client does not recognize. Its difficulty adjustments can\'t be checked, and block rewards are counted with whitepaper values, so miner balances may be off.'**
  String get unknownNetwork;

  /// No description provided for @linkOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get linkOffline;

  /// No description provided for @linkConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get linkConnecting;

  /// No description provided for @linkSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing {height}/{peerHeight}'**
  String linkSyncing(int height, int peerHeight);

  /// No description provided for @linkLive.
  ///
  /// In en, this message translates to:
  /// **'Live · {height}'**
  String linkLive(int height);

  /// No description provided for @connectToNode.
  ///
  /// In en, this message translates to:
  /// **'Connect to a node'**
  String get connectToNode;

  /// No description provided for @nodeAt.
  ///
  /// In en, this message translates to:
  /// **'Node {address}'**
  String nodeAt(String address);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguage;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @node.
  ///
  /// In en, this message translates to:
  /// **'Node'**
  String get node;

  /// No description provided for @connectHelpBridge.
  ///
  /// In en, this message translates to:
  /// **'In the browser, the client connects over WebSocket: to a node\'s WebSocket address (such as node.murmur.info, port 443, over TLS), or to a local bridge (dart run tool/ws_bridge.dart, port 7880).'**
  String get connectHelpBridge;

  /// No description provided for @connectHelpNative.
  ///
  /// In en, this message translates to:
  /// **'The peer-to-peer address of a murmur-node (its --port, 7878 by default). The control port (7879) will not work. Port 443 reaches a node behind a secure WebSocket, such as node.murmur.info.'**
  String get connectHelpNative;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @enterPort.
  ///
  /// In en, this message translates to:
  /// **'Enter a port number'**
  String get enterPort;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @syncingChain.
  ///
  /// In en, this message translates to:
  /// **'Syncing the chain…'**
  String get syncingChain;

  /// No description provided for @noThreads.
  ///
  /// In en, this message translates to:
  /// **'No threads yet. Start one with New thread.'**
  String get noThreads;

  /// time: when that block was mined, in local time; elapsed: how long ago that was (agoSeconds and so on)
  ///
  /// In en, this message translates to:
  /// **'As of block {height} ({time}, {elapsed})'**
  String threadsAsOf(int height, String time, String elapsed);

  /// No description provided for @newBlocksSince.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{up to date} =1{1 new block since} other{{count} new blocks since}}'**
  String newBlocksSince(int count);

  /// No description provided for @agoSeconds.
  ///
  /// In en, this message translates to:
  /// **'{s} s ago'**
  String agoSeconds(int s);

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m} min {s} s ago'**
  String agoMinutes(int m, int s);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min ago'**
  String agoHours(int h, int m);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{d} d {h} h ago'**
  String agoDays(int d, int h);

  /// No description provided for @threadStarted.
  ///
  /// In en, this message translates to:
  /// **'started {time}'**
  String threadStarted(String time);

  /// No description provided for @threadLastReply.
  ///
  /// In en, this message translates to:
  /// **'last reply {time}'**
  String threadLastReply(String time);

  /// No description provided for @messagesNeedWallet.
  ///
  /// In en, this message translates to:
  /// **'Create or import a wallet in the Wallet tab to see your messages.'**
  String get messagesNeedWallet;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages match these filters.'**
  String get noMessages;

  /// No description provided for @filterThreads.
  ///
  /// In en, this message translates to:
  /// **'My threads'**
  String get filterThreads;

  /// No description provided for @filterRepliesSent.
  ///
  /// In en, this message translates to:
  /// **'Replies sent'**
  String get filterRepliesSent;

  /// No description provided for @filterRepliesReceived.
  ///
  /// In en, this message translates to:
  /// **'Replies received'**
  String get filterRepliesReceived;

  /// No description provided for @filterFlagsSent.
  ///
  /// In en, this message translates to:
  /// **'Flags raised'**
  String get filterFlagsSent;

  /// No description provided for @filterFlagsReceived.
  ///
  /// In en, this message translates to:
  /// **'Flags received'**
  String get filterFlagsReceived;

  /// Messages tab filter chip: threads and replies by others that mention this wallet
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get filterMentions;

  /// Before the people a message mentions: under the message field, in the summary before signing
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get mentionsLabel;

  /// Explanation point where a mention is written: the chain shows publicly whom a message names
  ///
  /// In en, this message translates to:
  /// **'**A mention is public:** anyone can see whom you named.'**
  String get mentionPublicPoint;

  /// Under the message field, when four people are mentioned already
  ///
  /// In en, this message translates to:
  /// **'At most {max} mentions in a message'**
  String mentionsMax(int max);

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @pendingCommitted.
  ///
  /// In en, this message translates to:
  /// **'{amount} committed to pending transactions'**
  String pendingCommitted(String amount);

  /// No description provided for @blocksMined.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No blocks mined} =1{1 block mined} other{{count} blocks mined}}'**
  String blocksMined(int count);

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @showSeed.
  ///
  /// In en, this message translates to:
  /// **'Show seed'**
  String get showSeed;

  /// No description provided for @removeWallet.
  ///
  /// In en, this message translates to:
  /// **'Remove wallet'**
  String get removeWallet;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No transactions match these filters.'**
  String get noHistory;

  /// No description provided for @walletFilterTransfersSent.
  ///
  /// In en, this message translates to:
  /// **'Transfers sent'**
  String get walletFilterTransfersSent;

  /// No description provided for @walletFilterTransfersReceived.
  ///
  /// In en, this message translates to:
  /// **'Transfers received'**
  String get walletFilterTransfersReceived;

  /// No description provided for @walletFilterRepliesPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid for replies'**
  String get walletFilterRepliesPaid;

  /// No description provided for @walletFilterRepliesEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned from replies'**
  String get walletFilterRepliesEarned;

  /// No description provided for @walletFilterThreadCosts.
  ///
  /// In en, this message translates to:
  /// **'Thread costs'**
  String get walletFilterThreadCosts;

  /// No description provided for @walletFilterFlagCosts.
  ///
  /// In en, this message translates to:
  /// **'Flag fees'**
  String get walletFilterFlagCosts;

  /// No description provided for @seedTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet seed'**
  String get seedTitle;

  /// No description provided for @seedWarning.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this seed can spend this wallet. It is the same format as a key file made with murmur-node keygen.'**
  String get seedWarning;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @removeWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove wallet?'**
  String get removeWalletTitle;

  /// No description provided for @removeWalletBody.
  ///
  /// In en, this message translates to:
  /// **'The seed will be deleted from this device. Without a copy of it, any balance at this address is lost.'**
  String get removeWalletBody;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @importWallet.
  ///
  /// In en, this message translates to:
  /// **'Import wallet'**
  String get importWallet;

  /// Explains what can be pasted to import a wallet
  ///
  /// In en, this message translates to:
  /// **'Type or paste a wallet\'s seed: its 24 words, or its 64 hex characters (for example the contents of a key file made with murmur-node keygen, murmur.key, to use the rewards mined to its address).'**
  String get importHelp;

  /// No description provided for @seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get seed;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// Error: the text is neither form of a seed
  ///
  /// In en, this message translates to:
  /// **'A seed is 24 words or exactly 64 hex characters.'**
  String get seedInvalid;

  /// No description provided for @walletIntro.
  ///
  /// In en, this message translates to:
  /// **'A wallet signs the transactions you send. Its key stays on this device.'**
  String get walletIntro;

  /// No description provided for @createWallet.
  ///
  /// In en, this message translates to:
  /// **'Create new wallet'**
  String get createWallet;

  /// No description provided for @importSeed.
  ///
  /// In en, this message translates to:
  /// **'Import seed'**
  String get importSeed;

  /// No description provided for @noBlockAt.
  ///
  /// In en, this message translates to:
  /// **'No block at height {height} (the tip is {tip}).'**
  String noBlockAt(int height, int tip);

  /// No description provided for @searchInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a block height, or a 64-character txid, block hash or address.'**
  String get searchInvalid;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search height, txid, block hash or address'**
  String get searchHint;

  /// No description provided for @noBlocks.
  ///
  /// In en, this message translates to:
  /// **'No blocks yet.'**
  String get noBlocks;

  /// No description provided for @blockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {height}'**
  String blockTitle(int height);

  /// No description provided for @txShortCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tx} other{{count} tx}}'**
  String txShortCount(int count);

  /// No description provided for @minerIs.
  ///
  /// In en, this message translates to:
  /// **'miner {miner}'**
  String minerIs(String miner);

  /// No description provided for @statNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get statNetwork;

  /// No description provided for @statHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get statHeight;

  /// No description provided for @statNodeHeight.
  ///
  /// In en, this message translates to:
  /// **'Node height'**
  String get statNodeHeight;

  /// No description provided for @statNextReward.
  ///
  /// In en, this message translates to:
  /// **'Next block reward'**
  String get statNextReward;

  /// No description provided for @rewardPlusFees.
  ///
  /// In en, this message translates to:
  /// **'{amount} + fees'**
  String rewardPlusFees(String amount);

  /// No description provided for @statBurnPool.
  ///
  /// In en, this message translates to:
  /// **'Burn pool'**
  String get statBurnPool;

  /// No description provided for @statCirculating.
  ///
  /// In en, this message translates to:
  /// **'Circulating'**
  String get statCirculating;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @previousBlock.
  ///
  /// In en, this message translates to:
  /// **'Previous block'**
  String get previousBlock;

  /// No description provided for @nextBlock.
  ///
  /// In en, this message translates to:
  /// **'Next block'**
  String get nextBlock;

  /// No description provided for @blockGone.
  ///
  /// In en, this message translates to:
  /// **'This block is no longer on the best chain.'**
  String get blockGone;

  /// No description provided for @hash.
  ///
  /// In en, this message translates to:
  /// **'Hash'**
  String get hash;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @confirmations.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get confirmations;

  /// No description provided for @miner.
  ///
  /// In en, this message translates to:
  /// **'Miner'**
  String get miner;

  /// No description provided for @reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get reward;

  /// No description provided for @merkleRoot.
  ///
  /// In en, this message translates to:
  /// **'Merkle root'**
  String get merkleRoot;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @nonce.
  ///
  /// In en, this message translates to:
  /// **'Nonce'**
  String get nonce;

  /// No description provided for @txCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transactions} =1{1 transaction} other{{count} transactions}}'**
  String txCount(int count);

  /// No description provided for @yourAddress.
  ///
  /// In en, this message translates to:
  /// **'Your address'**
  String get yourAddress;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions.'**
  String get noTransactions;

  /// No description provided for @sendToAddress.
  ///
  /// In en, this message translates to:
  /// **'Send to this address'**
  String get sendToAddress;

  /// No description provided for @threadGone.
  ///
  /// In en, this message translates to:
  /// **'This thread is no longer on the chain.'**
  String get threadGone;

  /// No description provided for @paidToThreadAuthor.
  ///
  /// In en, this message translates to:
  /// **'paid {amount} to the thread\'s author'**
  String paidToThreadAuthor(String amount);

  /// No description provided for @actionReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get actionReply;

  /// No description provided for @actionFlag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get actionFlag;

  /// No description provided for @flagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get flagged;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @txTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get txTitle;

  /// No description provided for @txNotFound.
  ///
  /// In en, this message translates to:
  /// **'Transaction not found. It may have been dropped from the pending set or removed by a reorg.'**
  String get txNotFound;

  /// No description provided for @refNotLocal.
  ///
  /// In en, this message translates to:
  /// **'Transaction {txid} (not on the local chain)'**
  String refNotLocal(String txid);

  /// No description provided for @flaggedMessage.
  ///
  /// In en, this message translates to:
  /// **'Flagged message'**
  String get flaggedMessage;

  /// No description provided for @inReplyTo.
  ///
  /// In en, this message translates to:
  /// **'In reply to'**
  String get inReplyTo;

  /// No description provided for @notThreadedExplain.
  ///
  /// In en, this message translates to:
  /// **'Names this parent, but isn\'t part of its thread: the parent must be a mined thread or reply, and this reply must pay its author. It counts only as a payment.'**
  String get notThreadedExplain;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @openThread.
  ///
  /// In en, this message translates to:
  /// **'Open thread'**
  String get openThread;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @burned.
  ///
  /// In en, this message translates to:
  /// **'Burned'**
  String get burned;

  /// No description provided for @burnedValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} (returned to miners through the burn pool)'**
  String burnedValue(String amount);

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @contentHash.
  ///
  /// In en, this message translates to:
  /// **'Content hash'**
  String get contentHash;

  /// No description provided for @contentSize.
  ///
  /// In en, this message translates to:
  /// **'Content size'**
  String get contentSize;

  /// No description provided for @contentSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{size} bytes (a {salt}-byte salt and a {message}-byte message)'**
  String contentSizeValue(int size, int salt, int message);

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @repliesTo.
  ///
  /// In en, this message translates to:
  /// **'Replies to'**
  String get repliesTo;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @weightValue.
  ///
  /// In en, this message translates to:
  /// **'{weight} bytes ({perByte} fee per byte)'**
  String weightValue(int weight, String perByte);

  /// No description provided for @publicKey.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get publicKey;

  /// No description provided for @confirmedIn.
  ///
  /// In en, this message translates to:
  /// **'Confirmed in block {height}'**
  String confirmedIn(int height);

  /// No description provided for @confirmationCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 confirmation} other{{count} confirmations}}'**
  String confirmationCount(int count);

  /// No description provided for @notConfirmedAfter.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Not confirmed after 1 block} other{Not confirmed after {count} blocks}}'**
  String notConfirmedAfter(int count);

  /// No description provided for @maybeRefused.
  ///
  /// In en, this message translates to:
  /// **'The node may have refused it (for example, the balance changed before it was mined). It gives no feedback on refused transactions.'**
  String get maybeRefused;

  /// No description provided for @sentWaiting.
  ///
  /// In en, this message translates to:
  /// **'Sent, waiting for a block'**
  String get sentWaiting;

  /// No description provided for @submittedHere.
  ///
  /// In en, this message translates to:
  /// **'Submitted from this device.'**
  String get submittedHere;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTitle;

  /// No description provided for @relayedPending.
  ///
  /// In en, this message translates to:
  /// **'Relayed by the node, not yet in a block.'**
  String get relayedPending;

  /// No description provided for @viewBlock.
  ///
  /// In en, this message translates to:
  /// **'View block'**
  String get viewBlock;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get newTransaction;

  /// No description provided for @flagMessage.
  ///
  /// In en, this message translates to:
  /// **'Flag message'**
  String get flagMessage;

  /// No description provided for @flaggingInfo.
  ///
  /// In en, this message translates to:
  /// **'Flagging this message by {author}. Each wallet can flag a message once. Clients decide what to do with flags.'**
  String flaggingInfo(String author);

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {author}'**
  String replyingTo(String author);

  /// No description provided for @explainThread.
  ///
  /// In en, this message translates to:
  /// **'Starts a new thread. It costs {total} × the fee: the fee goes to the miner, and {burn} × the fee is burned. Burned tokens go back to miners over the following blocks.'**
  String explainThread(int total, int burn);

  /// No description provided for @explainReply.
  ///
  /// In en, this message translates to:
  /// **'Your reply pays the thread\'s author at least the fee (you can tip more), plus the fee to the miner.'**
  String get explainReply;

  /// No description provided for @explainTransfer.
  ///
  /// In en, this message translates to:
  /// **'A plain token transfer with no message. The amount must be at least the fee.'**
  String get explainTransfer;

  /// No description provided for @recipientAddress.
  ///
  /// In en, this message translates to:
  /// **'Recipient address'**
  String get recipientAddress;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a 64-character hex address'**
  String get enterAddress;

  /// No description provided for @payToAuthor.
  ///
  /// In en, this message translates to:
  /// **'Pay the thread\'s author'**
  String get payToAuthor;

  /// No description provided for @notAnAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get notAnAmount;

  /// No description provided for @atLeastFee.
  ///
  /// In en, this message translates to:
  /// **'At least the fee ({fee})'**
  String atLeastFee(String fee);

  /// No description provided for @feeToMiner.
  ///
  /// In en, this message translates to:
  /// **'Fee (to the miner)'**
  String get feeToMiner;

  /// No description provided for @suggestedFee.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {fee}'**
  String suggestedFee(String fee);

  /// In the summary before signing, when the fee given is below the suggested one: a light remark, not an error
  ///
  /// In en, this message translates to:
  /// **'Below the suggested fee ({fee}): it may take a while to get into a block.'**
  String feeBelowSuggested(String fee);

  /// In the summary before signing, when the fee given is above the suggested one
  ///
  /// In en, this message translates to:
  /// **'Above the suggested fee ({fee}): you offer the miner more than needed.'**
  String feeAboveSuggested(String fee);

  /// No description provided for @atLeastMin.
  ///
  /// In en, this message translates to:
  /// **'At least {min}'**
  String atLeastMin(String min);

  /// No description provided for @bytesOf.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} bytes'**
  String bytesOf(int count, int max);

  /// No description provided for @tooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long: {count} bytes'**
  String tooLong(int count);

  /// Button under the message field that opens Murmur's own emoji
  ///
  /// In en, this message translates to:
  /// **'Murmur emoji'**
  String get murmurEmoji;

  /// Under the emoji picker; example is an emoji's code, such as :murmur:
  ///
  /// In en, this message translates to:
  /// **'Drawn only in Murmur. Other apps show the name, such as {example}.'**
  String murmurEmojiHint(String example);

  /// No description provided for @sendingNeedsLive.
  ///
  /// In en, this message translates to:
  /// **'Sending is available once the client is connected and synced.'**
  String get sendingNeedsLive;

  /// No description provided for @signAndSend.
  ///
  /// In en, this message translates to:
  /// **'Sign and send'**
  String get signAndSend;

  /// No description provided for @costFee.
  ///
  /// In en, this message translates to:
  /// **'Fee, to the miner'**
  String get costFee;

  /// No description provided for @costBurn.
  ///
  /// In en, this message translates to:
  /// **'Burned: {multiple} × the fee'**
  String costBurn(int multiple);

  /// No description provided for @costPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid to the recipient'**
  String get costPaid;

  /// No description provided for @costTotal.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get costTotal;

  /// No description provided for @costAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available: balance minus pending transactions'**
  String get costAvailable;

  /// No description provided for @costRemaining.
  ///
  /// In en, this message translates to:
  /// **'Left after sending'**
  String get costRemaining;

  /// No description provided for @checkingFees.
  ///
  /// In en, this message translates to:
  /// **'Checking network fees…'**
  String get checkingFees;

  /// No description provided for @feeLocal.
  ///
  /// In en, this message translates to:
  /// **'Estimated from what this client has seen ({count} pending since it connected); the node\'s own fee report was not available.'**
  String feeLocal(int count);

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// An address's balance before and after a transaction
  ///
  /// In en, this message translates to:
  /// **'{before} → {after}'**
  String balanceBeforeAfter(String before, String after);

  /// No description provided for @balanceBeforeAfterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Balance: {before} before, {after} after'**
  String balanceBeforeAfterTooltip(String before, String after);

  /// No description provided for @loadingOlder.
  ///
  /// In en, this message translates to:
  /// **'Loading older blocks…'**
  String get loadingOlder;

  /// No description provided for @blockLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading this block…'**
  String get blockLoading;

  /// No description provided for @txSearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for this transaction in the blocks still loading…'**
  String get txSearching;

  /// Consent banner for keeping the downloaded chain in local storage (IndexedDB); nothing is sent anywhere
  ///
  /// In en, this message translates to:
  /// **'Keep a copy of the chain on this device? Later visits then open in seconds instead of downloading everything again. It stays here and is never sent to anyone: no cookies, no tracking. Your wallet key and settings are always kept on this device, as the app needs them to work.'**
  String get storageBanner;

  /// No description provided for @storageAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow necessary storage'**
  String get storageAllow;

  /// No description provided for @storageReject.
  ///
  /// In en, this message translates to:
  /// **'Reject (slower)'**
  String get storageReject;

  /// No description provided for @storageOn.
  ///
  /// In en, this message translates to:
  /// **'Local copy of the chain: on'**
  String get storageOn;

  /// No description provided for @storageOff.
  ///
  /// In en, this message translates to:
  /// **'Local copy of the chain: off (every visit downloads it again)'**
  String get storageOff;

  /// No description provided for @storageTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get storageTurnOn;

  /// No description provided for @storageTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off and delete'**
  String get storageTurnOff;

  /// No description provided for @checkingBalance.
  ///
  /// In en, this message translates to:
  /// **'Checking with the node…'**
  String get checkingBalance;

  /// No description provided for @errTampered.
  ///
  /// In en, this message translates to:
  /// **'The connection was altered or cut: a message failed its integrity check.'**
  String get errTampered;

  /// No description provided for @errStateMismatch.
  ///
  /// In en, this message translates to:
  /// **'The node\'s committed state at block {height} doesn\'t match this client\'s own count of the chain. Don\'t trust this node: connect to another.'**
  String errStateMismatch(int height);

  /// No description provided for @feeFromNode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{From the node: nothing pending.} =1{From the node: 1 pending transaction.} other{From the node: {count} pending transactions.}}'**
  String feeFromNode(int count);

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted by the node and relayed.'**
  String get statusAccepted;

  /// No description provided for @statusRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused by the node'**
  String get statusRefused;

  /// No description provided for @statusInvalid.
  ///
  /// In en, this message translates to:
  /// **'Rejected as invalid'**
  String get statusInvalid;

  /// reason is the node's own explanation, in English
  ///
  /// In en, this message translates to:
  /// **'The node says: {reason}'**
  String nodeReason(String reason);

  /// No description provided for @errCheckpointMismatch.
  ///
  /// In en, this message translates to:
  /// **'The chain doesn\'t lead to this release\'s checkpoint at block {height}: either the release or every node reached is wrong. Stopped; nothing from it can be trusted.'**
  String errCheckpointMismatch(int height);

  /// elapsed: how long ago, e.g. 5 min 12 s ago
  ///
  /// In en, this message translates to:
  /// **'The newest block is from {elapsed}: this node may be behind, or cut off from the network. What you see may be out of date.'**
  String staleTip(String elapsed);

  /// No description provided for @checkingToGenesis.
  ///
  /// In en, this message translates to:
  /// **'Started from the checkpoint at block {height}; checking the headers back to genesis ({done} so far).'**
  String checkingToGenesis(int height, int done);

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @appLicense.
  ///
  /// In en, this message translates to:
  /// **'Apache License 2.0'**
  String get appLicense;

  /// Shown on every screen while connected to a public test network. Say only that the tokens are for testing; never mention prices, value in money, returns or buying.
  ///
  /// In en, this message translates to:
  /// **'Testnet: tokens have no value'**
  String get testnetLabel;

  /// No description provided for @linkNodeRepo.
  ///
  /// In en, this message translates to:
  /// **'Node and protocol source'**
  String get linkNodeRepo;

  /// No description provided for @linkWhitepaper.
  ///
  /// In en, this message translates to:
  /// **'Whitepaper'**
  String get linkWhitepaper;

  /// While the header chain is checked from genesis, before anything can be shown
  ///
  /// In en, this message translates to:
  /// **'Checking block headers: {done} of {total}'**
  String checkingHeaders(int done, int total);

  /// Under a connection error: the client will try the node again by itself
  ///
  /// In en, this message translates to:
  /// **'Trying again in {seconds} s.'**
  String reconnectingIn(int seconds);

  /// No description provided for @languagesFilter.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesFilter;

  /// No description provided for @languageUndetected.
  ///
  /// In en, this message translates to:
  /// **'Undetected'**
  String get languageUndetected;

  /// No description provided for @hideFlaggedThreads.
  ///
  /// In en, this message translates to:
  /// **'Hide threads I flagged'**
  String get hideFlaggedThreads;

  /// Button: star a message or thread, to find it easily and keep its text on this device.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get star;

  /// No description provided for @unstar.
  ///
  /// In en, this message translates to:
  /// **'Remove star'**
  String get unstar;

  /// No description provided for @starredOnly.
  ///
  /// In en, this message translates to:
  /// **'Only starred threads'**
  String get starredOnly;

  /// No description provided for @localNodeRun.
  ///
  /// In en, this message translates to:
  /// **'Run a Murmur node on this computer'**
  String get localNodeRun;

  /// No description provided for @localNodeExplain.
  ///
  /// In en, this message translates to:
  /// **'Your computer checks the whole chain itself, helps relay it, and keeps your own messages available. It keeps only the latest day of the chain, and nobody else\'s messages beyond the one-hour check.'**
  String get localNodeExplain;

  /// No description provided for @localNodeStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting the node…'**
  String get localNodeStarting;

  /// address: where the app's own node listens for peers, as host:port
  ///
  /// In en, this message translates to:
  /// **'The node is running at {address}. The app keeps reading from the node you chose.'**
  String localNodeRunning(String address);

  /// No description provided for @localNodeFailed.
  ///
  /// In en, this message translates to:
  /// **'The node stopped: {reason}'**
  String localNodeFailed(String reason);

  /// No description provided for @localNodeFailedUnknown.
  ///
  /// In en, this message translates to:
  /// **'The node stopped unexpectedly.'**
  String get localNodeFailedUnknown;

  /// No description provided for @localNodeFromCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Starting at the newest blocks: the older ones are checked afterwards.'**
  String get localNodeFromCheckpoint;

  /// height, total: block heights, already formatted
  ///
  /// In en, this message translates to:
  /// **'Catching up with the chain: block {height} of {total}'**
  String localNodeCatchingUp(String height, String total);

  /// height, total: block heights, already formatted
  ///
  /// In en, this message translates to:
  /// **'Checking the older blocks in the background: {height} of {total}'**
  String localNodeCheckingHistory(String height, String total);

  /// No description provided for @localNodeMine.
  ///
  /// In en, this message translates to:
  /// **'Mine with this computer'**
  String get localNodeMine;

  /// No description provided for @localNodeMineNote.
  ///
  /// In en, this message translates to:
  /// **'Mining pays your wallet\'s address, uses electricity and makes your computer work harder. On the testnet, tokens are for testing only.'**
  String get localNodeMineNote;

  /// No description provided for @localNodeMineNeedsWallet.
  ///
  /// In en, this message translates to:
  /// **'Create a wallet first: mining pays its address.'**
  String get localNodeMineNeedsWallet;

  /// name: the wallet the app's own node mines to, as shown everywhere (a name, or a short address)
  ///
  /// In en, this message translates to:
  /// **'Mining pays **{name}**'**
  String localNodeMinesTo(String name);

  /// No description provided for @localNodeCpu.
  ///
  /// In en, this message translates to:
  /// **'Up to {pct}% of one processor core'**
  String localNodeCpu(int pct);

  /// No description provided for @localNodeGpu.
  ///
  /// In en, this message translates to:
  /// **'Mine on the graphics card'**
  String get localNodeGpu;

  /// No description provided for @localNodeGpuNote.
  ///
  /// In en, this message translates to:
  /// **'Much faster than the processor, and it uses more electricity. When the card can\'t be used, mining goes on with the processor.'**
  String get localNodeGpuNote;

  /// No description provided for @localNodeGpuStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting the graphics card. The processor mines meanwhile.'**
  String get localNodeGpuStarting;

  /// device: the graphics card's name, as its driver gives it
  ///
  /// In en, this message translates to:
  /// **'Mining on **{device}**'**
  String localNodeGpuMining(String device);

  /// No description provided for @localNodeGpuMiningAny.
  ///
  /// In en, this message translates to:
  /// **'Mining on **the graphics card**'**
  String get localNodeGpuMiningAny;

  /// No description provided for @localNodeGpuUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The graphics card can\'t be used: **mining goes on with the processor**.'**
  String get localNodeGpuUnavailable;

  /// reason: an English sentence from the node, shown as it is
  ///
  /// In en, this message translates to:
  /// **'What the node says: {reason}'**
  String localNodeGpuDetail(String reason);

  /// Threads left out by the language filter, mutes or own flags
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thread hidden} other{{count} threads hidden}}'**
  String threadsHidden(int count);

  /// No description provided for @searchThreads.
  ///
  /// In en, this message translates to:
  /// **'Search loaded threads'**
  String get searchThreads;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No loaded thread matches.'**
  String get noMatches;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String timeHoursAgo(int n);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String timeDaysAgo(int n);

  /// No description provided for @nameAddress.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameAddress;

  /// No description provided for @aliasTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this address'**
  String get aliasTitle;

  /// Names are local: never published
  ///
  /// In en, this message translates to:
  /// **'The name is kept on this device only. Leave it empty to remove it.'**
  String get aliasHelp;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @mutedNote.
  ///
  /// In en, this message translates to:
  /// **'Muted: its threads and replies are hidden on this device.'**
  String get mutedNote;

  /// Button above a thread's replies, under its first message, that loads the replies before them
  ///
  /// In en, this message translates to:
  /// **'Earlier replies'**
  String get earlierReplies;

  /// In place of a quoted reply that is older than the replies loaded so far
  ///
  /// In en, this message translates to:
  /// **'An earlier reply (tap to load it)'**
  String get quoteNotLoaded;

  /// No description provided for @mutedRepliesHidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reply from a muted address hidden} other{{count} replies from muted addresses hidden}}'**
  String mutedRepliesHidden(int count);

  /// Badge on the Messages tab
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new reply} other{{count} new replies}}'**
  String newReplies(int count);

  /// Prepaid cards that let a newcomer join without buying anything. Never mention prices or money value.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// No description provided for @createInvitations.
  ///
  /// In en, this message translates to:
  /// **'Create invitations'**
  String get createInvitations;

  /// No description provided for @inviteHowMany.
  ///
  /// In en, this message translates to:
  /// **'How many cards'**
  String get inviteHowMany;

  /// No description provided for @inviteFund.
  ///
  /// In en, this message translates to:
  /// **'Fund the cards'**
  String get inviteFund;

  /// No description provided for @inviteCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Murmur invitation'**
  String get inviteCardTitle;

  /// No description provided for @inviteCardSerial.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String inviteCardSerial(int n, int total);

  /// No description provided for @inviteCardFrom.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String inviteCardFrom(String name);

  /// No description provided for @inviteCardHow.
  ///
  /// In en, this message translates to:
  /// **'Scan the code or open the link to join Murmur.'**
  String get inviteCardHow;

  /// No description provided for @inviteClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get inviteClaimed;

  /// No description provided for @inviteChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get inviteChecking;

  /// No description provided for @claimTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re invited'**
  String get claimTitle;

  /// No description provided for @claimInvitedBy.
  ///
  /// In en, this message translates to:
  /// **'Invited by {name}'**
  String claimInvitedBy(String name);

  /// No description provided for @claimHolds.
  ///
  /// In en, this message translates to:
  /// **'This invitation holds {amount}: enough to start your first threads.'**
  String claimHolds(String amount);

  /// No description provided for @claimCreateWallet.
  ///
  /// In en, this message translates to:
  /// **'Create my wallet and claim'**
  String get claimCreateWallet;

  /// No description provided for @claimIntoWallet.
  ///
  /// In en, this message translates to:
  /// **'Claim into my wallet'**
  String get claimIntoWallet;

  /// No description provided for @claimDone.
  ///
  /// In en, this message translates to:
  /// **'Claimed. The tokens reach your wallet with the next block.'**
  String get claimDone;

  /// No description provided for @claimEmpty.
  ///
  /// In en, this message translates to:
  /// **'This invitation has already been claimed, or taken back.'**
  String get claimEmpty;

  /// No description provided for @claimWrongNetwork.
  ///
  /// In en, this message translates to:
  /// **'This invitation is for another network than the node you\'re connected to.'**
  String get claimWrongNetwork;

  /// No description provided for @claimInvalid.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a valid invitation code.'**
  String get claimInvalid;

  /// No description provided for @haveInvitation.
  ///
  /// In en, this message translates to:
  /// **'I have an invitation'**
  String get haveInvitation;

  /// No description provided for @inviteCodeField.
  ///
  /// In en, this message translates to:
  /// **'Invitation code or link'**
  String get inviteCodeField;

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claim;

  /// No description provided for @cancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Cancel invitation'**
  String get cancelInvitation;

  /// No description provided for @inviteCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get inviteCancelled;

  /// No description provided for @cancelInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Cancel this invitation?} other{Cancel {count} invitations?}}'**
  String cancelInviteTitle(int count);

  /// No description provided for @cancelInviteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Its tokens come back, and whoever has the card can no longer claim it.} other{Their tokens come back, and whoever has the cards can no longer claim them.}}'**
  String cancelInviteBody(int count);

  /// No description provided for @keepInvitation.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepInvitation;

  /// No description provided for @printOne.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printOne;

  /// No description provided for @inviteDoneSection.
  ///
  /// In en, this message translates to:
  /// **'Claimed or cancelled ({count})'**
  String inviteDoneSection(int count);

  /// No description provided for @inviteEachLabel.
  ///
  /// In en, this message translates to:
  /// **'Each card'**
  String get inviteEachLabel;

  /// No description provided for @inviteEachCaption.
  ///
  /// In en, this message translates to:
  /// **'Five threads at today\'s fee, plus the fee to claim it.'**
  String get inviteEachCaption;

  /// No description provided for @inviteTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'You pay'**
  String get inviteTotalLabel;

  /// No description provided for @inviteTotalCaption.
  ///
  /// In en, this message translates to:
  /// **'In all, fees included.'**
  String get inviteTotalCaption;

  /// No description provided for @inviteWaitingState.
  ///
  /// In en, this message translates to:
  /// **'Waiting to be claimed'**
  String get inviteWaitingState;

  /// Printed on invitation cards: short, warm, about joining the conversation. Never about money, value or prices.
  ///
  /// In en, this message translates to:
  /// **'Your voice has a seat here.'**
  String get inviteCardSlogan;

  /// No description provided for @inviteCardJoin.
  ///
  /// In en, this message translates to:
  /// **'Scan to join'**
  String get inviteCardJoin;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share…'**
  String get share;

  /// No description provided for @inviteDetailFunded.
  ///
  /// In en, this message translates to:
  /// **'Funded'**
  String get inviteDetailFunded;

  /// No description provided for @inviteDetailClaimedBy.
  ///
  /// In en, this message translates to:
  /// **'Claimed by'**
  String get inviteDetailClaimedBy;

  /// No description provided for @inviteDetailReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get inviteDetailReceived;

  /// No description provided for @inviteDetailCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled: the tokens came back to your wallet'**
  String get inviteDetailCancelled;

  /// No description provided for @inviteDetailReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get inviteDetailReturned;

  /// No description provided for @inviteDetailOnItsWay.
  ///
  /// In en, this message translates to:
  /// **'On its way to a block'**
  String get inviteDetailOnItsWay;

  /// No description provided for @seedConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Show your seed?'**
  String get seedConfirmTitle;

  /// No description provided for @seedConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Anyone who sees the seed can spend from this wallet. Make sure nobody else can see your screen.'**
  String get seedConfirmBody;

  /// No description provided for @showAction.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showAction;

  /// No description provided for @authReasonSeed.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to see the wallet seed'**
  String get authReasonSeed;

  /// No description provided for @authReasonRemove.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to remove this wallet'**
  String get authReasonRemove;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed: nothing was shown or changed.'**
  String get authFailed;

  /// No description provided for @passphraseNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a passphrase'**
  String get passphraseNewTitle;

  /// First of three points under the title Choose a passphrase: what it protects. The passphrase is shared by the wallet and the invitation cards.
  ///
  /// In en, this message translates to:
  /// **'**One passphrase for this app.** It encrypts your wallet key and your invitation cards\' codes on this device.'**
  String get passphraseNewWhat;

  /// No description provided for @passphraseNewWhen.
  ///
  /// In en, this message translates to:
  /// **'You\'ll type it **every time** you send, show the seed or remove the wallet, and to show, print or cancel a card.'**
  String get passphraseNewWhen;

  /// No description provided for @passphraseNewForget.
  ///
  /// In en, this message translates to:
  /// **'If you forget it, only your **seed backup** brings the wallet back, and cards not yet handed over can no longer be shown or cancelled.'**
  String get passphraseNewForget;

  /// No description provided for @passphraseField.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphraseField;

  /// No description provided for @passphraseRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat the passphrase'**
  String get passphraseRepeat;

  /// No description provided for @passphraseTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least {min} characters'**
  String passphraseTooShort(int min);

  /// No description provided for @passphraseMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two don\'t match'**
  String get passphraseMismatch;

  /// No description provided for @passphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphraseTitle;

  /// No description provided for @wrongPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Wrong passphrase: nothing was shown or sent.'**
  String get wrongPassphrase;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @authReasonSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to sign and send'**
  String get authReasonSend;

  /// No description provided for @authReasonNewWallet.
  ///
  /// In en, this message translates to:
  /// **'Protect your wallet key on this device'**
  String get authReasonNewWallet;

  /// No description provided for @authReasonInvite.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to fund the cards'**
  String get authReasonInvite;

  /// No description provided for @removeAnywayTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove without confirming?'**
  String get removeAnywayTitle;

  /// No description provided for @removeAnywayBody.
  ///
  /// In en, this message translates to:
  /// **'The wallet couldn\'t be unlocked. Removing it deletes its key from this device: only your seed backup can bring it back.'**
  String get removeAnywayBody;

  /// Wallet tab: how the key is protected (Android/iOS/macOS key store)
  ///
  /// In en, this message translates to:
  /// **'Key encrypted with this device\'s lock'**
  String get protectionDevice;

  /// Wallet tab: how the key is protected (browser passkey)
  ///
  /// In en, this message translates to:
  /// **'Key encrypted with a passkey on this device'**
  String get protectionPasskey;

  /// Wallet tab: how the key is protected (passphrase)
  ///
  /// In en, this message translates to:
  /// **'Key encrypted with your passphrase'**
  String get protectionPassphrase;

  /// Wallet tab: a key from an earlier version, still in plain secure storage
  ///
  /// In en, this message translates to:
  /// **'Key not encrypted yet: it will be at the next unlock'**
  String get protectionLegacy;

  /// Title of the final summary before signing
  ///
  /// In en, this message translates to:
  /// **'Check before signing'**
  String get confirmSendTitle;

  /// Last line of the final summary before signing
  ///
  /// In en, this message translates to:
  /// **'Signing sends this to the node. It can\'t be taken back: once mined, it stays on the chain.'**
  String get confirmSendFinal;

  /// Tooltip of the send button; keys is the shortcut, such as Ctrl+Enter
  ///
  /// In en, this message translates to:
  /// **'Sign and send ({keys})'**
  String signAndSendShortcut(String keys);

  /// Threads list: a thread the user flagged themselves (their own)
  ///
  /// In en, this message translates to:
  /// **'You withdrew it: hidden from others, and its text deleted from Murmur apps'**
  String get threadWithdrawnMine;

  /// Thread page: the user flagged their own thread
  ///
  /// In en, this message translates to:
  /// **'You flagged your own thread, which withdraws it. Murmur apps no longer show it to others and delete its text, on this device too; nodes may stop keeping its text and replies.'**
  String get threadWithdrawnMineNote;

  /// Thread page: the author flagged their own thread
  ///
  /// In en, this message translates to:
  /// **'Its author flagged this thread, which withdraws it. Murmur apps no longer list it and delete its text, and nodes may stop keeping its text and replies.'**
  String get threadWithdrawnNote;

  /// Compose: flagging one of your own messages
  ///
  /// In en, this message translates to:
  /// **'This is your own message. Flagging it withdraws it: Murmur apps stop showing it to others and delete its text, on this device too, and nodes may stop keeping its text and replies. It can\'t be undone.'**
  String get flagOwnInfo;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'Name on the cards'**
  String get inviteFromTitle;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'Each card says who it\'s from. The cards were funded by the inviting wallet, which may not be the one on this device now.'**
  String get inviteFromBody;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'Inviting wallet\'s address'**
  String get inviteFromOriginal;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'Your name for the inviting wallet'**
  String get inviteFromOriginalAlias;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'Inviting wallet\'s public name'**
  String get inviteFromOriginalPublic;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'This wallet\'s address'**
  String get inviteFromCurrent;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'Your name for this wallet'**
  String get inviteFromCurrentAlias;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'This wallet\'s public name'**
  String get inviteFromCurrentPublic;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'Other text'**
  String get inviteFromCustom;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'Leave it empty to print no name'**
  String get inviteFromCustomHint;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'No name given on this device'**
  String get inviteFromNotSet;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'Differs between the selected cards'**
  String get inviteFromMixed;

  /// Invitations, printing: which name the cards show
  ///
  /// In en, this message translates to:
  /// **'Still being looked up on the chain'**
  String get inviteFromChecking;

  /// Invitations, cancelling: where the card's tokens go
  ///
  /// In en, this message translates to:
  /// **'Send the tokens to'**
  String get cancelReturnTo;

  /// Invitations, cancelling: where the card's tokens go
  ///
  /// In en, this message translates to:
  /// **'The wallet that funded it'**
  String get cancelToFunder;

  /// Invitations, cancelling: where the card's tokens go
  ///
  /// In en, this message translates to:
  /// **'This wallet'**
  String get cancelToCurrent;

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'Public name'**
  String get publicName;

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'None known'**
  String get publicNameNone;

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'Set public name'**
  String get publicNameSet;

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get publicNameField;

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'At most {max} bytes'**
  String aliasTooLong(int max);

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'Invisible or control characters aren\'t allowed'**
  String get aliasBadCharacter;

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'No spaces at the start or end'**
  String get aliasEdgeSpace;

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'Public name: {name}'**
  String aliasSetTo(String name);

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'Public name cleared'**
  String get aliasCleared;

  /// A Name carrying a profile: a public name and a picture (PROTOCOL.md 7.8)
  ///
  /// In en, this message translates to:
  /// **'Public name and picture: {name}'**
  String profileSetTo(String name);

  /// A Name carrying a profile whose name is empty: a picture alone (PROTOCOL.md 7.8)
  ///
  /// In en, this message translates to:
  /// **'Public picture, without a name'**
  String get profilePictureOnly;

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'(not text: data for an app convention)'**
  String get nonTextMessage;

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'Publishes your public name. Like a new thread, it costs {total} × the fee: the fee goes to the miner, and {burn} × the fee is burned.'**
  String explainAlias(int total, int burn);

  /// Aliases (PROTOCOL.md 7.8) and non-text messages (2.4)
  ///
  /// In en, this message translates to:
  /// **'No public name known'**
  String get inviteFromNoPublic;

  /// The Starred tab
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get starredTitle;

  /// The Starred tab
  ///
  /// In en, this message translates to:
  /// **'Nothing starred yet. Star a thread, a message or a person from their page, and they show up here.'**
  String get noStarred;

  /// The Starred tab
  ///
  /// In en, this message translates to:
  /// **'No longer on the chain'**
  String get starredGone;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'Suggested fee'**
  String get feeSuggestedLabel;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'for {weight} bytes'**
  String feeForBytes(int weight);

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'Blocks have room'**
  String get feeRoom;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'Blocks are full'**
  String get feeFull;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'Next block'**
  String get feeNextBlock;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'To enter the pool'**
  String get feePoolEntry;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get feeMinimum;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'Why this fee'**
  String get feeWhy;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**Fees are per byte**: {base} bytes plus your message. Longer messages cost more when blocks are full.'**
  String feePerBytePoint(int base);

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**Recent blocks** took fees as low as **{lowest}** (median {median}).'**
  String feeRecentPoint(String lowest, String median);

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**Recent blocks** had no transactions.'**
  String get feeRecentNonePoint;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**No expiry**: a card works until someone claims it.'**
  String get inviteNoExpiryPoint;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**Cancel any time**: its tokens come back.'**
  String get inviteCancelPoint;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**Public**: the chain shows you funded each card, and which wallet claimed it.'**
  String get invitePublicPoint;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**Whoever has the code** can claim the card. Keep cards private until you hand them over.'**
  String get inviteCashPoint;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**Kept only on this device.** If its data is cleared or the app is removed, the codes are **lost for good**, and so are the tokens on cards not yet handed over.'**
  String get inviteLocalPoint;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'Your public name appears **next to your address** in Murmur apps.'**
  String get publicNameIntro;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'Appears as **{name}**'**
  String publicNameShownAs(String name);

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**Not unique**: anyone can pick the same name. The address beside it tells people apart.'**
  String get publicNameNotUnique;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**Costs as much as a new thread**, each time you set or change it.'**
  String get publicNameCost;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**A message on the chain**: any node may delete it, and then it\'s gone.'**
  String get publicNameRemovable;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**Leave it empty** to clear it.'**
  String get publicNameClear;

  /// The Public name dialog's picture section (a profile, PROTOCOL.md 7.8)
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get publicNamePicture;

  /// Button: choose a profile picture from the phone's photo library
  ///
  /// In en, this message translates to:
  /// **'From photos'**
  String get pictureFromPhotos;

  /// Button: choose a profile picture from the phone's files
  ///
  /// In en, this message translates to:
  /// **'From files'**
  String get pictureFromFiles;

  /// Button: choose a profile picture from a file (desktop, browser)
  ///
  /// In en, this message translates to:
  /// **'Choose a picture'**
  String get pictureChoose;

  /// Button: publish the name without a picture
  ///
  /// In en, this message translates to:
  /// **'Remove picture'**
  String get pictureRemove;

  /// A picked picture file is too large
  ///
  /// In en, this message translates to:
  /// **'That file is too large: choose one under {size} MB.'**
  String pictureTooLarge(String size);

  /// A picked file isn't an image the app can decode
  ///
  /// In en, this message translates to:
  /// **'That file can\'t be read as a picture.'**
  String get pictureUnreadable;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**32 × 32 pixels, 16 colours**, shown instead of your address\'s mark.'**
  String get picturePoint;

  /// Words between ** show in bold copper (Emphasized); keep the markers around the key words
  ///
  /// In en, this message translates to:
  /// **'**About three times the cost** with a picture.'**
  String get pictureCost;

  /// Browser: the chosen passkey manager lacks WebAuthn PRF. Words between ** show in bold copper
  ///
  /// In en, this message translates to:
  /// **'This passkey manager can\'t protect the wallet'**
  String get passkeyNoPrfTitle;

  /// Browser: the chosen passkey manager lacks WebAuthn PRF. Words between ** show in bold copper
  ///
  /// In en, this message translates to:
  /// **'**It can\'t encrypt.** To lock your wallet key, a passkey manager has to derive a key from the passkey (WebAuthn PRF). The one you picked doesn\'t.'**
  String get passkeyNoPrfWhy;

  /// Browser: the chosen passkey manager lacks WebAuthn PRF. Words between ** show in bold copper
  ///
  /// In en, this message translates to:
  /// **'**Try another manager**, such as Apple Passwords or Google Password Manager, or protect the wallet with a **passphrase**.'**
  String get passkeyNoPrfTry;

  /// Browser: the chosen passkey manager lacks WebAuthn PRF. Words between ** show in bold copper
  ///
  /// In en, this message translates to:
  /// **'The passkey it just saved (**Murmur wallet**) unlocks nothing: you can delete it from that manager.'**
  String get passkeyNoPrfLeftover;

  /// Browser: the chosen passkey manager lacks WebAuthn PRF. Words between ** show in bold copper
  ///
  /// In en, this message translates to:
  /// **'Try another passkey manager'**
  String get passkeyTryAnother;

  /// Browser: the chosen passkey manager lacks WebAuthn PRF. Words between ** show in bold copper
  ///
  /// In en, this message translates to:
  /// **'Use a passphrase'**
  String get passkeyUsePassphrase;

  /// A cancelled card whose tokens went to another wallet than this one (name is marked for Emphasized)
  ///
  /// In en, this message translates to:
  /// **'Cancelled: the tokens went to {name}'**
  String inviteDetailCancelledTo(String name);

  /// Title of the dialog that shows a newly created wallet its seed
  ///
  /// In en, this message translates to:
  /// **'Save your wallet\'s seed'**
  String get seedNewTitle;

  /// New wallet seed dialog: where to keep the seed. ** marks emphasis
  ///
  /// In en, this message translates to:
  /// **'**Keep it somewhere safe**, away from this device: written on paper, or in a password manager.'**
  String get seedNewKeep;

  /// New wallet seed dialog: why it matters. ** marks emphasis
  ///
  /// In en, this message translates to:
  /// **'It is the **only way back** to this wallet if this device is lost or its passphrase forgotten. Nobody can recover it for you.'**
  String get seedNewOnlyWay;

  /// New wallet seed dialog: keep it secret. ** marks emphasis
  ///
  /// In en, this message translates to:
  /// **'**Anyone who has it controls the wallet.** Never share it, and never type it into a site that asks for it.'**
  String get seedNewSecret;

  /// Checkbox the user ticks before the new wallet seed dialog can be closed
  ///
  /// In en, this message translates to:
  /// **'I have saved my seed'**
  String get seedNewSaved;

  /// Heading over the seed written as 24 words
  ///
  /// In en, this message translates to:
  /// **'As 24 words'**
  String get seedAsWords;

  /// Heading over the seed written as 64 hex characters
  ///
  /// In en, this message translates to:
  /// **'As 64 characters'**
  String get seedAsHex;

  /// Under the two forms of the seed
  ///
  /// In en, this message translates to:
  /// **'Both are the same seed: either one is enough.'**
  String get seedEitherForm;

  /// Button: copy the 24 words of the seed
  ///
  /// In en, this message translates to:
  /// **'Copy words'**
  String get copyWords;

  /// Button: copy the 64 characters of the seed
  ///
  /// In en, this message translates to:
  /// **'Copy characters'**
  String get copyCharacters;

  /// Label of the field where a seed is typed or pasted to import a wallet
  ///
  /// In en, this message translates to:
  /// **'Seed: 24 words or 64 characters'**
  String get seedOrWords;

  /// Error: one of the 24 words is not a seed word
  ///
  /// In en, this message translates to:
  /// **'\"{word}\" is not one of the seed words. Check its spelling.'**
  String seedUnknownWord(String word);

  /// Error: 24 valid words that do not make a seed
  ///
  /// In en, this message translates to:
  /// **'These 24 words do not make a seed: one of them is wrong or out of place.'**
  String get seedBadChecksum;

  /// Share menu entry that shows a QR code of the link
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get qrCode;

  /// Under the QR code of an address: what scanning it does
  ///
  /// In en, this message translates to:
  /// **'Scan to open this address in Murmur.'**
  String get addressQrHint;

  /// Starred tab: heading of the starred people
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get starredPeople;

  /// Starred tab: heading of the starred messages (a starred thread is its starred first message)
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get starredThreads;

  /// Starred tab: the threads and messages list, empty
  ///
  /// In en, this message translates to:
  /// **'No starred threads or messages. Star one from its page and it shows up here.'**
  String get noStarredThreads;

  /// Starred tab: the people list, empty
  ///
  /// In en, this message translates to:
  /// **'No starred people. Star someone from their page and they show up here.'**
  String get noStarredPeople;

  /// Starred tab: a mark on a starred thread or person with activity the user has not seen
  ///
  /// In en, this message translates to:
  /// **'New activity'**
  String get newActivity;

  /// Badge on the Starred tab
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 starred with new activity} other{{count} starred with new activity}}'**
  String starredNew(int count);

  /// Why the device check or passphrase is asked: to read the invitation cards' codes (show, print, cancel)
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to unlock the invitation cards'**
  String get authReasonCards;

  /// Invitations page, one of the points on how cards work. **…** marks the key words
  ///
  /// In en, this message translates to:
  /// **'**Codes are stored encrypted.** Showing, printing or cancelling a card asks you to **unlock** them.'**
  String get inviteLockedPoint;

  /// Notifications: the settings dialog's title, and its button's tooltip
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Notifications: switch for replies in the wallet's threads and answers to its replies
  ///
  /// In en, this message translates to:
  /// **'Replies and answers to you'**
  String get notifyReplies;

  /// Notifications: switch for messages that mention the wallet
  ///
  /// In en, this message translates to:
  /// **'Mentions of you'**
  String get notifyMentions;

  /// Notifications: switch for replies under starred threads and messages by starred people
  ///
  /// In en, this message translates to:
  /// **'News on what you starred'**
  String get notifyStarred;

  /// Notifications: under a switch that needs a wallet when there is none
  ///
  /// In en, this message translates to:
  /// **'Needs a wallet on this device'**
  String get notifyNeedsWallet;

  /// Notifications: the system refused the permission
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for Murmur in the system\'s settings.'**
  String get notifyDenied;

  /// Notifications dialog, a point: the app checks by itself, no push service. **…** marks the key words
  ///
  /// In en, this message translates to:
  /// **'**Checked by this app**, on the node you chose: nothing goes through Google, Apple or anyone else.'**
  String get notifyPointLocal;

  /// Notifications dialog, a point (Android): how often the app checks while closed. **…** marks the key words
  ///
  /// In en, this message translates to:
  /// **'While the app is closed, it checks **about every 15 minutes**, as the system allows.'**
  String get notifyPointBackground;

  /// Notifications dialog, a point (desktop and web): only while the app is open. **…** marks the key words
  ///
  /// In en, this message translates to:
  /// **'Only **while the app is open**, when it isn\'t in front.'**
  String get notifyPointOpen;

  /// Notifications dialog, a point (Android): the lock screen hides the text. **…** marks the key words
  ///
  /// In en, this message translates to:
  /// **'The lock screen **hides what they say**.'**
  String get notifyPointLockScreen;

  /// Android's name for the app's notifications, shown in the system's settings
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notifyChannel;

  /// Linux: the name of a notification's default action
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notifyOpen;

  /// Notification title: a reply in the wallet's thread
  ///
  /// In en, this message translates to:
  /// **'{name} replied to your thread'**
  String notifyReply(String name);

  /// Notification title: an answer to the wallet's reply
  ///
  /// In en, this message translates to:
  /// **'{name} answered you'**
  String notifyAnswer(String name);

  /// Notification title: a message mentioning the wallet
  ///
  /// In en, this message translates to:
  /// **'{name} mentioned you'**
  String notifyMention(String name);

  /// Notification title: a reply under a starred thread or message
  ///
  /// In en, this message translates to:
  /// **'{name} replied in a thread you starred'**
  String notifyStarredReply(String name);

  /// Notification title: a message by a starred person
  ///
  /// In en, this message translates to:
  /// **'New message from {name}'**
  String notifyStarredPerson(String name);

  /// Notification: how many more messages than the ones shown
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more new message} other{{count} more new messages}}'**
  String notifyMore(int count);

  /// iOS: why Face ID is asked for, shown by iOS the first time (Info.plist's NSFaceIDUsageDescription; tool/ios_localizations.dart copies it there)
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you before your wallet\'s key is used or shown.'**
  String get faceIdReason;

  /// Threads tab: takes the list again at the newest block
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Messages and Starred tabs: a button that marks every row of the list as read
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// Address page opened from a marked starred person: a line under their new messages
  ///
  /// In en, this message translates to:
  /// **'Above: new since your last visit'**
  String get newAboveLastVisit;

  /// Wallet tab: the heading of the wallet's public name and picture; also the dialog that sets them
  ///
  /// In en, this message translates to:
  /// **'Public name and picture'**
  String get publicNameAndPicture;

  /// Wallet tab: the button that opens the public name and picture dialog
  ///
  /// In en, this message translates to:
  /// **'Set public name and picture'**
  String get publicNameAndPictureSet;

  /// Wallet tab: what setting a public name and picture does; **…** marks the key words
  ///
  /// In en, this message translates to:
  /// **'**Stand out**: a name and a picture others see beside your address.'**
  String get publicNameStandOut;

  /// Address page: tooltip of the picture, which a tap shows larger
  ///
  /// In en, this message translates to:
  /// **'Show the picture larger'**
  String get pictureLarger;

  /// Wallet tab: switch that lets readers get the user's own messages from this device, through the node, when nodes no longer keep them
  ///
  /// In en, this message translates to:
  /// **'Keep my messages available'**
  String get keepMessagesAvailable;

  /// Wallet tab: what Keep my messages available does; **…** marks the key words
  ///
  /// In en, this message translates to:
  /// **'**While the app is open**, readers get your messages from you when nodes no longer keep them. **Only yours**, never anyone else\'s.'**
  String get keepMessagesAvailableExplain;

  /// Connection error: a transaction in a block the node served has an invalid signature (PROTOCOL.md Section 1)
  ///
  /// In en, this message translates to:
  /// **'Block {height} holds a transaction whose signature isn\'t valid: the node\'s chain breaks the rules every node applies. Don\'t trust this node: connect to another.'**
  String errBadSignature(int height);

  /// Messages tab: the node's lists of flags, answers and mentions left entries out, which the client found in blocks; **…** marks the key words
  ///
  /// In en, this message translates to:
  /// **'**The node left out** some of what others did about you ({count}). It\'s shown all the same, found in the blocks themselves.'**
  String receivedOmitted(String count);

  /// Linux: saving a wallet failed because the system keyring is locked and has no password prompt
  ///
  /// In en, this message translates to:
  /// **'The system keyring is locked and can\'t ask for its password, so the wallet can\'t be saved on this device. Unlock the keyring (logging in to the desktop usually does) and start Murmur again.'**
  String get keyringUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'it',
        'ja',
        'ko',
        'nl',
        'pt',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
