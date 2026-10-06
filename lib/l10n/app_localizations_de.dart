// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => 'Thread';

  @override
  String get kindReply => 'Antwort';

  @override
  String get kindTransfer => 'Überweisung';

  @override
  String get kindFlag => 'Meldung';

  @override
  String get contentUnavailable =>
      '(Inhalt nicht verfügbar: Der Knoten hat ihn nicht)';

  @override
  String get contentWithdrawn => '(vom Autor zurückgezogen)';

  @override
  String get contentLoading => '(Nachricht wird geladen…)';

  @override
  String get pending => 'ausstehend';

  @override
  String get copy => 'Kopieren';

  @override
  String get copied => 'Kopiert';

  @override
  String replyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Antworten',
      one: '1 Antwort',
      zero: 'Keine Antworten',
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
      other: '$countString Meldungen',
      one: '1 Meldung',
      zero: 'Keine Meldungen',
    );
    return '$_temp0';
  }

  @override
  String transferOf(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Überweisung von $amountString';
  }

  @override
  String flagOn(String text) {
    return 'Meldung zu „$text“';
  }

  @override
  String flagOnTx(String txid) {
    return 'Meldung zu $txid';
  }

  @override
  String get replyNotThreaded => 'Antwort (in keinem Thread)';

  @override
  String routeFrom(String address) {
    return 'von $address';
  }

  @override
  String routeFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String errUnreachable(String detail) {
    return 'Der Knoten ist nicht erreichbar: $detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return 'Die WebSocket-Brücke unter $url ist nicht erreichbar. Starte sie mit: dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return 'Verbindungsfehler: $detail';
  }

  @override
  String get errClosed => 'Der Knoten hat die Verbindung geschlossen.';

  @override
  String get errTimeout => 'Der Knoten hat nicht rechtzeitig geantwortet.';

  @override
  String errProtocol(String detail) {
    return 'Protokollfehler: $detail';
  }

  @override
  String errVersion(int node, int ours) {
    return 'Der Knoten spricht Protokoll $node; dieser Client spricht Protokoll $ours.';
  }

  @override
  String errSyncFailed(String cause) {
    return 'Synchronisierung fehlgeschlagen: $cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return 'Ein weitergeleiteter Block wurde ignoriert: $detail';
  }

  @override
  String get probFeeTooLow => 'Die Gebühr muss mindestens 1 betragen.';

  @override
  String get probMalformed => 'Diese Transaktion ist fehlerhaft aufgebaut.';

  @override
  String get probNeedsMessage => 'Schreib eine Nachricht.';

  @override
  String get probNeedsRecipient => 'Gib einen Empfänger an.';

  @override
  String probAmountBelowFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Der Betrag muss mindestens der Gebühr ($feeString) entsprechen.';
  }

  @override
  String get probReplyParentNotMined =>
      'Du kannst nur auf einen Thread oder eine Antwort antworten, die bereits in einem Block ist.';

  @override
  String get probReplyWrongRecipient =>
      'Eine Antwort muss den Autor der beantworteten Nachricht bezahlen.';

  @override
  String get probFlagNotMessage =>
      'Nur Threads und Antworten können gemeldet werden.';

  @override
  String get probAlreadyFlagged =>
      'Diese Wallet hat diese Nachricht bereits gemeldet.';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Die Nachricht ist $lengthString Byte lang; das Limit ist $limitString.';
  }

  @override
  String probInsufficientBalance(int needed, int available) {
    final intl.NumberFormat neededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String neededString = neededNumberFormat.format(needed);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return 'Guthaben reicht nicht: $neededString benötigt, $availableString verfügbar (bestätigtes Guthaben abzüglich ausstehender Transaktionen).';
  }

  @override
  String get probNotLive =>
      'Warte, bis der Client verbunden und synchronisiert ist.';

  @override
  String get probConnectionLost => 'Die Verbindung zum Knoten ist abgebrochen.';

  @override
  String get probDuplicate =>
      'In dieser Sekunde wurde bereits eine identische Transaktion gesendet.';

  @override
  String get tabThreads => 'Threads';

  @override
  String get tabMessages => 'Nachrichten';

  @override
  String get tabWallet => 'Wallet';

  @override
  String get tabChain => 'Chain';

  @override
  String get newThread => 'Neuer Thread';

  @override
  String get createWalletFirst =>
      'Erstelle oder importiere zuerst eine Wallet.';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get reconnect => 'Neu verbinden';

  @override
  String get changeNode => 'Knoten wechseln';

  @override
  String get unknownNetwork =>
      'Dieser Knoten ist in einem Netz, das der Client nicht kennt. Seine Schwierigkeitsanpassungen lassen sich nicht prüfen, und Blockbelohnungen werden mit den Werten aus dem Whitepaper berechnet, daher können Miner-Guthaben abweichen.';

  @override
  String get linkOffline => 'Offline';

  @override
  String get linkConnecting => 'Verbinde…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return 'Synchronisiere $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Live · $heightString';
  }

  @override
  String get connectToNode => 'Mit einem Knoten verbinden';

  @override
  String nodeAt(String address) {
    return 'Knoten $address';
  }

  @override
  String get language => 'Sprache';

  @override
  String get systemLanguage => 'Systemsprache';

  @override
  String get lightMode => 'Heller Modus';

  @override
  String get darkMode => 'Dunkler Modus';

  @override
  String get node => 'Knoten';

  @override
  String get connectHelpBridge =>
      'Im Browser verbindet sich der Client über WebSocket: mit der WebSocket-Adresse eines Knotens (etwa node.murmur.info, Port 443, über TLS) oder mit einer lokalen Bridge (dart run tool/ws_bridge.dart, Port 7880).';

  @override
  String get connectHelpNative =>
      'Die Peer-to-Peer-Adresse eines murmur-node (sein --port, standardmäßig 7878). Der Steuerport (7879) funktioniert nicht.';

  @override
  String get host => 'Host';

  @override
  String get port => 'Port';

  @override
  String get required => 'Pflichtfeld';

  @override
  String get enterPort => 'Gib eine Portnummer ein';

  @override
  String get disconnect => 'Trennen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get connect => 'Verbinden';

  @override
  String get syncingChain => 'Chain wird synchronisiert…';

  @override
  String get noThreads =>
      'Noch keine Threads. Starte einen mit „Neuer Thread“.';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Stand Block $heightString ($time, $elapsed)';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seitdem $countString neue Blöcke',
      one: 'seitdem 1 neuer Block',
      zero: 'aktuell',
    );
    return '$_temp0';
  }

  @override
  String agoSeconds(int s) {
    return 'vor $s s';
  }

  @override
  String agoMinutes(int m, int s) {
    return 'vor $m Min. $s s';
  }

  @override
  String agoHours(int h, int m) {
    return 'vor $h Std. $m Min.';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return 'vor $dString T. $h Std.';
  }

  @override
  String get refresh => 'Aktualisieren';

  @override
  String threadStarted(String time) {
    return 'gestartet $time';
  }

  @override
  String threadLastReply(String time) {
    return 'letzte Antwort $time';
  }

  @override
  String get messagesNeedWallet =>
      'Erstelle oder importiere im Tab „Wallet“ eine Wallet, um deine Nachrichten zu sehen.';

  @override
  String get noMessages => 'Keine Nachrichten passen zu diesen Filtern.';

  @override
  String get filterThreads => 'Meine Threads';

  @override
  String get filterRepliesSent => 'Gesendete Antworten';

  @override
  String get filterRepliesReceived => 'Erhaltene Antworten';

  @override
  String get filterFlagsSent => 'Gemeldet';

  @override
  String get filterFlagsReceived => 'Erhaltene Meldungen';

  @override
  String get balance => 'Guthaben';

  @override
  String pendingCommitted(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString in ausstehenden Transaktionen gebunden';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Blöcke gemined',
      one: '1 Block gemined',
      zero: 'Keine Blöcke gemined',
    );
    return '$_temp0';
  }

  @override
  String get address => 'Adresse';

  @override
  String get showSeed => 'Seed anzeigen';

  @override
  String get removeWallet => 'Wallet entfernen';

  @override
  String get history => 'Verlauf';

  @override
  String get filters => 'Filter';

  @override
  String get noHistory => 'Keine Transaktionen passen zu diesen Filtern.';

  @override
  String get walletFilterTransfersSent => 'Gesendete Überweisungen';

  @override
  String get walletFilterTransfersReceived => 'Erhaltene Überweisungen';

  @override
  String get walletFilterRepliesPaid => 'Für Antworten bezahlt';

  @override
  String get walletFilterRepliesEarned => 'Durch Antworten verdient';

  @override
  String get walletFilterThreadCosts => 'Thread-Kosten';

  @override
  String get walletFilterFlagCosts => 'Meldegebühren';

  @override
  String get seedTitle => 'Wallet-Seed';

  @override
  String get seedWarning =>
      'Wer diesen Seed hat, kann über diese Wallet verfügen. Er hat dasselbe Format wie eine mit murmur-node keygen erstellte Schlüsseldatei.';

  @override
  String get done => 'Fertig';

  @override
  String get removeWalletTitle => 'Wallet entfernen?';

  @override
  String get removeWalletBody =>
      'Der Seed wird von diesem Gerät gelöscht. Ohne eine Kopie ist jedes Guthaben dieser Adresse verloren.';

  @override
  String get remove => 'Entfernen';

  @override
  String get importWallet => 'Wallet importieren';

  @override
  String get importHelp =>
      'Gib den Seed einer Wallet ein oder füge ihn ein: seine 24 Wörter oder seine 64 Hex-Zeichen (zum Beispiel den Inhalt einer mit murmur-node keygen erstellten Schlüsseldatei, murmur.key, um die an ihre Adresse geschürften Belohnungen zu nutzen).';

  @override
  String get seed => 'Seed';

  @override
  String get import => 'Importieren';

  @override
  String get seedInvalid =>
      'Ein Seed besteht aus 24 Wörtern oder genau 64 Hex-Zeichen.';

  @override
  String get walletIntro =>
      'Eine Wallet signiert die Transaktionen, die du sendest. Ihr Schlüssel bleibt auf diesem Gerät.';

  @override
  String get createWallet => 'Neue Wallet erstellen';

  @override
  String get importSeed => 'Seed importieren';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return 'Kein Block auf Höhe $heightString (die Spitze ist $tipString).';
  }

  @override
  String get searchInvalid =>
      'Gib eine Blockhöhe oder eine 64-stellige Txid, einen Block-Hash oder eine Adresse ein.';

  @override
  String get searchHint => 'Höhe, Txid, Block-Hash oder Adresse suchen';

  @override
  String get noBlocks => 'Noch keine Blöcke.';

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
      other: '$countString Tx',
      one: '1 Tx',
    );
    return '$_temp0';
  }

  @override
  String minerIs(String miner) {
    return 'Miner $miner';
  }

  @override
  String get statNetwork => 'Netz';

  @override
  String get statHeight => 'Höhe';

  @override
  String get statNodeHeight => 'Höhe des Knotens';

  @override
  String get statNextReward => 'Belohnung des nächsten Blocks';

  @override
  String rewardPlusFees(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString + Gebühren';
  }

  @override
  String get statBurnPool => 'Burn-Pool';

  @override
  String get statCirculating => 'Im Umlauf';

  @override
  String get tip => 'Spitze';

  @override
  String get previousBlock => 'Vorheriger Block';

  @override
  String get nextBlock => 'Nächster Block';

  @override
  String get blockGone => 'Dieser Block ist nicht mehr auf der besten Chain.';

  @override
  String get hash => 'Hash';

  @override
  String get previous => 'Vorgänger';

  @override
  String get time => 'Zeit';

  @override
  String get confirmations => 'Bestätigungen';

  @override
  String get miner => 'Miner';

  @override
  String get reward => 'Belohnung';

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

    return '$subsidyString Subvention + $payoutString aus dem Burn-Pool + $feesString Gebühren';
  }

  @override
  String get merkleRoot => 'Merkle-Wurzel';

  @override
  String get target => 'Ziel';

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
      other: '$countString Transaktionen',
      one: '1 Transaktion',
      zero: 'Keine Transaktionen',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => 'Deine Adresse';

  @override
  String get noTransactions => 'Keine Transaktionen.';

  @override
  String get sendToAddress => 'An diese Adresse senden';

  @override
  String get threadGone => 'Dieser Thread ist nicht mehr auf der Chain.';

  @override
  String paidToParent(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'zahlte $amountString an den Autor der Ausgangsnachricht';
  }

  @override
  String get actionReply => 'Antworten';

  @override
  String get actionFlag => 'Melden';

  @override
  String get flagged => 'Gemeldet';

  @override
  String get details => 'Details';

  @override
  String get txTitle => 'Transaktion';

  @override
  String get txNotFound =>
      'Transaktion nicht gefunden. Sie wurde vielleicht aus den ausstehenden entfernt oder durch eine Reorganisation verworfen.';

  @override
  String refNotLocal(String txid) {
    return 'Transaktion $txid (nicht in der lokalen Chain)';
  }

  @override
  String get flaggedMessage => 'Gemeldete Nachricht';

  @override
  String get inReplyTo => 'Antwort auf';

  @override
  String get notThreadedExplain =>
      'Nennt diese Nachricht, gehört aber nicht zu ihrem Thread: Die Nachricht muss ein geminter Thread oder eine geminte Antwort sein, und diese Antwort muss ihren Autor bezahlen. Sie zählt nur als Zahlung.';

  @override
  String get message => 'Nachricht';

  @override
  String get openThread => 'Thread öffnen';

  @override
  String get transactionId => 'Transaktions-ID';

  @override
  String get type => 'Typ';

  @override
  String get from => 'Von';

  @override
  String get to => 'An';

  @override
  String get burned => 'Verbrannt';

  @override
  String burnedValue(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString (geht über den Burn-Pool an die Miner zurück)';
  }

  @override
  String get amount => 'Betrag';

  @override
  String get fee => 'Gebühr';

  @override
  String get signedAt => 'Signiert am';

  @override
  String get contentHash => 'Inhalts-Hash';

  @override
  String get contentSize => 'Inhaltsgröße';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString Byte ($salt Byte Salt und $messageString Byte Nachricht)';
  }

  @override
  String get reports => 'Meldet';

  @override
  String get repliesTo => 'Antwortet auf';

  @override
  String get weight => 'Gewicht';

  @override
  String weightValue(int weight, String perByte) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString Byte ($perByte Gebühr pro Byte)';
  }

  @override
  String get publicKey => 'Öffentlicher Schlüssel';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Bestätigt in Block $heightString';
  }

  @override
  String confirmationCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Bestätigungen',
      one: '1 Bestätigung',
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
      other: 'Nach $countString Blöcken nicht bestätigt',
      one: 'Nach 1 Block nicht bestätigt',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused =>
      'Der Knoten hat sie womöglich abgelehnt (zum Beispiel, weil sich das Guthaben vor dem Minen geändert hat). Über abgelehnte Transaktionen gibt er keine Rückmeldung.';

  @override
  String get sentWaiting => 'Gesendet, wartet auf einen Block';

  @override
  String get submittedHere => 'Von diesem Gerät gesendet.';

  @override
  String get pendingTitle => 'Ausstehend';

  @override
  String get relayedPending =>
      'Vom Knoten weitergeleitet, noch in keinem Block.';

  @override
  String get viewBlock => 'Block ansehen';

  @override
  String get newTransaction => 'Neue Transaktion';

  @override
  String get flagMessage => 'Nachricht melden';

  @override
  String flaggingInfo(String author) {
    return 'Du meldest diese Nachricht von $author. Jede Wallet kann eine Nachricht nur einmal melden. Was mit Meldungen geschieht, entscheidet jeder Client selbst.';
  }

  @override
  String replyingTo(String author) {
    return 'Antwort an $author';
  }

  @override
  String explainThread(int total, int burn) {
    return 'Startet einen neuen Thread. Er kostet das $total-Fache der Gebühr: Die Gebühr geht an den Miner, und das $burn-Fache der Gebühr wird verbrannt. Verbrannte Token gehen in den folgenden Blöcken an die Miner zurück.';
  }

  @override
  String get explainReply =>
      'Deine Antwort zahlt dem Autor der Nachricht mindestens die Gebühr (du kannst mehr als Trinkgeld geben), dazu die Gebühr an den Miner.';

  @override
  String get explainTransfer =>
      'Eine einfache Token-Überweisung ohne Nachricht. Der Betrag muss mindestens der Gebühr entsprechen.';

  @override
  String get recipientAddress => 'Empfängeradresse';

  @override
  String get enterAddress => 'Gib eine 64-stellige Hex-Adresse ein';

  @override
  String get payToAuthor => 'An den Autor zahlen';

  @override
  String get wholeNumber => 'Ganze Zahl';

  @override
  String atLeastFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Mindestens die Gebühr ($feeString)';
  }

  @override
  String get feeToMiner => 'Gebühr (an den Miner)';

  @override
  String suggestedFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Vorschlag: $feeString';
  }

  @override
  String get atLeastOne => 'Mindestens 1';

  @override
  String bytesOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString Byte';
  }

  @override
  String tooLong(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Zu lang: $countString Byte';
  }

  @override
  String get sendingNeedsLive =>
      'Senden ist möglich, sobald der Client verbunden und synchronisiert ist.';

  @override
  String get signAndSend => 'Signieren und senden';

  @override
  String get costFee => 'Gebühr, an den Miner';

  @override
  String costBurn(int multiple) {
    return 'Verbrannt: das $multiple-Fache der Gebühr';
  }

  @override
  String get costPaid => 'An den Empfänger gezahlt';

  @override
  String get costTotal => 'Gesamtkosten';

  @override
  String get costAvailable =>
      'Verfügbar: Guthaben abzüglich ausstehender Transaktionen';

  @override
  String get costRemaining => 'Übrig nach dem Senden';

  @override
  String get checkingFees => 'Netzgebühren werden abgefragt…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Geschätzt aus dem, was dieser Client gesehen hat ($countString ausstehend seit der Verbindung); der Gebührenbericht des Knotens war nicht verfügbar.';
  }

  @override
  String get use => 'Übernehmen';

  @override
  String get checkAgain => 'Erneut abfragen';

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

    return 'Guthaben: vorher $beforeString, nachher $afterString';
  }

  @override
  String chainCounted(int counted, int total) {
    final intl.NumberFormat countedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countedString = countedNumberFormat.format(counted);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$countedString von $totalString Blöcken gezählt';
  }

  @override
  String get loadingOlder => 'Ältere Blöcke werden geladen…';

  @override
  String get blockLoading => 'Dieser Block wird geladen…';

  @override
  String get txSearching =>
      'Diese Transaktion wird in den noch ladenden Blöcken gesucht…';

  @override
  String get storageBanner =>
      'Eine Kopie der Chain auf diesem Gerät behalten? Spätere Besuche öffnen dann in Sekunden, statt alles neu herunterzuladen. Sie bleibt hier und wird nie an jemanden gesendet: keine Cookies, kein Tracking. Dein Wallet-Schlüssel und deine Einstellungen bleiben immer auf diesem Gerät, weil die App sie braucht.';

  @override
  String get storageAllow => 'Notwendige Speicherung erlauben';

  @override
  String get storageReject => 'Ablehnen (langsamer)';

  @override
  String get storageOn => 'Lokale Kopie der Chain: an';

  @override
  String get storageOff =>
      'Lokale Kopie der Chain: aus (jeder Besuch lädt sie neu)';

  @override
  String get storageTurnOn => 'Einschalten';

  @override
  String get storageTurnOff => 'Ausschalten und löschen';

  @override
  String get checkingBalance => 'Wird beim Knoten geprüft…';

  @override
  String get errTampered =>
      'Die Verbindung wurde verändert oder unterbrochen: Eine Nachricht hat ihre Integritätsprüfung nicht bestanden.';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Der Zustand, auf den sich der Knoten in Block $heightString festlegt, stimmt nicht mit der eigenen Zählung dieses Clients überein. Vertrau diesem Knoten nicht: Verbinde dich mit einem anderen.';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Laut Knoten: $countString ausstehende Transaktionen.',
      one: 'Laut Knoten: 1 ausstehende Transaktion.',
      zero: 'Laut Knoten: nichts ausstehend.',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => 'Vom Knoten angenommen und weitergeleitet.';

  @override
  String get statusRefused => 'Vom Knoten abgelehnt';

  @override
  String get statusInvalid => 'Als ungültig zurückgewiesen';

  @override
  String nodeReason(String reason) {
    return 'Der Knoten meldet: $reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Die Chain führt nicht zum Checkpoint dieser Version bei Block $heightString: Entweder die Version oder alle erreichten Knoten liegen falsch. Angehalten; nichts davon ist vertrauenswürdig.';
  }

  @override
  String staleTip(String elapsed) {
    return 'Der neueste Block ist von $elapsed: Dieser Knoten hinkt vielleicht hinterher oder ist vom Netz abgeschnitten. Was du siehst, ist womöglich veraltet.';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return 'Vom Checkpoint bei Block $heightString gestartet; die Header bis zur Genesis werden geprüft (bisher $doneString).';
  }

  @override
  String get licenses => 'Lizenzen';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => 'Testnetz: Token haben keinen Wert';

  @override
  String get linkNodeRepo => 'Quellcode von Knoten und Protokoll';

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

    return 'Blockheader werden geprüft: $doneString von $totalString';
  }

  @override
  String reconnectingIn(int seconds) {
    return 'Neuer Versuch in $seconds s.';
  }

  @override
  String get languagesFilter => 'Sprachen';

  @override
  String get languageUndetected => 'Nicht erkannt';

  @override
  String get hideFlaggedThreads => 'Von mir gemeldete Threads ausblenden';

  @override
  String get star => 'Mit Stern markieren';

  @override
  String get unstar => 'Stern entfernen';

  @override
  String get starredOnly => 'Nur markierte Threads';

  @override
  String get localNodeRun =>
      'Einen Murmur-Knoten auf diesem Computer betreiben';

  @override
  String get localNodeExplain =>
      'Dein Computer prüft die Kette selbst, hilft sie weiterzugeben und hält deine eigenen Nachrichten verfügbar. Nachrichten anderer behält er nicht über die einstündige Prüfung hinaus.';

  @override
  String get localNodeStarting => 'Knoten wird gestartet…';

  @override
  String get localNodeRunning => 'Der Knoten läuft, und die App nutzt ihn.';

  @override
  String localNodeFailed(String reason) {
    return 'Der Knoten wurde beendet: $reason';
  }

  @override
  String get localNodeFailedUnknown => 'Der Knoten wurde unerwartet beendet.';

  @override
  String get localNodeMine => 'Mit diesem Computer minen';

  @override
  String get localNodeMineNote =>
      'Mining zahlt an die Adresse deiner Wallet, verbraucht Strom und lässt deinen Computer mehr arbeiten. Im Testnet sind Tokens nur zum Testen da.';

  @override
  String get localNodeMineNeedsWallet =>
      'Lege zuerst eine Wallet an: Mining zahlt an ihre Adresse.';

  @override
  String localNodeCpu(int pct) {
    return 'Bis zu $pct % eines Prozessorkerns';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Threads ausgeblendet',
      one: '1 Thread ausgeblendet',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => 'Geladene Threads durchsuchen';

  @override
  String get noMatches => 'Kein geladener Thread passt.';

  @override
  String get timeJustNow => 'gerade eben';

  @override
  String timeMinutesAgo(int n) {
    return 'vor $n Min.';
  }

  @override
  String timeHoursAgo(int n) {
    return 'vor $n Std.';
  }

  @override
  String timeDaysAgo(int n) {
    return 'vor $n T.';
  }

  @override
  String get nameAddress => 'Name';

  @override
  String get aliasTitle => 'Dieser Adresse einen Namen geben';

  @override
  String get aliasHelp =>
      'Der Name bleibt nur auf diesem Gerät. Leer lassen, um ihn zu entfernen.';

  @override
  String get save => 'Speichern';

  @override
  String get mute => 'Stummschalten';

  @override
  String get unmute => 'Stummschaltung aufheben';

  @override
  String get mutedNote =>
      'Stummgeschaltet: Ihre Threads und Antworten sind auf diesem Gerät ausgeblendet.';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Antworten stummgeschalteter Adressen ausgeblendet',
      one: '1 Antwort einer stummgeschalteten Adresse ausgeblendet',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Antworten',
      one: '1 neue Antwort',
    );
    return '$_temp0';
  }

  @override
  String get invitations => 'Einladungen';

  @override
  String get createInvitations => 'Einladungen erstellen';

  @override
  String get inviteHowMany => 'Wie viele Karten';

  @override
  String get inviteFund => 'Karten finanzieren';

  @override
  String get inviteCardTitle => 'Einladung zu Murmur';

  @override
  String inviteCardSerial(int n, int total) {
    return '$n von $total';
  }

  @override
  String inviteCardFrom(String name) {
    return 'Von $name';
  }

  @override
  String get inviteCardHow =>
      'Code scannen oder Link öffnen, um Murmur beizutreten.';

  @override
  String get inviteClaimed => 'Eingelöst';

  @override
  String get inviteChecking => 'Wird geprüft…';

  @override
  String get claimTitle => 'Du bist eingeladen';

  @override
  String claimInvitedBy(String name) {
    return 'Eingeladen von $name';
  }

  @override
  String claimHolds(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Diese Einladung enthält $amountString: genug für deine ersten Threads.';
  }

  @override
  String get claimCreateWallet => 'Wallet erstellen und einlösen';

  @override
  String get claimIntoWallet => 'In meine Wallet einlösen';

  @override
  String get claimDone =>
      'Eingelöst. Die Token kommen mit dem nächsten Block in deiner Wallet an.';

  @override
  String get claimEmpty =>
      'Diese Einladung wurde schon eingelöst oder zurückgeholt.';

  @override
  String get claimWrongNetwork =>
      'Diese Einladung gehört zu einem anderen Netz als der Knoten, mit dem du verbunden bist.';

  @override
  String get claimInvalid => 'Das ist kein gültiger Einladungscode.';

  @override
  String get haveInvitation => 'Ich habe eine Einladung';

  @override
  String get inviteCodeField => 'Einladungscode oder Link';

  @override
  String get claim => 'Einlösen';

  @override
  String get cancelInvitation => 'Einladung stornieren';

  @override
  String get inviteCancelled => 'Storniert';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einladungen stornieren?',
      one: 'Diese Einladung stornieren?',
    );
    return '$_temp0';
  }

  @override
  String cancelInviteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ihre Token kommen zurück, und wer die Karten hat, kann sie nicht mehr einlösen.',
      one:
          'Ihre Token kommen zurück, und wer die Karte hat, kann sie nicht mehr einlösen.',
    );
    return '$_temp0';
  }

  @override
  String get keepInvitation => 'Behalten';

  @override
  String get printOne => 'Drucken';

  @override
  String inviteDoneSection(int count) {
    return 'Eingelöst oder storniert ($count)';
  }

  @override
  String get inviteEachLabel => 'Jede Karte';

  @override
  String get inviteEachCaption =>
      'Fünf Threads zur heutigen Gebühr, plus die Gebühr zum Einlösen.';

  @override
  String get inviteTotalLabel => 'Du zahlst';

  @override
  String get inviteTotalCaption => 'Insgesamt, Gebühren inbegriffen.';

  @override
  String get inviteWaitingState => 'Wartet auf Einlösung';

  @override
  String get inviteCardSlogan => 'Deine Stimme hat hier einen Platz.';

  @override
  String get inviteCardJoin => 'Scannen und mitmachen';

  @override
  String get share => 'Teilen…';

  @override
  String get inviteDetailFunded => 'Finanziert';

  @override
  String get inviteDetailClaimedBy => 'Eingelöst von';

  @override
  String get inviteDetailReceived => 'Erhalten';

  @override
  String get inviteDetailCancelled =>
      'Storniert: Die Token sind zurück in deiner Wallet';

  @override
  String get inviteDetailReturned => 'Zurück';

  @override
  String get inviteDetailOnItsWay => 'Unterwegs in einen Block';

  @override
  String get seedConfirmTitle => 'Seed anzeigen?';

  @override
  String get seedConfirmBody =>
      'Wer den Seed sieht, kann aus dieser Wallet ausgeben. Achte darauf, dass niemand sonst deinen Bildschirm sieht.';

  @override
  String get showAction => 'Anzeigen';

  @override
  String get authReasonSeed =>
      'Bestätige, dass du es bist, um den Seed zu sehen';

  @override
  String get authReasonRemove =>
      'Bestätige, dass du es bist, um diese Wallet zu entfernen';

  @override
  String get authFailed =>
      'Nicht bestätigt: Nichts wurde angezeigt oder geändert.';

  @override
  String get passphraseNewTitle => 'Passphrase wählen';

  @override
  String get passphraseNewBody =>
      'Sie verschlüsselt den Schlüssel deiner Wallet auf diesem Gerät. Du gibst sie ein, um zu senden, den Seed anzuzeigen oder die Wallet zu entfernen. Wenn du sie vergisst, kann nur deine Seed-Sicherung die Wallet zurückholen.';

  @override
  String get passphraseField => 'Passphrase';

  @override
  String get passphraseRepeat => 'Passphrase wiederholen';

  @override
  String passphraseTooShort(int min) {
    return 'Mindestens $min Zeichen';
  }

  @override
  String get passphraseMismatch => 'Die beiden stimmen nicht überein';

  @override
  String get passphraseTitle => 'Passphrase';

  @override
  String get wrongPassphrase =>
      'Falsche Passphrase: Nichts wurde angezeigt oder gesendet.';

  @override
  String get unlock => 'Entsperren';

  @override
  String get authReasonSend =>
      'Bestätige, dass du es bist, um zu signieren und zu senden';

  @override
  String get authReasonNewWallet =>
      'Schütze den Schlüssel deiner Wallet auf diesem Gerät';

  @override
  String get authReasonInvite =>
      'Bestätige, dass du es bist, um die Karten zu finanzieren';

  @override
  String get removeAnywayTitle => 'Ohne Bestätigung entfernen?';

  @override
  String get removeAnywayBody =>
      'Die Wallet konnte nicht entsperrt werden. Wenn du sie entfernst, wird ihr Schlüssel von diesem Gerät gelöscht: Nur deine Seed-Sicherung kann sie zurückholen.';

  @override
  String get protectionDevice =>
      'Schlüssel mit der Sperre dieses Geräts verschlüsselt';

  @override
  String get protectionPasskey =>
      'Schlüssel mit einem Passkey auf diesem Gerät verschlüsselt';

  @override
  String get protectionPassphrase =>
      'Schlüssel mit deiner Passphrase verschlüsselt';

  @override
  String get protectionLegacy =>
      'Schlüssel noch nicht verschlüsselt: beim nächsten Entsperren';

  @override
  String get confirmSendTitle => 'Vor dem Signieren prüfen';

  @override
  String get confirmSendFinal =>
      'Beim Signieren geht dies an den Knoten. Es lässt sich nicht zurücknehmen: Einmal gemint, bleibt es in der Kette.';

  @override
  String signAndSendShortcut(String keys) {
    return 'Signieren und senden ($keys)';
  }

  @override
  String get threadWithdrawnMine =>
      'Von dir zurückgezogen: für andere verborgen, der Text in Murmur-Apps gelöscht';

  @override
  String get threadWithdrawnMineNote =>
      'Du hast deinen eigenen Thread gemeldet und ihn damit zurückgezogen. Murmur-Apps zeigen ihn anderen nicht mehr und löschen seinen Text, auch auf diesem Gerät; Knoten können aufhören, seinen Text und die Antworten zu speichern.';

  @override
  String get threadWithdrawnNote =>
      'Der Autor hat diesen Thread gemeldet und ihn damit zurückgezogen. Murmur-Apps listen ihn nicht mehr und löschen seinen Text, und Knoten können aufhören, seinen Text und die Antworten zu speichern.';

  @override
  String get flagOwnInfo =>
      'Das ist deine eigene Nachricht. Wenn du sie meldest, ziehst du sie zurück: Murmur-Apps zeigen sie anderen nicht mehr und löschen ihren Text, auch auf diesem Gerät, und Knoten können aufhören, ihren Text und die Antworten zu speichern. Das lässt sich nicht rückgängig machen.';

  @override
  String get inviteFromTitle => 'Name auf den Karten';

  @override
  String get inviteFromBody =>
      'Jede Karte sagt, von wem sie ist. Finanziert hat sie die einladende Wallet, die jetzt vielleicht nicht mehr die auf diesem Gerät ist.';

  @override
  String get inviteFromOriginal => 'Adresse der einladenden Wallet';

  @override
  String get inviteFromOriginalAlias => 'Dein Name für die einladende Wallet';

  @override
  String get inviteFromOriginalPublic =>
      'Öffentlicher Name der einladenden Wallet';

  @override
  String get inviteFromCurrent => 'Adresse dieser Wallet';

  @override
  String get inviteFromCurrentAlias => 'Dein Name für diese Wallet';

  @override
  String get inviteFromCurrentPublic => 'Öffentlicher Name dieser Wallet';

  @override
  String get inviteFromCustom => 'Anderer Text';

  @override
  String get inviteFromCustomHint => 'Leer lassen, um keinen Namen zu drucken';

  @override
  String get inviteFromNotSet => 'Auf diesem Gerät kein Name vergeben';

  @override
  String get inviteFromMixed => 'Unterschiedlich bei den gewählten Karten';

  @override
  String get inviteFromChecking => 'Wird noch in der Kette gesucht';

  @override
  String get cancelReturnTo => 'Token senden an';

  @override
  String get cancelToFunder => 'Die Wallet, die sie finanziert hat';

  @override
  String get cancelToCurrent => 'Diese Wallet';

  @override
  String get publicName => 'Öffentlicher Name';

  @override
  String get publicNameNone => 'Keiner bekannt';

  @override
  String get publicNameSet => 'Öffentlichen Namen festlegen';

  @override
  String get publicNameField => 'Name';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return 'Höchstens $maxString Bytes';
  }

  @override
  String get aliasBadCharacter =>
      'Unsichtbare oder Steuerzeichen sind nicht erlaubt';

  @override
  String get aliasEdgeSpace => 'Keine Leerzeichen am Anfang oder Ende';

  @override
  String aliasSetTo(String name) {
    return 'Öffentlicher Name: $name';
  }

  @override
  String get aliasCleared => 'Öffentlicher Name entfernt';

  @override
  String get nonTextMessage => '(kein Text: Daten einer App-Konvention)';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return 'Veröffentlicht deinen öffentlichen Namen. Wie ein neuer Thread kostet er $totalString × die Gebühr: Die Gebühr geht an den Miner, $burnString × die Gebühr wird verbrannt.';
  }

  @override
  String get inviteFromNoPublic => 'Kein öffentlicher Name bekannt';

  @override
  String get starredTitle => 'Markiert';

  @override
  String get noStarred =>
      'Noch nichts markiert. Markiere einen Thread, eine Nachricht oder eine Person auf ihrer Seite, dann erscheint sie hier.';

  @override
  String get starredGone => 'Nicht mehr in der Kette';

  @override
  String get feeSuggestedLabel => 'Vorgeschlagene Gebühr';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return 'für $weightString Bytes';
  }

  @override
  String get feeRoom => 'Blöcke haben Platz';

  @override
  String get feeFull => 'Blöcke sind voll';

  @override
  String get feeNextBlock => 'Nächster Block';

  @override
  String get feePoolEntry => 'Um in den Pool zu kommen';

  @override
  String get feeMinimum => 'Minimum';

  @override
  String get feeWhy => 'Warum diese Gebühr';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**Gebühren gelten pro Byte**: $baseString Bytes plus deine Nachricht. Lange Nachrichten kosten mehr, wenn die Blöcke voll sind.';
  }

  @override
  String feeRecentPoint(int lowest, int median) {
    final intl.NumberFormat lowestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lowestString = lowestNumberFormat.format(lowest);
    final intl.NumberFormat medianNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String medianString = medianNumberFormat.format(median);

    return '**Letzte Blöcke** nahmen Gebühren ab **$lowestString** (Median $medianString).';
  }

  @override
  String get feeRecentNonePoint =>
      '**Letzte Blöcke** hatten keine Transaktionen.';

  @override
  String get inviteNoExpiryPoint =>
      '**Läuft nicht ab**: Eine Karte gilt, bis jemand sie einlöst.';

  @override
  String get inviteCancelPoint =>
      '**Jederzeit stornierbar**: Ihre Token kommen zurück.';

  @override
  String get invitePublicPoint =>
      '**Öffentlich**: Die Kette zeigt, dass du jede Karte finanziert hast und welche Wallet sie eingelöst hat.';

  @override
  String get inviteCashPoint =>
      '**Wer den Code hat**, kann die Karte einlösen. Halte Karten privat, bis du sie übergibst.';

  @override
  String get inviteLocalPoint =>
      '**Nur auf diesem Gerät gespeichert.** Werden seine Daten gelöscht oder die App entfernt, sind die Codes **für immer verloren**, ebenso die Token auf noch nicht übergebenen Karten.';

  @override
  String get publicNameIntro =>
      'Dein öffentlicher Name steht in Murmur-Apps **neben deiner Adresse**.';

  @override
  String publicNameShownAs(String name) {
    return 'Erscheint als **$name**';
  }

  @override
  String get publicNameNotUnique =>
      '**Nicht eindeutig**: Jeder kann denselben Namen wählen. Die Adresse daneben unterscheidet die Leute.';

  @override
  String get publicNameCost =>
      '**Kostet so viel wie ein neuer Thread**, jedes Mal, wenn du ihn setzt oder änderst.';

  @override
  String get publicNameRemovable =>
      '**Eine Nachricht in der Kette**: Jeder Knoten kann sie löschen, dann ist sie weg.';

  @override
  String get publicNameClear => '**Leer lassen**, um ihn zu entfernen.';

  @override
  String get passkeyNoPrfTitle =>
      'Dieser Passkey-Manager kann die Wallet nicht schützen';

  @override
  String get passkeyNoPrfWhy =>
      '**Er kann nicht verschlüsseln.** Um den Wallet-Schlüssel zu sperren, muss der Manager aus dem Passkey einen Schlüssel ableiten (WebAuthn PRF). Der gewählte kann das nicht.';

  @override
  String get passkeyNoPrfTry =>
      '**Versuche einen anderen Manager**, etwa Apple Passwörter oder den Google Passwortmanager, oder schütze die Wallet mit einer **Passphrase**.';

  @override
  String get passkeyNoPrfLeftover =>
      'Der eben gespeicherte Passkey (**Murmur wallet**) entsperrt nichts: Du kannst ihn in diesem Manager löschen.';

  @override
  String get passkeyTryAnother => 'Anderen Passkey-Manager versuchen';

  @override
  String get passkeyUsePassphrase => 'Passphrase verwenden';

  @override
  String inviteDetailCancelledTo(String name) {
    return 'Storniert: Die Token gingen an $name';
  }

  @override
  String get seedNewTitle => 'Sichere den Seed deiner Wallet';

  @override
  String get seedNewKeep =>
      '**Bewahre ihn sicher auf**, getrennt von diesem Gerät: auf Papier geschrieben oder in einem Passwortmanager.';

  @override
  String get seedNewOnlyWay =>
      'Er ist der **einzige Weg zurück** zu dieser Wallet, wenn dieses Gerät verloren geht oder die Passphrase vergessen wird. Niemand kann ihn für dich wiederherstellen.';

  @override
  String get seedNewSecret =>
      '**Wer ihn hat, kontrolliert die Wallet.** Gib ihn nie weiter und tippe ihn nie auf einer Website ein, die danach fragt.';

  @override
  String get seedNewSaved => 'Ich habe meinen Seed gesichert';

  @override
  String get seedAsWords => 'Als 24 Wörter';

  @override
  String get seedAsHex => 'Als 64 Zeichen';

  @override
  String get seedEitherForm =>
      'Beides ist derselbe Seed: eines von beiden genügt.';

  @override
  String get copyWords => 'Wörter kopieren';

  @override
  String get copyCharacters => 'Zeichen kopieren';

  @override
  String get seedOrWords => 'Seed: 24 Wörter oder 64 Zeichen';

  @override
  String seedUnknownWord(String word) {
    return '„$word“ ist keines der Seed-Wörter. Prüfe die Schreibweise.';
  }

  @override
  String get seedBadChecksum =>
      'Diese 24 Wörter ergeben keinen Seed: eines ist falsch oder steht an der falschen Stelle.';

  @override
  String get qrCode => 'QR-Code';

  @override
  String get addressQrHint => 'Scannen, um diese Adresse in Murmur zu öffnen.';

  @override
  String get starredPeople => 'Personen';

  @override
  String get starredThreads => 'Threads und Nachrichten';

  @override
  String get newActivity => 'Neue Aktivität';

  @override
  String starredNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count markierte Einträge mit neuer Aktivität',
      one: '1 markierter Eintrag mit neuer Aktivität',
    );
    return '$_temp0';
  }
}
