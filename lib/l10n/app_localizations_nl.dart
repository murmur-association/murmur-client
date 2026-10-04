// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => 'Draad';

  @override
  String get kindReply => 'Antwoord';

  @override
  String get kindTransfer => 'Overboeking';

  @override
  String get kindFlag => 'Melding';

  @override
  String get contentUnavailable =>
      '(inhoud niet beschikbaar: de node heeft hem niet)';

  @override
  String get contentWithdrawn => '(ingetrokken door de auteur)';

  @override
  String get contentLoading => '(bericht wordt geladen…)';

  @override
  String get pending => 'in behandeling';

  @override
  String get copy => 'Kopiëren';

  @override
  String get copied => 'Gekopieerd';

  @override
  String replyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString antwoorden',
      one: '1 antwoord',
      zero: 'Geen antwoorden',
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
      other: '$countString meldingen',
      one: '1 melding',
      zero: 'Geen meldingen',
    );
    return '$_temp0';
  }

  @override
  String transferOf(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Overboeking van $amountString';
  }

  @override
  String flagOn(String text) {
    return 'Melding over ‘$text’';
  }

  @override
  String flagOnTx(String txid) {
    return 'Melding over $txid';
  }

  @override
  String get replyNotThreaded => 'Antwoord (niet in een draad)';

  @override
  String routeFrom(String address) {
    return 'van $address';
  }

  @override
  String routeFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String errUnreachable(String detail) {
    return 'De node is niet bereikbaar: $detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return 'De WebSocket-brug op $url is niet bereikbaar. Start hem met: dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return 'Verbindingsfout: $detail';
  }

  @override
  String get errClosed => 'De node heeft de verbinding gesloten.';

  @override
  String get errTimeout => 'De node reageerde niet op tijd.';

  @override
  String errProtocol(String detail) {
    return 'Protocolfout: $detail';
  }

  @override
  String errVersion(int node, int ours) {
    return 'De node spreekt protocol $node; deze client spreekt protocol $ours.';
  }

  @override
  String errSyncFailed(String cause) {
    return 'Synchroniseren mislukt: $cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return 'Een doorgestuurd blok is genegeerd: $detail';
  }

  @override
  String get probFeeTooLow => 'De vergoeding moet minstens 1 zijn.';

  @override
  String get probMalformed => 'Deze transactie is niet goed opgebouwd.';

  @override
  String get probNeedsMessage => 'Schrijf een bericht.';

  @override
  String get probNeedsRecipient => 'Geef een ontvanger op.';

  @override
  String probAmountBelowFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Het bedrag moet minstens de vergoeding ($feeString) zijn.';
  }

  @override
  String get probReplyParentNotMined =>
      'Je kunt alleen antwoorden op een draad of antwoord dat al in een blok staat.';

  @override
  String get probReplyWrongRecipient =>
      'Een antwoord moet de auteur betalen van het bericht waarop het antwoordt.';

  @override
  String get probFlagNotMessage =>
      'Alleen draden en antwoorden kunnen gemeld worden.';

  @override
  String get probAlreadyFlagged => 'Deze wallet heeft dat bericht al gemeld.';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Het bericht is $lengthString bytes; de limiet is $limitString.';
  }

  @override
  String probInsufficientBalance(int needed, int available) {
    final intl.NumberFormat neededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String neededString = neededNumberFormat.format(needed);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return 'Onvoldoende saldo: $neededString nodig, $availableString beschikbaar (bevestigd saldo min openstaande transacties).';
  }

  @override
  String get probNotLive =>
      'Wacht tot de client verbonden en gesynchroniseerd is.';

  @override
  String get probConnectionLost => 'De verbinding met de node is verbroken.';

  @override
  String get probDuplicate =>
      'Er is deze seconde al een identieke transactie verstuurd.';

  @override
  String get tabThreads => 'Draden';

  @override
  String get tabMessages => 'Berichten';

  @override
  String get tabWallet => 'Wallet';

  @override
  String get tabChain => 'Keten';

  @override
  String get newThread => 'Nieuwe draad';

  @override
  String get createWalletFirst => 'Maak of importeer eerst een wallet.';

  @override
  String get syncNow => 'Nu synchroniseren';

  @override
  String get reconnect => 'Opnieuw verbinden';

  @override
  String get changeNode => 'Andere node';

  @override
  String get unknownNetwork =>
      'Deze node zit op een netwerk dat de client niet kent. De moeilijkheidsaanpassingen kunnen niet worden gecontroleerd, en blokbeloningen worden met de waarden uit de whitepaper berekend, dus saldi van miners kunnen afwijken.';

  @override
  String get linkOffline => 'Offline';

  @override
  String get linkConnecting => 'Verbinden…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return 'Synchroniseren $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Live · $heightString';
  }

  @override
  String get connectToNode => 'Verbinden met een node';

  @override
  String nodeAt(String address) {
    return 'Node $address';
  }

  @override
  String get language => 'Taal';

  @override
  String get systemLanguage => 'Systeemtaal';

  @override
  String get lightMode => 'Lichte modus';

  @override
  String get darkMode => 'Donkere modus';

  @override
  String get node => 'Node';

  @override
  String get connectHelpBridge =>
      'In de browser verbindt de client via WebSocket: met het WebSocket-adres van een node (zoals node.murmur.info, poort 443, via TLS) of met een lokale bridge (dart run tool/ws_bridge.dart, poort 7880).';

  @override
  String get connectHelpNative =>
      'Het peer-to-peer-adres van een murmur-node (zijn --port, standaard 7878). De beheerpoort (7879) werkt niet.';

  @override
  String get host => 'Host';

  @override
  String get port => 'Poort';

  @override
  String get required => 'Verplicht';

  @override
  String get enterPort => 'Geef een poortnummer op';

  @override
  String get disconnect => 'Verbreken';

  @override
  String get cancel => 'Annuleren';

  @override
  String get connect => 'Verbinden';

  @override
  String get syncingChain => 'Keten synchroniseren…';

  @override
  String get noThreads => 'Nog geen draden. Begin er een met Nieuwe draad.';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Stand bij blok $heightString ($time, $elapsed)';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sindsdien $countString nieuwe blokken',
      one: 'sindsdien 1 nieuw blok',
      zero: 'bijgewerkt',
    );
    return '$_temp0';
  }

  @override
  String agoSeconds(int s) {
    return '$s s geleden';
  }

  @override
  String agoMinutes(int m, int s) {
    return '$m min $s s geleden';
  }

  @override
  String agoHours(int h, int m) {
    return '$h u $m min geleden';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return '$dString d $h u geleden';
  }

  @override
  String get refresh => 'Vernieuwen';

  @override
  String threadStarted(String time) {
    return 'gestart $time';
  }

  @override
  String threadLastReply(String time) {
    return 'laatste antwoord $time';
  }

  @override
  String get messagesNeedWallet =>
      'Maak of importeer een wallet in het tabblad Wallet om je berichten te zien.';

  @override
  String get noMessages => 'Geen berichten voldoen aan deze filters.';

  @override
  String get filterThreads => 'Mijn draden';

  @override
  String get filterRepliesSent => 'Verstuurde antwoorden';

  @override
  String get filterRepliesReceived => 'Ontvangen antwoorden';

  @override
  String get filterFlagsSent => 'Gedane meldingen';

  @override
  String get filterFlagsReceived => 'Ontvangen meldingen';

  @override
  String get balance => 'Saldo';

  @override
  String pendingCommitted(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString vastgelegd in openstaande transacties';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString blokken gemined',
      one: '1 blok gemined',
      zero: 'Geen blokken gemined',
    );
    return '$_temp0';
  }

  @override
  String get address => 'Adres';

  @override
  String get showSeed => 'Seed tonen';

  @override
  String get removeWallet => 'Wallet verwijderen';

  @override
  String get history => 'Geschiedenis';

  @override
  String get filters => 'Filters';

  @override
  String get noHistory => 'Geen transacties voldoen aan deze filters.';

  @override
  String get walletFilterTransfersSent => 'Verstuurde overboekingen';

  @override
  String get walletFilterTransfersReceived => 'Ontvangen overboekingen';

  @override
  String get walletFilterRepliesPaid => 'Betaald voor antwoorden';

  @override
  String get walletFilterRepliesEarned => 'Verdiend met antwoorden';

  @override
  String get walletFilterThreadCosts => 'Kosten van draden';

  @override
  String get walletFilterFlagCosts => 'Vergoedingen voor meldingen';

  @override
  String get seedTitle => 'Seed van de wallet';

  @override
  String get seedWarning =>
      'Iedereen met deze seed kan uit deze wallet uitgeven. Hij heeft hetzelfde formaat als een sleutelbestand gemaakt met murmur-node keygen.';

  @override
  String get done => 'Klaar';

  @override
  String get removeWalletTitle => 'Wallet verwijderen?';

  @override
  String get removeWalletBody =>
      'De seed wordt van dit apparaat gewist. Zonder kopie gaat elk saldo op dit adres verloren.';

  @override
  String get remove => 'Verwijderen';

  @override
  String get importWallet => 'Wallet importeren';

  @override
  String get importHelp =>
      'Plak een hexadecimale seed van 64 tekens, bijvoorbeeld de inhoud van een sleutelbestand gemaakt met murmur-node keygen (murmur.key), om de beloningen te gebruiken die naar dat adres zijn gemined.';

  @override
  String get seed => 'Seed';

  @override
  String get import => 'Importeren';

  @override
  String get seedInvalid =>
      'Een seed bestaat uit precies 64 hexadecimale tekens.';

  @override
  String get walletIntro =>
      'Een wallet ondertekent de transacties die je verstuurt. De sleutel blijft op dit apparaat.';

  @override
  String get createWallet => 'Nieuwe wallet maken';

  @override
  String get importSeed => 'Seed importeren';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return 'Geen blok op hoogte $heightString (de top is $tipString).';
  }

  @override
  String get searchInvalid =>
      'Geef een blokhoogte op, of een txid, blokhash of adres van 64 tekens.';

  @override
  String get searchHint => 'Zoek hoogte, txid, blokhash of adres';

  @override
  String get noBlocks => 'Nog geen blokken.';

  @override
  String blockTitle(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Blok $heightString';
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
  String get statNetwork => 'Netwerk';

  @override
  String get statHeight => 'Hoogte';

  @override
  String get statNodeHeight => 'Hoogte van de node';

  @override
  String get statNextReward => 'Beloning volgend blok';

  @override
  String rewardPlusFees(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString + vergoedingen';
  }

  @override
  String get statBurnPool => 'Verbrandingspot';

  @override
  String get statCirculating => 'In omloop';

  @override
  String get tip => 'Top';

  @override
  String get previousBlock => 'Vorig blok';

  @override
  String get nextBlock => 'Volgend blok';

  @override
  String get blockGone => 'Dit blok staat niet meer op de beste keten.';

  @override
  String get hash => 'Hash';

  @override
  String get previous => 'Vorige';

  @override
  String get time => 'Tijd';

  @override
  String get confirmations => 'Bevestigingen';

  @override
  String get miner => 'Miner';

  @override
  String get reward => 'Beloning';

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

    return '$subsidyString subsidie + $payoutString uit de verbrandingspot + $feesString aan vergoedingen';
  }

  @override
  String get merkleRoot => 'Merkle-wortel';

  @override
  String get target => 'Doel';

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
      other: '$countString transacties',
      one: '1 transactie',
      zero: 'Geen transacties',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => 'Jouw adres';

  @override
  String get noTransactions => 'Geen transacties.';

  @override
  String get sendToAddress => 'Naar dit adres sturen';

  @override
  String get threadGone => 'Deze draad staat niet meer op de keten.';

  @override
  String paidToParent(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'betaalde $amountString aan de auteur van het oorspronkelijke bericht';
  }

  @override
  String get actionReply => 'Antwoorden';

  @override
  String get actionFlag => 'Melden';

  @override
  String get flagged => 'Gemeld';

  @override
  String get details => 'Details';

  @override
  String get txTitle => 'Transactie';

  @override
  String get txNotFound =>
      'Transactie niet gevonden. Misschien is ze uit de openstaande transacties gevallen of door een reorganisatie verwijderd.';

  @override
  String refNotLocal(String txid) {
    return 'Transactie $txid (niet op de lokale keten)';
  }

  @override
  String get flaggedMessage => 'Gemeld bericht';

  @override
  String get inReplyTo => 'Antwoord op';

  @override
  String get notThreadedExplain =>
      'Noemt dit bericht, maar hoort niet bij de draad ervan: het bericht moet een geminede draad of een gemined antwoord zijn, en dit antwoord moet de auteur betalen. Het telt alleen als betaling.';

  @override
  String get message => 'Bericht';

  @override
  String get openThread => 'Draad openen';

  @override
  String get transactionId => 'Transactie-ID';

  @override
  String get type => 'Type';

  @override
  String get from => 'Van';

  @override
  String get to => 'Aan';

  @override
  String get burned => 'Verbrand';

  @override
  String burnedValue(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString (gaat via de verbrandingspot terug naar miners)';
  }

  @override
  String get amount => 'Bedrag';

  @override
  String get fee => 'Vergoeding';

  @override
  String get signedAt => 'Ondertekend op';

  @override
  String get contentHash => 'Hash van de inhoud';

  @override
  String get contentSize => 'Grootte van de inhoud';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString bytes (een salt van $salt bytes en een bericht van $messageString bytes)';
  }

  @override
  String get reports => 'Meldt';

  @override
  String get repliesTo => 'Antwoordt op';

  @override
  String get weight => 'Gewicht';

  @override
  String weightValue(int weight, String perByte) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString bytes ($perByte vergoeding per byte)';
  }

  @override
  String get publicKey => 'Publieke sleutel';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Bevestigd in blok $heightString';
  }

  @override
  String confirmationCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bevestigingen',
      one: '1 bevestiging',
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
      other: 'Niet bevestigd na $countString blokken',
      one: 'Niet bevestigd na 1 blok',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused =>
      'De node heeft haar misschien geweigerd (bijvoorbeeld omdat het saldo veranderde voordat ze gemined werd). Over geweigerde transacties geeft hij geen bericht.';

  @override
  String get sentWaiting => 'Verstuurd, wacht op een blok';

  @override
  String get submittedHere => 'Verstuurd vanaf dit apparaat.';

  @override
  String get pendingTitle => 'In behandeling';

  @override
  String get relayedPending =>
      'Doorgestuurd door de node, nog niet in een blok.';

  @override
  String get viewBlock => 'Blok bekijken';

  @override
  String get newTransaction => 'Nieuwe transactie';

  @override
  String get flagMessage => 'Bericht melden';

  @override
  String flaggingInfo(String author) {
    return 'Je meldt dit bericht van $author. Elke wallet kan een bericht één keer melden. Wat er met meldingen gebeurt, bepaalt elke client zelf.';
  }

  @override
  String replyingTo(String author) {
    return 'Antwoord aan $author';
  }

  @override
  String explainThread(int total, int burn) {
    return 'Begint een nieuwe draad. Die kost $total × de vergoeding: de vergoeding gaat naar de miner en $burn × de vergoeding wordt verbrand. Verbrande tokens gaan in de volgende blokken terug naar de miners.';
  }

  @override
  String get explainReply =>
      'Je antwoord betaalt de auteur van het bericht minstens de vergoeding (je mag meer geven als fooi), plus de vergoeding voor de miner.';

  @override
  String get explainTransfer =>
      'Een gewone overboeking van tokens zonder bericht. Het bedrag moet minstens de vergoeding zijn.';

  @override
  String get recipientAddress => 'Adres van de ontvanger';

  @override
  String get enterAddress => 'Geef een hexadecimaal adres van 64 tekens op';

  @override
  String get payToAuthor => 'Betalen aan auteur';

  @override
  String get wholeNumber => 'Geheel getal';

  @override
  String atLeastFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Minstens de vergoeding ($feeString)';
  }

  @override
  String get feeToMiner => 'Vergoeding (voor de miner)';

  @override
  String suggestedFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Voorgesteld: $feeString';
  }

  @override
  String get atLeastOne => 'Minstens 1';

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

    return 'Te lang: $countString bytes';
  }

  @override
  String get sendingNeedsLive =>
      'Versturen kan zodra de client verbonden en gesynchroniseerd is.';

  @override
  String get signAndSend => 'Ondertekenen en versturen';

  @override
  String get costFee => 'Vergoeding, voor de miner';

  @override
  String costBurn(int multiple) {
    return 'Verbrand: $multiple × de vergoeding';
  }

  @override
  String get costPaid => 'Betaald aan de ontvanger';

  @override
  String get costTotal => 'Totale kosten';

  @override
  String get costAvailable => 'Beschikbaar: saldo min openstaande transacties';

  @override
  String get costRemaining => 'Over na versturen';

  @override
  String get checkingFees => 'Netwerkvergoedingen opvragen…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Geschat op basis van wat deze client zag ($countString openstaand sinds het verbinden); het vergoedingsrapport van de node was niet beschikbaar.';
  }

  @override
  String get use => 'Gebruiken';

  @override
  String get checkAgain => 'Opnieuw opvragen';

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

    return 'Saldo: $beforeString ervoor, $afterString erna';
  }

  @override
  String chainCounted(int counted, int total) {
    final intl.NumberFormat countedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countedString = countedNumberFormat.format(counted);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$countedString van $totalString blokken geteld';
  }

  @override
  String get loadingOlder => 'Oudere blokken laden…';

  @override
  String get blockLoading => 'Dit blok wordt geladen…';

  @override
  String get txSearching =>
      'Deze transactie wordt gezocht in de blokken die nog laden…';

  @override
  String get storageBanner =>
      'Een kopie van de keten op dit apparaat bewaren? Latere bezoeken openen dan in seconden, in plaats van alles opnieuw te downloaden. Ze blijft hier en wordt nooit naar iemand gestuurd: geen cookies, geen tracking. Je walletsleutel en instellingen blijven altijd op dit apparaat, omdat de app ze nodig heeft.';

  @override
  String get storageAllow => 'Noodzakelijke opslag toestaan';

  @override
  String get storageReject => 'Weigeren (trager)';

  @override
  String get storageOn => 'Lokale kopie van de keten: aan';

  @override
  String get storageOff =>
      'Lokale kopie van de keten: uit (elk bezoek downloadt haar opnieuw)';

  @override
  String get storageTurnOn => 'Aanzetten';

  @override
  String get storageTurnOff => 'Uitzetten en wissen';

  @override
  String get checkingBalance => 'Controleren bij de node…';

  @override
  String get errTampered =>
      'De verbinding is gewijzigd of verbroken: een bericht kwam niet door de integriteitscontrole.';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'De toestand waaraan de node zich bij blok $heightString bindt, klopt niet met de eigen telling van deze client. Vertrouw deze node niet: maak verbinding met een andere.';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Volgens de node: $countString openstaande transacties.',
      one: 'Volgens de node: 1 openstaande transactie.',
      zero: 'Volgens de node: niets openstaand.',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => 'Geaccepteerd door de node en doorgestuurd.';

  @override
  String get statusRefused => 'Geweigerd door de node';

  @override
  String get statusInvalid => 'Afgewezen als ongeldig';

  @override
  String nodeReason(String reason) {
    return 'De node meldt: $reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'De keten leidt niet naar het checkpoint van deze versie bij blok $heightString: de versie of alle bereikte nodes zitten fout. Gestopt; niets ervan is te vertrouwen.';
  }

  @override
  String staleTip(String elapsed) {
    return 'Het nieuwste blok is van $elapsed: deze node loopt misschien achter of is van het netwerk afgesneden. Wat je ziet, is mogelijk verouderd.';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return 'Gestart vanaf het checkpoint bij blok $heightString; de headers tot aan genesis worden gecontroleerd ($doneString tot nu toe).';
  }

  @override
  String get licenses => 'Licenties';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => 'Testnet: tokens hebben geen waarde';

  @override
  String get linkNodeRepo => 'Broncode van node en protocol';

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

    return 'Blokheaders controleren: $doneString van $totalString';
  }

  @override
  String reconnectingIn(int seconds) {
    return 'Nieuwe poging over $seconds s.';
  }

  @override
  String get languagesFilter => 'Talen';

  @override
  String get languageUndetected => 'Niet herkend';

  @override
  String get hideFlaggedThreads => 'Draadjes verbergen die ik heb gemeld';

  @override
  String get star => 'Ster geven';

  @override
  String get unstar => 'Ster weghalen';

  @override
  String get starredOnly => 'Alleen draadjes met ster';

  @override
  String get localNodeRun => 'Een Murmur-node op deze computer draaien';

  @override
  String get localNodeExplain =>
      'Je computer controleert de keten zelf, helpt hem door te geven en houdt je eigen berichten beschikbaar. Berichten van anderen bewaart hij niet langer dan de controle van een uur.';

  @override
  String get localNodeStarting => 'De node start…';

  @override
  String get localNodeRunning => 'De node draait en de app gebruikt hem.';

  @override
  String localNodeFailed(String reason) {
    return 'De node is gestopt: $reason';
  }

  @override
  String get localNodeFailedUnknown => 'De node is onverwacht gestopt.';

  @override
  String get localNodeMine => 'Minen met deze computer';

  @override
  String get localNodeMineNote =>
      'Minen betaalt aan het adres van je wallet, verbruikt stroom en laat je computer harder werken. Op het testnet zijn tokens alleen om te testen.';

  @override
  String get localNodeMineNeedsWallet =>
      'Maak eerst een wallet: minen betaalt aan zijn adres.';

  @override
  String localNodeCpu(int pct) {
    return 'Tot $pct% van één processorkern';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count draadjes verborgen',
      one: '1 draadje verborgen',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => 'Geladen draadjes doorzoeken';

  @override
  String get noMatches => 'Geen geladen draadje komt overeen.';

  @override
  String get timeJustNow => 'zojuist';

  @override
  String timeMinutesAgo(int n) {
    return '$n min geleden';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n u geleden';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n d geleden';
  }

  @override
  String get nameAddress => 'Naam';

  @override
  String get aliasTitle => 'Dit adres een naam geven';

  @override
  String get aliasHelp =>
      'De naam blijft alleen op dit apparaat. Laat hem leeg om hem te verwijderen.';

  @override
  String get save => 'Opslaan';

  @override
  String get mute => 'Dempen';

  @override
  String get unmute => 'Niet meer dempen';

  @override
  String get mutedNote =>
      'Gedempt: de draadjes en antwoorden ervan zijn op dit apparaat verborgen.';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count antwoorden van gedempte adressen verborgen',
      one: '1 antwoord van een gedempt adres verborgen',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe antwoorden',
      one: '1 nieuw antwoord',
    );
    return '$_temp0';
  }

  @override
  String get invitations => 'Uitnodigingen';

  @override
  String get createInvitations => 'Uitnodigingen maken';

  @override
  String get inviteHowMany => 'Hoeveel kaarten';

  @override
  String get inviteFund => 'Kaarten financieren';

  @override
  String get inviteCardTitle => 'Uitnodiging voor Murmur';

  @override
  String inviteCardSerial(int n, int total) {
    return '$n van $total';
  }

  @override
  String inviteCardFrom(String name) {
    return 'Van $name';
  }

  @override
  String get inviteCardHow =>
      'Scan de code of open de link om lid te worden van Murmur.';

  @override
  String get inviteClaimed => 'Geïnd';

  @override
  String get inviteChecking => 'Controleren…';

  @override
  String get claimTitle => 'Je bent uitgenodigd';

  @override
  String claimInvitedBy(String name) {
    return 'Uitgenodigd door $name';
  }

  @override
  String claimHolds(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Deze uitnodiging bevat $amountString: genoeg voor je eerste draadjes.';
  }

  @override
  String get claimCreateWallet => 'Mijn wallet maken en innen';

  @override
  String get claimIntoWallet => 'In mijn wallet innen';

  @override
  String get claimDone =>
      'Geïnd. De tokens komen met het volgende blok in je wallet aan.';

  @override
  String get claimEmpty => 'Deze uitnodiging is al geïnd of teruggenomen.';

  @override
  String get claimWrongNetwork =>
      'Deze uitnodiging hoort bij een ander netwerk dan de node waarmee je verbonden bent.';

  @override
  String get claimInvalid => 'Dat is geen geldige uitnodigingscode.';

  @override
  String get haveInvitation => 'Ik heb een uitnodiging';

  @override
  String get inviteCodeField => 'Uitnodigingscode of link';

  @override
  String get claim => 'Innen';

  @override
  String get cancelInvitation => 'Uitnodiging annuleren';

  @override
  String get inviteCancelled => 'Geannuleerd';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uitnodigingen annuleren?',
      one: 'Deze uitnodiging annuleren?',
    );
    return '$_temp0';
  }

  @override
  String cancelInviteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'De tokens komen terug in je wallet, en wie de kaarten heeft kan ze niet meer innen.',
      one:
          'De tokens komen terug in je wallet, en wie de kaart heeft kan hem niet meer innen.',
    );
    return '$_temp0';
  }

  @override
  String get keepInvitation => 'Behouden';

  @override
  String get printOne => 'Afdrukken';

  @override
  String inviteDoneSection(int count) {
    return 'Geïnd of geannuleerd ($count)';
  }

  @override
  String get inviteEachLabel => 'Elke kaart';

  @override
  String get inviteEachCaption =>
      'Vijf draadjes tegen de vergoeding van vandaag, plus de vergoeding om hem te innen.';

  @override
  String get inviteTotalLabel => 'Je betaalt';

  @override
  String get inviteTotalCaption => 'In totaal, vergoedingen inbegrepen.';

  @override
  String get inviteWaitingState => 'Wacht op innen';

  @override
  String get inviteCardSlogan => 'Jouw stem heeft hier een plek.';

  @override
  String get inviteCardJoin => 'Scan om mee te doen';

  @override
  String get share => 'Delen…';

  @override
  String get inviteDetailFunded => 'Gefinancierd';

  @override
  String get inviteDetailClaimedBy => 'Geïnd door';

  @override
  String get inviteDetailReceived => 'Ontvangen';

  @override
  String get inviteDetailCancelled =>
      'Geannuleerd: de tokens zijn terug in je wallet';

  @override
  String get inviteDetailReturned => 'Teruggekregen';

  @override
  String get inviteDetailOnItsWay => 'Onderweg naar een blok';

  @override
  String get seedConfirmTitle => 'Je seed tonen?';

  @override
  String get seedConfirmBody =>
      'Wie de seed ziet, kan uit deze wallet uitgeven. Zorg dat niemand anders je scherm ziet.';

  @override
  String get showAction => 'Tonen';

  @override
  String get authReasonSeed => 'Bevestig dat jij het bent om de seed te zien';

  @override
  String get authReasonRemove =>
      'Bevestig dat jij het bent om deze wallet te verwijderen';

  @override
  String get authFailed => 'Niet bevestigd: er is niets getoond of gewijzigd.';

  @override
  String get passphraseNewTitle => 'Kies een wachtzin';

  @override
  String get passphraseNewBody =>
      'Die versleutelt de sleutel van je wallet op dit apparaat. Je typt hem om te versturen, de seed te tonen of de wallet te verwijderen. Vergeet je hem, dan kan alleen je seed-back-up de wallet terugbrengen.';

  @override
  String get passphraseField => 'Wachtzin';

  @override
  String get passphraseRepeat => 'Herhaal de wachtzin';

  @override
  String passphraseTooShort(int min) {
    return 'Minstens $min tekens';
  }

  @override
  String get passphraseMismatch => 'Ze komen niet overeen';

  @override
  String get passphraseTitle => 'Wachtzin';

  @override
  String get wrongPassphrase =>
      'Verkeerde wachtzin: er is niets getoond of verstuurd.';

  @override
  String get unlock => 'Ontgrendelen';

  @override
  String get authReasonSend =>
      'Bevestig dat jij het bent om te ondertekenen en te versturen';

  @override
  String get authReasonNewWallet =>
      'Bescherm de sleutel van je wallet op dit apparaat';

  @override
  String get authReasonInvite =>
      'Bevestig dat jij het bent om de kaarten te financieren';

  @override
  String get removeAnywayTitle => 'Verwijderen zonder bevestiging?';

  @override
  String get removeAnywayBody =>
      'De wallet kon niet worden ontgrendeld. Verwijderen wist de sleutel van dit apparaat: alleen je seed-back-up kan hem terugbrengen.';

  @override
  String get protectionDevice =>
      'Sleutel versleuteld met de vergrendeling van dit apparaat';

  @override
  String get protectionPasskey =>
      'Sleutel versleuteld met een passkey op dit apparaat';

  @override
  String get protectionPassphrase => 'Sleutel versleuteld met je wachtzin';

  @override
  String get protectionLegacy =>
      'Sleutel nog niet versleuteld: dat gebeurt bij de volgende ontgrendeling';

  @override
  String get confirmSendTitle => 'Controleer voor het ondertekenen';

  @override
  String get confirmSendFinal =>
      'Ondertekenen stuurt dit naar de node. Het kan niet worden teruggedraaid: eenmaal gemined blijft het in de keten.';

  @override
  String signAndSendShortcut(String keys) {
    return 'Ondertekenen en versturen ($keys)';
  }

  @override
  String get threadWithdrawnMine =>
      'Door jou ingetrokken: verborgen voor anderen, en de tekst gewist uit Murmur-apps';

  @override
  String get threadWithdrawnMineNote =>
      'Je hebt je eigen draadje gemeld en het daarmee ingetrokken. Murmur-apps tonen het niet meer aan anderen en wissen de tekst, ook op dit apparaat; nodes kunnen stoppen met het bewaren van de tekst en de antwoorden.';

  @override
  String get threadWithdrawnNote =>
      'De auteur heeft dit draadje gemeld en het daarmee ingetrokken. Murmur-apps tonen het niet meer in de lijst en wissen de tekst, en nodes kunnen stoppen met het bewaren van de tekst en de antwoorden.';

  @override
  String get flagOwnInfo =>
      'Dit is je eigen bericht. Melden trekt het in: Murmur-apps tonen het niet meer aan anderen en wissen de tekst, ook op dit apparaat, en nodes kunnen stoppen met het bewaren van de tekst en de antwoorden. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get inviteFromTitle => 'Naam op de kaarten';

  @override
  String get inviteFromBody =>
      'Elke kaart zegt van wie hij is. De kaarten zijn gefinancierd door de uitnodigende wallet, die nu misschien niet meer die op dit apparaat is.';

  @override
  String get inviteFromOriginal => 'Adres van de uitnodigende wallet';

  @override
  String get inviteFromOriginalAlias => 'Jouw naam voor de uitnodigende wallet';

  @override
  String get inviteFromOriginalPublic =>
      'Openbare naam van de uitnodigende wallet';

  @override
  String get inviteFromCurrent => 'Adres van deze wallet';

  @override
  String get inviteFromCurrentAlias => 'Jouw naam voor deze wallet';

  @override
  String get inviteFromCurrentPublic => 'Openbare naam van deze wallet';

  @override
  String get inviteFromCustom => 'Andere tekst';

  @override
  String get inviteFromCustomHint => 'Laat leeg om geen naam af te drukken';

  @override
  String get inviteFromNotSet => 'Geen naam gegeven op dit apparaat';

  @override
  String get inviteFromMixed => 'Verschilt tussen de gekozen kaarten';

  @override
  String get inviteFromChecking => 'Wordt nog opgezocht in de keten';

  @override
  String get cancelReturnTo => 'Tokens sturen naar';

  @override
  String get cancelToFunder => 'De wallet die hem financierde';

  @override
  String get cancelToCurrent => 'Deze wallet';

  @override
  String get publicName => 'Openbare naam';

  @override
  String get publicNameNone => 'Geen bekend';

  @override
  String get publicNameSet => 'Openbare naam instellen';

  @override
  String get publicNameField => 'Naam';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return 'Hoogstens $maxString bytes';
  }

  @override
  String get aliasBadCharacter =>
      'Onzichtbare of stuurtekens zijn niet toegestaan';

  @override
  String get aliasEdgeSpace => 'Geen spaties aan het begin of eind';

  @override
  String aliasSetTo(String name) {
    return 'Openbare naam: $name';
  }

  @override
  String get aliasCleared => 'Openbare naam gewist';

  @override
  String get nonTextMessage => '(geen tekst: gegevens voor een app-conventie)';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return 'Publiceert je openbare naam. Net als een nieuw draadje kost dat $totalString × de fee: de fee gaat naar de miner en $burnString × de fee wordt verbrand.';
  }

  @override
  String get inviteFromNoPublic => 'Geen openbare naam bekend';

  @override
  String get starredTitle => 'Met ster';

  @override
  String get noStarred =>
      'Nog niets met een ster. Geef een draadje of bericht een ster op de eigen pagina, dan verschijnt het hier.';

  @override
  String get starredGone => 'Niet meer in de keten';

  @override
  String get feeSuggestedLabel => 'Voorgestelde fee';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return 'voor $weightString bytes';
  }

  @override
  String get feeRoom => 'Blokken hebben ruimte';

  @override
  String get feeFull => 'Blokken zijn vol';

  @override
  String get feeNextBlock => 'Volgend blok';

  @override
  String get feePoolEntry => 'Om in de pool te komen';

  @override
  String get feeMinimum => 'Minimum';

  @override
  String get feeWhy => 'Waarom deze fee';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**De fee is per byte**: $baseString bytes plus je bericht. Lange berichten kosten meer als blokken vol zijn.';
  }

  @override
  String feeRecentPoint(int lowest, int median) {
    final intl.NumberFormat lowestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lowestString = lowestNumberFormat.format(lowest);
    final intl.NumberFormat medianNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String medianString = medianNumberFormat.format(median);

    return '**Recente blokken** namen fees vanaf **$lowestString** (mediaan $medianString).';
  }

  @override
  String get feeRecentNonePoint =>
      '**Recente blokken** hadden geen transacties.';

  @override
  String get inviteNoExpiryPoint =>
      '**Verloopt niet**: een kaart werkt tot iemand hem claimt.';

  @override
  String get inviteCancelPoint =>
      '**Altijd te annuleren**: de tokens komen terug.';

  @override
  String get invitePublicPoint =>
      '**Openbaar**: de keten laat zien dat jij elke kaart financierde en welke wallet hem claimde.';

  @override
  String get inviteCashPoint =>
      '**Wie de code heeft**, kan de kaart claimen. Houd kaarten privé tot je ze overhandigt.';

  @override
  String get inviteLocalPoint =>
      '**Alleen op dit apparaat bewaard.** Worden de gegevens gewist of de app verwijderd, dan zijn de codes **voorgoed kwijt**, en ook de tokens op kaarten die nog niet zijn overhandigd.';

  @override
  String get publicNameIntro =>
      'Je openbare naam staat **naast je adres** in Murmur-apps.';

  @override
  String publicNameShownAs(String name) {
    return 'Verschijnt als **$name**';
  }

  @override
  String get publicNameNotUnique =>
      '**Niet uniek**: iedereen kan dezelfde naam kiezen. Het adres ernaast onderscheidt mensen.';

  @override
  String get publicNameCost =>
      '**Kost evenveel als een nieuw draadje**, elke keer dat je hem instelt of wijzigt.';

  @override
  String get publicNameRemovable =>
      '**Een bericht in de keten**: elke node mag het wissen, en dan is het weg.';

  @override
  String get publicNameClear => '**Laat leeg** om hem te wissen.';

  @override
  String get passkeyNoPrfTitle =>
      'Deze passkeybeheerder kan de wallet niet beschermen';

  @override
  String get passkeyNoPrfWhy =>
      '**Hij kan niet versleutelen.** Om je walletsleutel te vergrendelen, moet de beheerder een sleutel uit de passkey afleiden (WebAuthn PRF). Die je koos doet dat niet.';

  @override
  String get passkeyNoPrfTry =>
      '**Probeer een andere beheerder**, zoals Apple Wachtwoorden of Google Wachtwoordmanager, of bescherm de wallet met een **wachtzin**.';

  @override
  String get passkeyNoPrfLeftover =>
      'De passkey die hij net bewaarde (**Murmur wallet**) ontgrendelt niets: je kunt hem uit die beheerder verwijderen.';

  @override
  String get passkeyTryAnother => 'Andere passkeybeheerder proberen';

  @override
  String get passkeyUsePassphrase => 'Een wachtzin gebruiken';
}
