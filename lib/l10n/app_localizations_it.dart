// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => 'Discussione';

  @override
  String get kindReply => 'Risposta';

  @override
  String get kindTransfer => 'Trasferimento';

  @override
  String get kindFlag => 'Segnalazione';

  @override
  String get contentUnavailable =>
      '(contenuto non disponibile: il nodo non ce l\'ha)';

  @override
  String get contentWithdrawn => '(ritirato dall\'autore)';

  @override
  String get contentLoading => '(caricamento del messaggio…)';

  @override
  String get pending => 'in attesa';

  @override
  String get copy => 'Copia';

  @override
  String get copied => 'Copiato';

  @override
  String replyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString risposte',
      one: '1 risposta',
      zero: 'Nessuna risposta',
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
      other: '$countString segnalazioni',
      one: '1 segnalazione',
      zero: 'Nessuna segnalazione',
    );
    return '$_temp0';
  }

  @override
  String transferOf(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Trasferimento di $amountString';
  }

  @override
  String flagOn(String text) {
    return 'Segnalazione di «$text»';
  }

  @override
  String flagOnTx(String txid) {
    return 'Segnalazione di $txid';
  }

  @override
  String get replyNotThreaded => 'Risposta (fuori da una discussione)';

  @override
  String routeFrom(String address) {
    return 'da $address';
  }

  @override
  String routeFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String errUnreachable(String detail) {
    return 'Impossibile raggiungere il nodo: $detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return 'Impossibile raggiungere il bridge WebSocket su $url. Avvialo con: dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return 'Errore di connessione: $detail';
  }

  @override
  String get errClosed => 'Il nodo ha chiuso la connessione.';

  @override
  String get errTimeout => 'Il nodo non ha risposto in tempo.';

  @override
  String errProtocol(String detail) {
    return 'Errore di protocollo: $detail';
  }

  @override
  String errVersion(int node, int ours) {
    return 'Il nodo usa il protocollo $node; questo client usa il protocollo $ours.';
  }

  @override
  String errSyncFailed(String cause) {
    return 'Sincronizzazione non riuscita: $cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return 'Ignorato un blocco inoltrato: $detail';
  }

  @override
  String get probFeeTooLow => 'La commissione deve essere almeno 1.';

  @override
  String get probMalformed => 'Questa transazione non è ben formata.';

  @override
  String get probNeedsMessage => 'Scrivi un messaggio.';

  @override
  String get probNeedsRecipient => 'Indica un destinatario.';

  @override
  String probAmountBelowFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'L\'importo deve essere almeno pari alla commissione ($feeString).';
  }

  @override
  String get probReplyParentNotMined =>
      'Puoi rispondere solo a una discussione o risposta già inclusa in un blocco.';

  @override
  String get probReplyWrongRecipient =>
      'Una risposta deve pagare l\'autore del messaggio a cui risponde.';

  @override
  String get probFlagNotMessage =>
      'Si possono segnalare solo discussioni e risposte.';

  @override
  String get probAlreadyFlagged =>
      'Questo portafoglio ha già segnalato quel messaggio.';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Il messaggio è di $lengthString byte; il limite è $limitString.';
  }

  @override
  String probInsufficientBalance(int needed, int available) {
    final intl.NumberFormat neededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String neededString = neededNumberFormat.format(needed);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return 'Saldo insufficiente: servono $neededString, disponibili $availableString (saldo confermato meno le transazioni in attesa).';
  }

  @override
  String get probNotLive =>
      'Attendi che il client sia connesso e sincronizzato.';

  @override
  String get probConnectionLost => 'Connessione al nodo persa.';

  @override
  String get probDuplicate =>
      'Una transazione identica è già stata inviata in questo stesso secondo.';

  @override
  String get tabThreads => 'Discussioni';

  @override
  String get tabMessages => 'Messaggi';

  @override
  String get tabWallet => 'Portafoglio';

  @override
  String get tabChain => 'Catena';

  @override
  String get newThread => 'Nuova discussione';

  @override
  String get createWalletFirst => 'Prima crea o importa un portafoglio.';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String get reconnect => 'Riconnetti';

  @override
  String get changeNode => 'Cambia nodo';

  @override
  String get unknownNetwork =>
      'Questo nodo è su una rete che il client non riconosce. Non è possibile verificarne gli aggiustamenti di difficoltà, e le ricompense dei blocchi sono calcolate con i valori del whitepaper, quindi i saldi dei miner potrebbero non essere esatti.';

  @override
  String get linkOffline => 'Offline';

  @override
  String get linkConnecting => 'Connessione…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return 'Sincronizzazione $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'In diretta · $heightString';
  }

  @override
  String get connectToNode => 'Connetti a un nodo';

  @override
  String nodeAt(String address) {
    return 'Nodo $address';
  }

  @override
  String get language => 'Lingua';

  @override
  String get systemLanguage => 'Lingua del sistema';

  @override
  String get lightMode => 'Tema chiaro';

  @override
  String get darkMode => 'Tema scuro';

  @override
  String get node => 'Nodo';

  @override
  String get connectHelpBridge =>
      'Nel browser, il client si collega via WebSocket: all\'indirizzo WebSocket di un nodo (come node.murmur.info, porta 443, con TLS) o a un bridge locale (dart run tool/ws_bridge.dart, porta 7880).';

  @override
  String get connectHelpNative =>
      'L\'indirizzo peer-to-peer di un murmur-node (la sua --port, 7878 di default). La porta di controllo (7879) non funziona.';

  @override
  String get host => 'Host';

  @override
  String get port => 'Porta';

  @override
  String get required => 'Obbligatorio';

  @override
  String get enterPort => 'Inserisci un numero di porta';

  @override
  String get disconnect => 'Disconnetti';

  @override
  String get cancel => 'Annulla';

  @override
  String get connect => 'Connetti';

  @override
  String get syncingChain => 'Sincronizzazione della catena…';

  @override
  String get noThreads =>
      'Ancora nessuna discussione. Iniziane una con Nuova discussione.';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Al blocco $heightString ($time, $elapsed)';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString nuovi blocchi da allora',
      one: '1 nuovo blocco da allora',
      zero: 'aggiornato',
    );
    return '$_temp0';
  }

  @override
  String agoSeconds(int s) {
    return '$s s fa';
  }

  @override
  String agoMinutes(int m, int s) {
    return '$m min $s s fa';
  }

  @override
  String agoHours(int h, int m) {
    return '$h h $m min fa';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return '$dString g $h h fa';
  }

  @override
  String get refresh => 'Aggiorna';

  @override
  String threadStarted(String time) {
    return 'iniziata $time';
  }

  @override
  String threadLastReply(String time) {
    return 'ultima risposta $time';
  }

  @override
  String get messagesNeedWallet =>
      'Crea o importa un portafoglio nella scheda Portafoglio per vedere i tuoi messaggi.';

  @override
  String get noMessages => 'Nessun messaggio corrisponde a questi filtri.';

  @override
  String get filterThreads => 'Le mie discussioni';

  @override
  String get filterRepliesSent => 'Risposte inviate';

  @override
  String get filterRepliesReceived => 'Risposte ricevute';

  @override
  String get filterFlagsSent => 'Segnalazioni fatte';

  @override
  String get filterFlagsReceived => 'Segnalazioni ricevute';

  @override
  String get balance => 'Saldo';

  @override
  String pendingCommitted(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString impegnati in transazioni in attesa';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString blocchi minati',
      one: '1 blocco minato',
      zero: 'Nessun blocco minato',
    );
    return '$_temp0';
  }

  @override
  String get address => 'Indirizzo';

  @override
  String get showSeed => 'Mostra seed';

  @override
  String get removeWallet => 'Rimuovi portafoglio';

  @override
  String get history => 'Cronologia';

  @override
  String get filters => 'Filtri';

  @override
  String get noHistory => 'Nessuna transazione corrisponde a questi filtri.';

  @override
  String get walletFilterTransfersSent => 'Trasferimenti inviati';

  @override
  String get walletFilterTransfersReceived => 'Trasferimenti ricevuti';

  @override
  String get walletFilterRepliesPaid => 'Pagato per rispondere';

  @override
  String get walletFilterRepliesEarned => 'Guadagnato dalle risposte';

  @override
  String get walletFilterThreadCosts => 'Costi delle discussioni';

  @override
  String get walletFilterFlagCosts => 'Commissioni delle segnalazioni';

  @override
  String get seedTitle => 'Seed del portafoglio';

  @override
  String get seedWarning =>
      'Chiunque abbia questo seed può spendere da questo portafoglio. Ha lo stesso formato di un file di chiave creato con murmur-node keygen.';

  @override
  String get done => 'Fatto';

  @override
  String get removeWalletTitle => 'Rimuovere il portafoglio?';

  @override
  String get removeWalletBody =>
      'Il seed verrà cancellato da questo dispositivo. Senza una copia, qualsiasi saldo su questo indirizzo andrà perso.';

  @override
  String get remove => 'Rimuovi';

  @override
  String get importWallet => 'Importa portafoglio';

  @override
  String get importHelp =>
      'Incolla un seed esadecimale di 64 caratteri, ad esempio il contenuto di un file di chiave creato con murmur-node keygen (murmur.key), per usare le ricompense minate al suo indirizzo.';

  @override
  String get seed => 'Seed';

  @override
  String get import => 'Importa';

  @override
  String get seedInvalid =>
      'Un seed è lungo esattamente 64 caratteri esadecimali.';

  @override
  String get walletIntro =>
      'Un portafoglio firma le transazioni che invii. La sua chiave resta su questo dispositivo.';

  @override
  String get createWallet => 'Crea nuovo portafoglio';

  @override
  String get importSeed => 'Importa seed';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return 'Nessun blocco all\'altezza $heightString (la punta è $tipString).';
  }

  @override
  String get searchInvalid =>
      'Inserisci un\'altezza di blocco, oppure un txid, hash di blocco o indirizzo di 64 caratteri.';

  @override
  String get searchHint => 'Cerca altezza, txid, hash di blocco o indirizzo';

  @override
  String get noBlocks => 'Ancora nessun blocco.';

  @override
  String blockTitle(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Blocco $heightString';
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
  String get statNetwork => 'Rete';

  @override
  String get statHeight => 'Altezza';

  @override
  String get statNodeHeight => 'Altezza del nodo';

  @override
  String get statNextReward => 'Ricompensa del prossimo blocco';

  @override
  String rewardPlusFees(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString + commissioni';
  }

  @override
  String get statBurnPool => 'Fondo bruciato';

  @override
  String get statCirculating => 'In circolazione';

  @override
  String get tip => 'Punta';

  @override
  String get previousBlock => 'Blocco precedente';

  @override
  String get nextBlock => 'Blocco successivo';

  @override
  String get blockGone => 'Questo blocco non è più sulla catena migliore.';

  @override
  String get hash => 'Hash';

  @override
  String get previous => 'Precedente';

  @override
  String get time => 'Ora';

  @override
  String get confirmations => 'Conferme';

  @override
  String get miner => 'Miner';

  @override
  String get reward => 'Ricompensa';

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

    return '$subsidyString di sussidio + $payoutString dal fondo bruciato + $feesString di commissioni';
  }

  @override
  String get merkleRoot => 'Radice di Merkle';

  @override
  String get target => 'Obiettivo';

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
      other: '$countString transazioni',
      one: '1 transazione',
      zero: 'Nessuna transazione',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => 'Il tuo indirizzo';

  @override
  String get noTransactions => 'Nessuna transazione.';

  @override
  String get sendToAddress => 'Invia a questo indirizzo';

  @override
  String get threadGone => 'Questa discussione non è più sulla catena.';

  @override
  String paidToParent(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'ha pagato $amountString all\'autore del messaggio originale';
  }

  @override
  String get actionReply => 'Rispondi';

  @override
  String get actionFlag => 'Segnala';

  @override
  String get flagged => 'Segnalato';

  @override
  String get details => 'Dettagli';

  @override
  String get txTitle => 'Transazione';

  @override
  String get txNotFound =>
      'Transazione non trovata. Potrebbe essere stata scartata da quelle in attesa o rimossa da una riorganizzazione.';

  @override
  String refNotLocal(String txid) {
    return 'Transazione $txid (non è sulla catena locale)';
  }

  @override
  String get flaggedMessage => 'Messaggio segnalato';

  @override
  String get inReplyTo => 'In risposta a';

  @override
  String get notThreadedExplain =>
      'Indica questo messaggio, ma non fa parte della sua discussione: il messaggio deve essere una discussione o risposta minata, e questa risposta deve pagarne l\'autore. Conta solo come pagamento.';

  @override
  String get message => 'Messaggio';

  @override
  String get openThread => 'Apri discussione';

  @override
  String get transactionId => 'ID transazione';

  @override
  String get type => 'Tipo';

  @override
  String get from => 'Da';

  @override
  String get to => 'A';

  @override
  String get burned => 'Bruciato';

  @override
  String burnedValue(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString (restituito ai miner tramite il fondo bruciato)';
  }

  @override
  String get amount => 'Importo';

  @override
  String get fee => 'Commissione';

  @override
  String get signedAt => 'Firmata il';

  @override
  String get contentHash => 'Hash del contenuto';

  @override
  String get contentSize => 'Dimensione del contenuto';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString byte (un sale di $salt byte e un messaggio di $messageString byte)';
  }

  @override
  String get reports => 'Segnala';

  @override
  String get repliesTo => 'Risponde a';

  @override
  String get weight => 'Peso';

  @override
  String weightValue(int weight, String perByte) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString byte ($perByte di commissione per byte)';
  }

  @override
  String get publicKey => 'Chiave pubblica';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Confermata nel blocco $heightString';
  }

  @override
  String confirmationCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString conferme',
      one: '1 conferma',
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
      other: 'Non confermata dopo $countString blocchi',
      one: 'Non confermata dopo 1 blocco',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused =>
      'Il nodo potrebbe averla rifiutata (ad esempio, se il saldo è cambiato prima che fosse minata). Il nodo non avvisa delle transazioni rifiutate.';

  @override
  String get sentWaiting => 'Inviata, in attesa di un blocco';

  @override
  String get submittedHere => 'Inviata da questo dispositivo.';

  @override
  String get pendingTitle => 'In attesa';

  @override
  String get relayedPending => 'Inoltrata dal nodo, non ancora in un blocco.';

  @override
  String get viewBlock => 'Vedi blocco';

  @override
  String get newTransaction => 'Nuova transazione';

  @override
  String get flagMessage => 'Segnala messaggio';

  @override
  String flaggingInfo(String author) {
    return 'Stai segnalando questo messaggio di $author. Ogni portafoglio può segnalare un messaggio una sola volta. Ogni client decide cosa fare delle segnalazioni.';
  }

  @override
  String replyingTo(String author) {
    return 'Risposta a $author';
  }

  @override
  String explainThread(int total, int burn) {
    return 'Avvia una nuova discussione. Costa $total × la commissione: la commissione va al miner e $burn × la commissione viene bruciato. I token bruciati tornano ai miner nei blocchi successivi.';
  }

  @override
  String get explainReply =>
      'La tua risposta paga all\'autore del messaggio almeno la commissione (puoi lasciare di più come mancia), più la commissione al miner.';

  @override
  String get explainTransfer =>
      'Un semplice trasferimento di token senza messaggio. L\'importo deve essere almeno pari alla commissione.';

  @override
  String get recipientAddress => 'Indirizzo del destinatario';

  @override
  String get enterAddress =>
      'Inserisci un indirizzo esadecimale di 64 caratteri';

  @override
  String get payToAuthor => 'Paga all\'autore';

  @override
  String get wholeNumber => 'Numero intero';

  @override
  String atLeastFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Almeno la commissione ($feeString)';
  }

  @override
  String get feeToMiner => 'Commissione (al miner)';

  @override
  String suggestedFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Consigliata: $feeString';
  }

  @override
  String get atLeastOne => 'Almeno 1';

  @override
  String bytesOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString byte';
  }

  @override
  String tooLong(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Troppo lungo: $countString byte';
  }

  @override
  String get sendingNeedsLive =>
      'Potrai inviare quando il client sarà connesso e sincronizzato.';

  @override
  String get signAndSend => 'Firma e invia';

  @override
  String get costFee => 'Commissione, al miner';

  @override
  String costBurn(int multiple) {
    return 'Bruciato: $multiple × la commissione';
  }

  @override
  String get costPaid => 'Pagato al destinatario';

  @override
  String get costTotal => 'Costo totale';

  @override
  String get costAvailable => 'Disponibile: saldo meno transazioni in attesa';

  @override
  String get costRemaining => 'Rimanente dopo l\'invio';

  @override
  String get checkingFees => 'Controllo delle commissioni di rete…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Stima basata su ciò che ha visto questo client ($countString in attesa da quando si è connesso); il resoconto delle commissioni del nodo non era disponibile.';
  }

  @override
  String get use => 'Usa';

  @override
  String get checkAgain => 'Controlla di nuovo';

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

    return 'Saldo: $beforeString prima, $afterString dopo';
  }

  @override
  String chainCounted(int counted, int total) {
    final intl.NumberFormat countedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countedString = countedNumberFormat.format(counted);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$countedString di $totalString blocchi contati';
  }

  @override
  String get loadingOlder => 'Caricamento dei blocchi precedenti…';

  @override
  String get blockLoading => 'Caricamento del blocco…';

  @override
  String get txSearching =>
      'Ricerca della transazione nei blocchi ancora in caricamento…';

  @override
  String get storageBanner =>
      'Conservare una copia della catena su questo dispositivo? Le visite successive si apriranno in pochi secondi invece di riscaricare tutto. Resta qui e non viene mai inviata a nessuno: niente cookie né tracciamento. La chiave del portafoglio e le impostazioni restano sempre su questo dispositivo, perché servono all\'app per funzionare.';

  @override
  String get storageAllow => 'Consenti l\'archiviazione necessaria';

  @override
  String get storageReject => 'Rifiuta (più lento)';

  @override
  String get storageOn => 'Copia locale della catena: attiva';

  @override
  String get storageOff =>
      'Copia locale della catena: disattivata (ogni visita la riscarica)';

  @override
  String get storageTurnOn => 'Attiva';

  @override
  String get storageTurnOff => 'Disattiva ed elimina';

  @override
  String get checkingBalance => 'Verifica con il nodo…';

  @override
  String get errTampered =>
      'La connessione è stata alterata o interrotta: un messaggio non ha superato il controllo d\'integrità.';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Lo stato impegnato dal nodo al blocco $heightString non corrisponde al conteggio della catena di questo client. Non fidarti di questo nodo: connettiti a un altro.';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dal nodo: $countString transazioni in attesa.',
      one: 'Dal nodo: 1 transazione in attesa.',
      zero: 'Dal nodo: nulla in attesa.',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => 'Accettata dal nodo e inoltrata.';

  @override
  String get statusRefused => 'Rifiutata dal nodo';

  @override
  String get statusInvalid => 'Respinta perché non valida';

  @override
  String nodeReason(String reason) {
    return 'Il nodo dice: $reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'La catena non porta al checkpoint di questa versione al blocco $heightString: o la versione o tutti i nodi raggiunti sono in errore. Interrotto; non ci si può fidare di nulla.';
  }

  @override
  String staleTip(String elapsed) {
    return 'Il blocco più recente è di $elapsed: questo nodo potrebbe essere indietro o isolato dalla rete. Ciò che vedi potrebbe non essere aggiornato.';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return 'Avviato dal checkpoint al blocco $heightString; verifica delle intestazioni fino alla genesi ($doneString finora).';
  }

  @override
  String get licenses => 'Licenze';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => 'Testnet: i token non hanno valore';

  @override
  String get linkNodeRepo => 'Codice del nodo e del protocollo';

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

    return 'Verifica delle intestazioni dei blocchi: $doneString di $totalString';
  }

  @override
  String reconnectingIn(int seconds) {
    return 'Nuovo tentativo tra $seconds s.';
  }

  @override
  String get languagesFilter => 'Lingue';

  @override
  String get languageUndetected => 'Non rilevata';

  @override
  String get hideFlaggedThreads => 'Nascondi le discussioni che ho segnalato';

  @override
  String get star => 'Aggiungi stella';

  @override
  String get unstar => 'Togli stella';

  @override
  String get starredOnly => 'Solo discussioni con stella';

  @override
  String get localNodeRun => 'Esegui un nodo Murmur su questo computer';

  @override
  String get localNodeExplain =>
      'Il tuo computer verifica da sé la catena, aiuta a diffonderla e mantiene disponibili i tuoi messaggi. Non conserva i messaggi di nessun altro oltre la verifica di un\'ora.';

  @override
  String get localNodeStarting => 'Avvio del nodo…';

  @override
  String get localNodeRunning => 'Il nodo è in funzione e l\'app lo usa.';

  @override
  String localNodeFailed(String reason) {
    return 'Il nodo si è fermato: $reason';
  }

  @override
  String get localNodeFailedUnknown =>
      'Il nodo si è fermato in modo imprevisto.';

  @override
  String get localNodeMine => 'Mina con questo computer';

  @override
  String get localNodeMineNote =>
      'Il mining paga l\'indirizzo del tuo portafoglio, consuma elettricità e fa lavorare di più il computer. Sulla testnet i token servono solo per i test.';

  @override
  String get localNodeMineNeedsWallet =>
      'Crea prima un portafoglio: il mining paga il suo indirizzo.';

  @override
  String localNodeCpu(int pct) {
    return 'Fino al $pct% di un core del processore';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count discussioni nascoste',
      one: '1 discussione nascosta',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => 'Cerca nelle discussioni caricate';

  @override
  String get noMatches => 'Nessuna discussione caricata corrisponde.';

  @override
  String get timeJustNow => 'adesso';

  @override
  String timeMinutesAgo(int n) {
    return '$n min fa';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n h fa';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n g fa';
  }

  @override
  String get nameAddress => 'Nome';

  @override
  String get aliasTitle => 'Dai un nome a questo indirizzo';

  @override
  String get aliasHelp =>
      'Il nome resta solo su questo dispositivo. Lascialo vuoto per toglierlo.';

  @override
  String get save => 'Salva';

  @override
  String get mute => 'Silenzia';

  @override
  String get unmute => 'Riattiva';

  @override
  String get mutedNote =>
      'Silenziato: le sue discussioni e risposte sono nascoste su questo dispositivo.';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risposte da indirizzi silenziati nascoste',
      one: '1 risposta da un indirizzo silenziato nascosta',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuove risposte',
      one: '1 nuova risposta',
    );
    return '$_temp0';
  }

  @override
  String get invitations => 'Inviti';

  @override
  String get createInvitations => 'Crea inviti';

  @override
  String get inviteHowMany => 'Quante tessere';

  @override
  String get inviteFund => 'Finanzia le tessere';

  @override
  String get inviteCardTitle => 'Invito a Murmur';

  @override
  String inviteCardSerial(int n, int total) {
    return '$n di $total';
  }

  @override
  String inviteCardFrom(String name) {
    return 'Da $name';
  }

  @override
  String get inviteCardHow =>
      'Scansiona il codice o apri il link per entrare in Murmur.';

  @override
  String get inviteClaimed => 'Riscattato';

  @override
  String get inviteChecking => 'Verifica…';

  @override
  String get claimTitle => 'Sei stato invitato';

  @override
  String claimInvitedBy(String name) {
    return 'Invito da $name';
  }

  @override
  String claimHolds(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Questo invito contiene $amountString: abbastanza per le tue prime discussioni.';
  }

  @override
  String get claimCreateWallet => 'Crea il mio portafoglio e riscatta';

  @override
  String get claimIntoWallet => 'Riscatta nel mio portafoglio';

  @override
  String get claimDone =>
      'Riscattato. I token arrivano nel tuo portafoglio con il prossimo blocco.';

  @override
  String get claimEmpty => 'Questo invito è già stato riscattato o ripreso.';

  @override
  String get claimWrongNetwork =>
      'Questo invito è per un\'altra rete rispetto al nodo a cui sei collegato.';

  @override
  String get claimInvalid => 'Questo non è un codice di invito valido.';

  @override
  String get haveInvitation => 'Ho un invito';

  @override
  String get inviteCodeField => 'Codice o link dell\'invito';

  @override
  String get claim => 'Riscatta';

  @override
  String get cancelInvitation => 'Annulla invito';

  @override
  String get inviteCancelled => 'Annullato';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Annullare $count inviti?',
      one: 'Annullare questo invito?',
    );
    return '$_temp0';
  }

  @override
  String get cancelInviteBody =>
      'I suoi token tornano nel tuo portafoglio, e chi ha la tessera non potrà più riscattarla.';

  @override
  String get keepInvitation => 'Tienilo';

  @override
  String get printOne => 'Stampa';

  @override
  String inviteDoneSection(int count) {
    return 'Riscattati o annullati ($count)';
  }

  @override
  String get inviteEachLabel => 'Ogni tessera';

  @override
  String get inviteEachCaption =>
      'Cinque discussioni alla commissione di oggi, più la commissione per riscattarla.';

  @override
  String get inviteTotalLabel => 'Paghi';

  @override
  String get inviteTotalCaption => 'In tutto, commissioni incluse.';

  @override
  String get inviteWaitingState => 'In attesa di riscatto';

  @override
  String get inviteCardSlogan => 'Qui la tua voce ha un posto.';

  @override
  String get inviteCardJoin => 'Scansiona per entrare';

  @override
  String get share => 'Condividi…';

  @override
  String get inviteDetailFunded => 'Finanziato';

  @override
  String get inviteDetailClaimedBy => 'Riscattato da';

  @override
  String get inviteDetailReceived => 'Ricevuto';

  @override
  String get inviteDetailCancelled =>
      'Annullato: i token sono tornati nel tuo portafoglio';

  @override
  String get inviteDetailReturned => 'Restituito';

  @override
  String get inviteDetailOnItsWay => 'In arrivo in un blocco';

  @override
  String get seedConfirmTitle => 'Mostrare il seed?';

  @override
  String get seedConfirmBody =>
      'Chiunque veda il seed può spendere da questo portafoglio. Assicurati che nessun altro veda lo schermo.';

  @override
  String get showAction => 'Mostra';

  @override
  String get authReasonSeed => 'Conferma che sei tu per vedere il seed';

  @override
  String get authReasonRemove =>
      'Conferma che sei tu per rimuovere questo portafoglio';

  @override
  String get authFailed =>
      'Non confermato: non è stato mostrato né cambiato nulla.';

  @override
  String get passphraseNewTitle => 'Scegli una passphrase';

  @override
  String get passphraseNewBody =>
      'Cifra la chiave del portafoglio su questo dispositivo. La scriverai per inviare, mostrare il seed o rimuovere il portafoglio. Se la dimentichi, solo la copia del seed potrà recuperare il portafoglio.';

  @override
  String get passphraseField => 'Passphrase';

  @override
  String get passphraseRepeat => 'Ripeti la passphrase';

  @override
  String passphraseTooShort(int min) {
    return 'Almeno $min caratteri';
  }

  @override
  String get passphraseMismatch => 'Non coincidono';

  @override
  String get passphraseTitle => 'Passphrase';

  @override
  String get wrongPassphrase =>
      'Passphrase errata: non è stato mostrato né inviato nulla.';

  @override
  String get unlock => 'Sblocca';

  @override
  String get authReasonSend => 'Conferma che sei tu per firmare e inviare';

  @override
  String get authReasonNewWallet =>
      'Proteggi la chiave del portafoglio su questo dispositivo';

  @override
  String get authReasonInvite =>
      'Conferma che sei tu per finanziare le tessere';

  @override
  String get removeAnywayTitle => 'Rimuovere senza conferma?';

  @override
  String get removeAnywayBody =>
      'Non è stato possibile sbloccare il portafoglio. Rimuoverlo cancella la sua chiave da questo dispositivo: solo la copia del seed potrà recuperarlo.';

  @override
  String get protectionDevice =>
      'Chiave cifrata con il blocco di questo dispositivo';

  @override
  String get protectionPasskey =>
      'Chiave cifrata con una passkey di questo dispositivo';

  @override
  String get protectionPassphrase => 'Chiave cifrata con la tua passphrase';

  @override
  String get protectionLegacy =>
      'Chiave non ancora cifrata: lo sarà al prossimo sblocco';

  @override
  String get confirmSendTitle => 'Controlla prima di firmare';

  @override
  String get confirmSendFinal =>
      'Firmando, questo viene inviato al nodo. Non si può annullare: una volta minato, resta nella catena.';

  @override
  String signAndSendShortcut(String keys) {
    return 'Firma e invia ($keys)';
  }

  @override
  String get threadWithdrawnMine =>
      'L\'hai ritirata: nascosta agli altri, e il suo testo eliminato dalle app Murmur';

  @override
  String get threadWithdrawnMineNote =>
      'Hai segnalato la tua discussione, e questo la ritira. Le app Murmur non la mostrano più agli altri e ne eliminano il testo, anche su questo dispositivo; i nodi possono smettere di conservarne il testo e le risposte.';

  @override
  String get threadWithdrawnNote =>
      'L\'autore ha segnalato questa discussione, e questo la ritira. Le app Murmur non la elencano più e ne eliminano il testo, e i nodi possono smettere di conservarne il testo e le risposte.';

  @override
  String get flagOwnInfo =>
      'Questo messaggio è tuo. Segnalarlo lo ritira: le app Murmur smettono di mostrarlo agli altri e ne eliminano il testo, anche su questo dispositivo, e i nodi possono smettere di conservarne il testo e le risposte. Non si può annullare.';

  @override
  String get inviteFromTitle => 'Nome sui biglietti';

  @override
  String get inviteFromBody =>
      'Ogni biglietto dice da chi viene. Li ha finanziati il portafoglio che invita, che ora potrebbe non essere quello di questo dispositivo.';

  @override
  String get inviteFromOriginal => 'Indirizzo del portafoglio che invita';

  @override
  String get inviteFromOriginalAlias =>
      'Il tuo nome per il portafoglio che invita';

  @override
  String get inviteFromOriginalPublic =>
      'Nome pubblico del portafoglio che invita';

  @override
  String get inviteFromCurrent => 'Indirizzo di questo portafoglio';

  @override
  String get inviteFromCurrentAlias => 'Il tuo nome per questo portafoglio';

  @override
  String get inviteFromCurrentPublic => 'Nome pubblico di questo portafoglio';

  @override
  String get inviteFromCustom => 'Altro testo';

  @override
  String get inviteFromCustomHint =>
      'Lascialo vuoto per non stampare alcun nome';

  @override
  String get inviteFromNotSet => 'Nessun nome su questo dispositivo';

  @override
  String get inviteFromMixed => 'Diverso tra i biglietti scelti';

  @override
  String get inviteFromChecking => 'Ancora in cerca nella catena';

  @override
  String get cancelReturnTo => 'Invia i token a';

  @override
  String get cancelToFunder => 'Il portafoglio che l\'ha finanziato';

  @override
  String get cancelToCurrent => 'Questo portafoglio';

  @override
  String get publicName => 'Nome pubblico';

  @override
  String get publicNameNone => 'Nessuno noto';

  @override
  String get publicNameSet => 'Imposta nome pubblico';

  @override
  String get publicNameField => 'Nome';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return 'Al massimo $maxString byte';
  }

  @override
  String get aliasBadCharacter =>
      'Non sono ammessi caratteri invisibili o di controllo';

  @override
  String get aliasEdgeSpace => 'Niente spazi all\'inizio o alla fine';

  @override
  String aliasSetTo(String name) {
    return 'Nome pubblico: $name';
  }

  @override
  String get aliasCleared => 'Nome pubblico tolto';

  @override
  String get nonTextMessage =>
      '(non è testo: dati di una convenzione delle app)';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return 'Pubblica il tuo nome pubblico. Come una nuova discussione, costa $totalString × la commissione: la commissione va al miner e $burnString × la commissione viene bruciato.';
  }

  @override
  String get inviteFromNoPublic => 'Nessun nome pubblico noto';

  @override
  String get starredTitle => 'Con stella';

  @override
  String get noStarred =>
      'Ancora nessuna stella. Metti una stella a una discussione o a un messaggio dalla sua pagina e comparirà qui.';

  @override
  String get starredGone => 'Non è più nella catena';

  @override
  String get feeSuggestedLabel => 'Commissione suggerita';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return 'per $weightString byte';
  }

  @override
  String get feeRoom => 'I blocchi hanno spazio';

  @override
  String get feeFull => 'I blocchi sono pieni';

  @override
  String get feeNextBlock => 'Prossimo blocco';

  @override
  String get feePoolEntry => 'Per entrare in coda';

  @override
  String get feeMinimum => 'Minimo';

  @override
  String get feeWhy => 'Perché questa commissione';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**La commissione è per byte**: $baseString byte più il tuo messaggio. I messaggi lunghi costano di più quando i blocchi sono pieni.';
  }

  @override
  String feeRecentPoint(int lowest, int median) {
    final intl.NumberFormat lowestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lowestString = lowestNumberFormat.format(lowest);
    final intl.NumberFormat medianNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String medianString = medianNumberFormat.format(median);

    return '**I blocchi recenti** hanno accettato commissioni di appena **$lowestString** (mediana $medianString).';
  }

  @override
  String get feeRecentNonePoint =>
      '**I blocchi recenti** non avevano transazioni.';

  @override
  String get inviteNoExpiryPoint =>
      '**Non scade**: un biglietto vale finché qualcuno non lo riscatta.';

  @override
  String get inviteCancelPoint =>
      '**Annulla quando vuoi**: i suoi token tornano indietro.';

  @override
  String get invitePublicPoint =>
      '**È pubblico**: la catena mostra che hai finanziato ogni biglietto e quale portafoglio l\'ha riscattato.';

  @override
  String get inviteCashPoint =>
      '**Chi ha il codice** può riscattare il biglietto. Tienili privati finché non li consegni.';

  @override
  String get inviteLocalPoint =>
      '**Salvati solo su questo dispositivo.** Se i suoi dati vengono cancellati o l\'app viene rimossa, i codici sono **persi per sempre**, e con loro i token dei biglietti non ancora consegnati.';

  @override
  String get publicNameIntro =>
      'Il tuo nome pubblico compare **accanto al tuo indirizzo** nelle app Murmur.';

  @override
  String publicNameShownAs(String name) {
    return 'Apparirà come **$name**';
  }

  @override
  String get publicNameNotUnique =>
      '**Non è unico**: chiunque può scegliere lo stesso nome. L\'indirizzo accanto distingue le persone.';

  @override
  String get publicNameCost =>
      '**Costa quanto una nuova discussione**, ogni volta che lo imposti o lo cambi.';

  @override
  String get publicNameRemovable =>
      '**È un messaggio nella catena**: qualsiasi nodo può cancellarlo, e allora sparisce.';

  @override
  String get publicNameClear => '**Lascialo vuoto** per toglierlo.';
}
