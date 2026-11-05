// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => 'Fil';

  @override
  String get kindReply => 'Réponse';

  @override
  String get kindTransfer => 'Transfert';

  @override
  String get kindFlag => 'Signalement';

  @override
  String get contentUnavailable =>
      '(contenu indisponible : le nœud ne l\'a pas)';

  @override
  String get contentWithdrawn => '(retiré par son auteur)';

  @override
  String get contentLoading => '(chargement du message…)';

  @override
  String get pending => 'en attente';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié';

  @override
  String replyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString réponses',
      one: '$countString réponse',
      zero: 'Aucune réponse',
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
      other: '$countString signalements',
      one: '$countString signalement',
      zero: 'Aucun signalement',
    );
    return '$_temp0';
  }

  @override
  String transferOf(String amount) {
    return 'Transfert de $amount';
  }

  @override
  String flagOn(String text) {
    return 'Signalement de « $text »';
  }

  @override
  String flagOnTx(String txid) {
    return 'Signalement de $txid';
  }

  @override
  String get replyNotThreaded => 'Réponse (hors d\'un fil)';

  @override
  String routeFrom(String address) {
    return 'de $address';
  }

  @override
  String routeFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String errUnreachable(String detail) {
    return 'Impossible de joindre le nœud : $detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return 'Impossible de joindre le pont WebSocket à $url. Lancez-le avec : dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return 'Erreur de connexion : $detail';
  }

  @override
  String get errClosed => 'Le nœud a fermé la connexion.';

  @override
  String get errTimeout => 'Le nœud n\'a pas répondu à temps.';

  @override
  String errProtocol(String detail) {
    return 'Erreur de protocole : $detail';
  }

  @override
  String errVersion(int node, int ours) {
    return 'Le nœud parle le protocole $node ; ce client parle le protocole $ours.';
  }

  @override
  String get errAppOutdated =>
      'Le réseau utilise désormais un protocole plus récent que cette application. Mettez l\'application à jour pour continuer à l\'utiliser.';

  @override
  String get errAppOutdatedWeb =>
      'Le réseau utilise désormais un protocole plus récent que cette page. Rechargez la page pour obtenir la nouvelle version.';

  @override
  String get errAppOutdatedSystem =>
      'Le réseau utilise désormais un protocole plus récent que cette application. Mettez-la à jour depuis les mises à jour logicielles de votre système.';

  @override
  String get getNewVersion => 'Obtenir la nouvelle version';

  @override
  String get appMaybeOld =>
      'Cette version de l\'application a **plus d\'un mois** : une version plus récente est sans doute disponible.';

  @override
  String get appMaybeOldSystem =>
      'Cette version de l\'application a **plus d\'un mois** : les mises à jour logicielles de votre système en proposent sans doute une plus récente.';

  @override
  String get localNodeOutdated =>
      'Le réseau utilise un **protocole plus récent** : ce nœud ne pourra pas le suivre tant que l\'application n\'est pas mise à jour.';

  @override
  String get localNodeOutdatedSystem =>
      'Le réseau utilise un **protocole plus récent** : ce nœud ne pourra pas le suivre tant que l\'application n\'est pas mise à jour depuis les mises à jour logicielles de votre système.';

  @override
  String errSyncFailed(String cause) {
    return 'Échec de la synchronisation : $cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return 'Bloc relayé ignoré : $detail';
  }

  @override
  String get probFeeTooLow => 'Les frais sont inférieurs au minimum du réseau.';

  @override
  String get probMalformed => 'Cette transaction est mal formée.';

  @override
  String get probNeedsMessage => 'Écrivez un message.';

  @override
  String get probNeedsRecipient => 'Saisissez un destinataire.';

  @override
  String probAmountBelowFee(String fee) {
    return 'Le montant doit être au moins égal aux frais ($fee).';
  }

  @override
  String get probReplyParentNotMined =>
      'Vous ne pouvez répondre qu\'à un fil ou à une réponse déjà inclus dans un bloc.';

  @override
  String get probFlagNotMessage =>
      'Seuls les fils et les réponses peuvent être signalés.';

  @override
  String get probAlreadyFlagged => 'Ce portefeuille a déjà signalé ce message.';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'Le message fait $lengthString octets ; la limite est de $limitString.';
  }

  @override
  String probInsufficientBalance(String needed, String available) {
    return 'Solde insuffisant : $needed nécessaires, $available disponibles (solde confirmé moins les transactions en attente).';
  }

  @override
  String get probNotLive =>
      'Attendez que le client soit connecté et synchronisé.';

  @override
  String get probConnectionLost => 'Connexion au nœud perdue.';

  @override
  String get probDuplicate =>
      'Une transaction identique a déjà été envoyée dans cette seconde.';

  @override
  String get tabThreads => 'Fils';

  @override
  String get tabMessages => 'Messages';

  @override
  String get tabWallet => 'Portefeuille';

  @override
  String get tabChain => 'Chaîne';

  @override
  String get newThread => 'Nouveau fil';

  @override
  String get createWalletFirst => 'Créez ou importez d\'abord un portefeuille.';

  @override
  String get syncNow => 'Synchroniser';

  @override
  String get reconnect => 'Se reconnecter';

  @override
  String get changeNode => 'Changer de nœud';

  @override
  String get unknownNetwork =>
      'Ce nœud est sur un réseau que le client ne reconnaît pas. Ses ajustements de difficulté ne peuvent pas être vérifiés, et les récompenses de bloc sont comptées avec les valeurs du livre blanc : les soldes des mineurs peuvent être faux.';

  @override
  String get linkOffline => 'Hors ligne';

  @override
  String get linkConnecting => 'Connexion…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return 'Synchronisation $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'En direct · $heightString';
  }

  @override
  String get connectToNode => 'Se connecter à un nœud';

  @override
  String nodeAt(String address) {
    return 'Nœud $address';
  }

  @override
  String get language => 'Langue';

  @override
  String get systemLanguage => 'Langue du système';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get node => 'Nœud';

  @override
  String get connectHelpBridge =>
      'Dans le navigateur, le client se connecte par WebSocket : à l\'adresse WebSocket d\'un nœud (comme node.murmur.info, port 443, via TLS), ou à un pont local (dart run tool/ws_bridge.dart, port 7880).';

  @override
  String get connectHelpNative =>
      'L\'adresse pair-à-pair d\'un murmur-node (son --port, 7878 par défaut). Le port de contrôle (7879) ne fonctionnera pas. Le port 443 atteint un nœud derrière un WebSocket sécurisé, comme node.murmur.info.';

  @override
  String get host => 'Hôte';

  @override
  String get port => 'Port';

  @override
  String get required => 'Obligatoire';

  @override
  String get enterPort => 'Saisissez un numéro de port';

  @override
  String get disconnect => 'Se déconnecter';

  @override
  String get cancel => 'Annuler';

  @override
  String get connect => 'Se connecter';

  @override
  String get syncingChain => 'Synchronisation de la chaîne…';

  @override
  String get noThreads =>
      'Aucun fil pour l\'instant. Lancez-en un avec Nouveau fil.';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Au bloc $heightString ($time, $elapsed)';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString nouveaux blocs depuis',
      one: '$countString nouveau bloc depuis',
      zero: 'à jour',
    );
    return '$_temp0';
  }

  @override
  String agoSeconds(int s) {
    return 'il y a $s s';
  }

  @override
  String agoMinutes(int m, int s) {
    return 'il y a $m min $s s';
  }

  @override
  String agoHours(int h, int m) {
    return 'il y a $h h $m min';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return 'il y a $dString j $h h';
  }

  @override
  String threadStarted(String time) {
    return 'commencé $time';
  }

  @override
  String threadLastReply(String time) {
    return 'dernière réponse $time';
  }

  @override
  String get messagesNeedWallet =>
      'Créez ou importez un portefeuille dans l\'onglet Portefeuille pour voir vos messages.';

  @override
  String get noMessages => 'Aucun message ne correspond à ces filtres.';

  @override
  String get filterThreads => 'Mes fils';

  @override
  String get filterRepliesSent => 'Réponses envoyées';

  @override
  String get filterRepliesReceived => 'Réponses reçues';

  @override
  String get filterFlagsSent => 'Signalements émis';

  @override
  String get filterFlagsReceived => 'Signalements reçus';

  @override
  String get filterMentions => 'Mentions';

  @override
  String get mentionsLabel => 'Mentions';

  @override
  String get mentionPublicPoint =>
      '**Une mention est publique :** tout le monde peut voir qui vous avez nommé.';

  @override
  String mentionsMax(int max) {
    return 'Au plus $max mentions par message';
  }

  @override
  String get balance => 'Solde';

  @override
  String pendingCommitted(String amount) {
    return '$amount engagés dans des transactions en attente';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString blocs minés',
      one: '$countString bloc miné',
      zero: 'Aucun bloc miné',
    );
    return '$_temp0';
  }

  @override
  String get address => 'Adresse';

  @override
  String get showSeed => 'Afficher la graine';

  @override
  String get removeWallet => 'Supprimer le portefeuille';

  @override
  String get history => 'Historique';

  @override
  String get filters => 'Filtres';

  @override
  String get noHistory => 'Aucune transaction ne correspond à ces filtres.';

  @override
  String get walletFilterTransfersSent => 'Transferts envoyés';

  @override
  String get walletFilterTransfersReceived => 'Transferts reçus';

  @override
  String get walletFilterRepliesPaid => 'Payé pour des réponses';

  @override
  String get walletFilterRepliesEarned => 'Reçu pour des réponses';

  @override
  String get walletFilterThreadCosts => 'Coût des fils';

  @override
  String get walletFilterFlagCosts => 'Frais de signalement';

  @override
  String get seedTitle => 'Graine du portefeuille';

  @override
  String get seedWarning =>
      'Quiconque possède cette graine peut dépenser ce portefeuille. Elle a le même format qu\'un fichier de clé créé avec murmur-node keygen.';

  @override
  String get done => 'Terminé';

  @override
  String get removeWalletTitle => 'Supprimer le portefeuille ?';

  @override
  String get removeWalletBody =>
      'La graine sera effacée de cet appareil. Sans copie, tout solde à cette adresse est perdu.';

  @override
  String get remove => 'Supprimer';

  @override
  String get importWallet => 'Importer un portefeuille';

  @override
  String get importHelp =>
      'Saisissez ou collez la graine d\'un portefeuille : ses 24 mots, ou ses 64 caractères hexadécimaux (par exemple le contenu d\'un fichier de clé créé avec murmur-node keygen, murmur.key, pour utiliser les récompenses minées à son adresse).';

  @override
  String get seed => 'Graine';

  @override
  String get import => 'Importer';

  @override
  String get seedInvalid =>
      'Une graine fait 24 mots ou exactement 64 caractères hexadécimaux.';

  @override
  String get walletIntro =>
      'Un portefeuille signe les transactions que vous envoyez. Sa clé reste sur cet appareil.';

  @override
  String get createWallet => 'Créer un portefeuille';

  @override
  String get importSeed => 'Importer une graine';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return 'Aucun bloc à la hauteur $heightString (le sommet est à $tipString).';
  }

  @override
  String get searchInvalid =>
      'Saisissez une hauteur de bloc, ou un txid, un hash de bloc ou une adresse de 64 caractères.';

  @override
  String get searchHint =>
      'Rechercher une hauteur, un txid, un hash de bloc ou une adresse';

  @override
  String get noBlocks => 'Aucun bloc pour l\'instant.';

  @override
  String blockTitle(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Bloc $heightString';
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
      one: '$countString tx',
    );
    return '$_temp0';
  }

  @override
  String minerIs(String miner) {
    return 'mineur $miner';
  }

  @override
  String get statNetwork => 'Réseau';

  @override
  String get statHeight => 'Hauteur';

  @override
  String get statNodeHeight => 'Hauteur du nœud';

  @override
  String get statNextReward => 'Récompense du prochain bloc';

  @override
  String rewardPlusFees(String amount) {
    return '$amount + frais';
  }

  @override
  String get statBurnPool => 'Réserve brûlée';

  @override
  String get statCirculating => 'En circulation';

  @override
  String get tip => 'Sommet';

  @override
  String get previousBlock => 'Bloc précédent';

  @override
  String get nextBlock => 'Bloc suivant';

  @override
  String get blockGone => 'Ce bloc n\'est plus sur la meilleure chaîne.';

  @override
  String get hash => 'Hash';

  @override
  String get previous => 'Précédent';

  @override
  String get time => 'Heure';

  @override
  String get confirmations => 'Confirmations';

  @override
  String get miner => 'Mineur';

  @override
  String get reward => 'Récompense';

  @override
  String get merkleRoot => 'Racine de Merkle';

  @override
  String get target => 'Cible';

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
      one: '$countString transaction',
      zero: 'Aucune transaction',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => 'Votre adresse';

  @override
  String get noTransactions => 'Aucune transaction.';

  @override
  String get sendToAddress => 'Envoyer à cette adresse';

  @override
  String get threadGone => 'Ce fil n\'est plus sur la chaîne.';

  @override
  String paidToThreadAuthor(String amount) {
    return 'a payé $amount à l\'auteur du fil';
  }

  @override
  String get actionReply => 'Répondre';

  @override
  String get actionFlag => 'Signaler';

  @override
  String get flagged => 'Signalé';

  @override
  String get details => 'Détails';

  @override
  String get txTitle => 'Transaction';

  @override
  String get txNotFound =>
      'Transaction introuvable. Elle a peut-être été retirée des transactions en attente, ou supprimée par une réorganisation.';

  @override
  String refNotLocal(String txid) {
    return 'Transaction $txid (absente de la chaîne locale)';
  }

  @override
  String get flaggedMessage => 'Message signalé';

  @override
  String get inReplyTo => 'En réponse à';

  @override
  String get notThreadedExplain =>
      'Désigne ce parent, mais ne fait pas partie de son fil : le parent doit être un fil ou une réponse déjà miné, et cette réponse doit payer son auteur. Elle ne compte que comme un paiement.';

  @override
  String get message => 'Message';

  @override
  String get openThread => 'Ouvrir le fil';

  @override
  String get transactionId => 'ID de transaction';

  @override
  String get type => 'Type';

  @override
  String get from => 'De';

  @override
  String get to => 'À';

  @override
  String get burned => 'Brûlé';

  @override
  String burnedValue(String amount) {
    return '$amount (rendus aux mineurs par la réserve brûlée)';
  }

  @override
  String get amount => 'Montant';

  @override
  String get fee => 'Frais';

  @override
  String get contentHash => 'Hash du contenu';

  @override
  String get contentSize => 'Taille du contenu';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString octets (un sel de $salt octets et un message de $messageString octets)';
  }

  @override
  String get reports => 'Signalements';

  @override
  String get repliesTo => 'Répond à';

  @override
  String get weight => 'Poids';

  @override
  String weightValue(int weight, String perByte) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString octets ($perByte de frais par octet)';
  }

  @override
  String get publicKey => 'Clé publique';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Confirmée dans le bloc $heightString';
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
      one: '$countString confirmation',
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
      other: 'Non confirmée après $countString blocs',
      one: 'Non confirmée après $countString bloc',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused =>
      'Le nœud l\'a peut-être refusée (par exemple, le solde a changé avant qu\'elle soit minée). Il ne signale pas les transactions refusées.';

  @override
  String get sentWaiting => 'Envoyée, en attente d\'un bloc';

  @override
  String get submittedHere => 'Soumise depuis cet appareil.';

  @override
  String get pendingTitle => 'En attente';

  @override
  String get relayedPending => 'Relayée par le nœud, pas encore dans un bloc.';

  @override
  String get viewBlock => 'Voir le bloc';

  @override
  String get newTransaction => 'Nouvelle transaction';

  @override
  String get flagMessage => 'Signaler le message';

  @override
  String flaggingInfo(String author) {
    return 'Signalement de ce message de $author. Chaque portefeuille peut signaler un message une fois. Les clients décident quoi faire des signalements.';
  }

  @override
  String replyingTo(String author) {
    return 'Réponse à $author';
  }

  @override
  String explainThread(int total, int burn) {
    return 'Lance un nouveau fil. Il coûte $total × les frais : les frais vont au mineur, et $burn × les frais sont brûlés. Les jetons brûlés retournent aux mineurs dans les blocs suivants.';
  }

  @override
  String get explainReply =>
      'Votre réponse paie à l\'auteur du fil au moins les frais (vous pouvez donner plus), plus les frais au mineur.';

  @override
  String get explainTransfer =>
      'Un simple transfert de jetons, sans message. Le montant doit être au moins égal aux frais.';

  @override
  String get recipientAddress => 'Adresse du destinataire';

  @override
  String get enterAddress =>
      'Saisissez une adresse hexadécimale de 64 caractères';

  @override
  String get payToAuthor => 'Payer l\'auteur du fil';

  @override
  String get notAnAmount => 'Saisissez un montant';

  @override
  String atLeastFee(String fee) {
    return 'Au moins les frais ($fee)';
  }

  @override
  String get feeToMiner => 'Frais (au mineur)';

  @override
  String suggestedFee(String fee) {
    return 'Suggérés : $fee';
  }

  @override
  String feeBelowSuggested(String fee) {
    return 'Sous les frais suggérés ($fee) : l\'entrée dans un bloc peut prendre un moment.';
  }

  @override
  String feeAboveSuggested(String fee) {
    return 'Au-dessus des frais suggérés ($fee) : vous offrez au mineur plus que nécessaire.';
  }

  @override
  String atLeastMin(String min) {
    return 'Au moins $min';
  }

  @override
  String bytesOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString octets';
  }

  @override
  String tooLong(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Trop long : $countString octets';
  }

  @override
  String get murmurEmoji => 'Émojis Murmur';

  @override
  String murmurEmojiHint(String example) {
    return 'Dessinés uniquement dans Murmur. Les autres applis affichent le nom, comme $example.';
  }

  @override
  String get sendingNeedsLive =>
      'L\'envoi est possible une fois le client connecté et synchronisé.';

  @override
  String get signAndSend => 'Signer et envoyer';

  @override
  String get costFee => 'Frais, au mineur';

  @override
  String costBurn(int multiple) {
    return 'Brûlé : $multiple × les frais';
  }

  @override
  String get costPaid => 'Payé au destinataire';

  @override
  String get costTotal => 'Coût total';

  @override
  String get costAvailable =>
      'Disponible : solde moins les transactions en attente';

  @override
  String get costRemaining => 'Reste après l\'envoi';

  @override
  String get checkingFees => 'Vérification des frais du réseau…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Estimés d\'après ce que ce client a vu ($countString en attente depuis sa connexion) ; le rapport de frais du nœud n\'était pas disponible.';
  }

  @override
  String get use => 'Utiliser';

  @override
  String balanceBeforeAfter(String before, String after) {
    return '$before → $after';
  }

  @override
  String balanceBeforeAfterTooltip(String before, String after) {
    return 'Solde : $before avant, $after après';
  }

  @override
  String get loadingOlder => 'Chargement des blocs plus anciens…';

  @override
  String get blockLoading => 'Chargement de ce bloc…';

  @override
  String get txSearching =>
      'Recherche de cette transaction dans les blocs encore en chargement…';

  @override
  String get storageBanner =>
      'Garder une copie de la chaîne sur cet appareil ? Les visites suivantes s\'ouvrent alors en quelques secondes au lieu de tout retélécharger. Elle reste ici et n\'est jamais envoyée à personne : pas de cookies, pas de pistage. La clé de votre portefeuille et vos réglages sont toujours conservés sur cet appareil, car l\'application en a besoin pour fonctionner.';

  @override
  String get storageAllow => 'Autoriser le stockage nécessaire';

  @override
  String get storageReject => 'Refuser (plus lent)';

  @override
  String get storageOn => 'Copie locale de la chaîne : activée';

  @override
  String get storageOff =>
      'Copie locale de la chaîne : désactivée (chaque visite la retélécharge)';

  @override
  String get storageTurnOn => 'Activer';

  @override
  String get storageTurnOff => 'Désactiver et supprimer';

  @override
  String get checkingBalance => 'Vérification auprès du nœud…';

  @override
  String get errTampered =>
      'La connexion a été altérée ou coupée : un message a échoué au contrôle d\'intégrité.';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'L\'état engagé par le nœud au bloc $heightString ne correspond pas au décompte de la chaîne fait par ce client. Ne faites pas confiance à ce nœud : connectez-vous à un autre.';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'D\'après le nœud : $countString transactions en attente.',
      one: 'D\'après le nœud : $countString transaction en attente.',
      zero: 'D\'après le nœud : rien en attente.',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => 'Acceptée par le nœud et relayée.';

  @override
  String get statusRefused => 'Refusée par le nœud';

  @override
  String get statusInvalid => 'Rejetée comme invalide';

  @override
  String nodeReason(String reason) {
    return 'Le nœud dit : $reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'La chaîne ne mène pas au point de contrôle de cette version, au bloc $heightString : soit la version, soit tous les nœuds joints se trompent. Arrêt ; rien de cette chaîne n\'est fiable.';
  }

  @override
  String staleTip(String elapsed) {
    return 'Le bloc le plus récent a été produit $elapsed : ce nœud est peut-être en retard, ou coupé du réseau. Ce que vous voyez n\'est peut-être pas à jour.';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return 'Démarré au point de contrôle du bloc $heightString ; vérification des en-têtes jusqu\'au bloc de genèse ($doneString pour l\'instant).';
  }

  @override
  String get licenses => 'Licences';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => 'Réseau de test : les jetons n\'ont aucune valeur';

  @override
  String get linkNodeRepo => 'Code source du nœud et du protocole';

  @override
  String get linkWhitepaper => 'Livre blanc';

  @override
  String checkingHeaders(int done, int total) {
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Vérification des en-têtes de bloc : $doneString sur $totalString';
  }

  @override
  String reconnectingIn(int seconds) {
    return 'Nouvel essai dans $seconds s.';
  }

  @override
  String get languagesFilter => 'Langues';

  @override
  String get languageUndetected => 'Non détectée';

  @override
  String get hideFlaggedThreads => 'Masquer les fils que j\'ai signalés';

  @override
  String get star => 'Mettre en favori';

  @override
  String get unstar => 'Retirer des favoris';

  @override
  String get starredOnly => 'Fils favoris uniquement';

  @override
  String get localNodeRun => 'Faire tourner un nœud Murmur sur cet ordinateur';

  @override
  String get localNodeExplain =>
      'Votre ordinateur vérifie lui-même toute la chaîne, aide à la relayer et garde vos propres messages disponibles. Il ne garde que le dernier jour de la chaîne, et aucun message d\'autrui au-delà de la vérification d\'une heure.';

  @override
  String get localNodeStarting => 'Démarrage du nœud…';

  @override
  String localNodeRunning(String address) {
    return 'Le nœud tourne sur $address. L\'application continue de lire depuis le nœud que vous avez choisi.';
  }

  @override
  String localNodeFailed(String reason) {
    return 'Le nœud s\'est arrêté : $reason';
  }

  @override
  String get localNodeFailedUnknown =>
      'Le nœud s\'est arrêté de façon inattendue.';

  @override
  String get localNodeFromCheckpoint =>
      'Démarrage aux blocs les plus récents : les plus anciens sont vérifiés ensuite.';

  @override
  String localNodeCatchingUp(String height, String total) {
    return 'Rattrapage de la chaîne : bloc $height sur $total';
  }

  @override
  String localNodeCheckingHistory(String height, String total) {
    return 'Vérification des anciens blocs en arrière-plan : $height sur $total';
  }

  @override
  String get localNodeMine => 'Miner avec cet ordinateur';

  @override
  String get localNodeMineNote =>
      'Le minage paie l\'adresse de votre portefeuille, consomme de l\'électricité et fait davantage travailler votre ordinateur. Sur le réseau de test, les jetons servent uniquement aux essais.';

  @override
  String get localNodeMineNeedsWallet =>
      'Créez d\'abord un portefeuille : le minage paie son adresse.';

  @override
  String localNodeMinesTo(String name) {
    return 'Le minage paie **$name**';
  }

  @override
  String localNodeCpu(int pct) {
    return 'Jusqu\'à $pct % d\'un cœur de processeur';
  }

  @override
  String get localNodeGpu => 'Miner sur la carte graphique';

  @override
  String get localNodeGpuNote =>
      'Bien plus rapide que le processeur, et plus gourmand en électricité. Quand la carte ne peut pas servir, le minage continue sur le processeur.';

  @override
  String get localNodeGpuStarting =>
      'Démarrage de la carte graphique. Le processeur mine en attendant.';

  @override
  String localNodeGpuMining(String device) {
    return 'Minage sur **$device**';
  }

  @override
  String get localNodeGpuMiningAny => 'Minage sur **la carte graphique**';

  @override
  String get localNodeGpuUnavailable =>
      'La carte graphique ne peut pas servir : **le minage continue sur le processeur**.';

  @override
  String localNodeGpuDetail(String reason) {
    return 'Ce que dit le nœud : $reason';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fils masqués',
      one: '$count fil masqué',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => 'Rechercher dans les fils chargés';

  @override
  String get noMatches => 'Aucun fil chargé ne correspond.';

  @override
  String get timeJustNow => 'à l\'instant';

  @override
  String timeMinutesAgo(int n) {
    return 'il y a $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'il y a $n h';
  }

  @override
  String timeDaysAgo(int n) {
    return 'il y a $n j';
  }

  @override
  String get nameAddress => 'Nom';

  @override
  String get aliasTitle => 'Nommer cette adresse';

  @override
  String get aliasHelp =>
      'Le nom est gardé sur cet appareil uniquement. Laissez-le vide pour le retirer.';

  @override
  String get save => 'Enregistrer';

  @override
  String get mute => 'Masquer';

  @override
  String get unmute => 'Ne plus masquer';

  @override
  String get mutedNote =>
      'Masquée : ses fils et ses réponses sont cachés sur cet appareil.';

  @override
  String get earlierReplies => 'Réponses précédentes';

  @override
  String get quoteNotLoaded =>
      'Une réponse précédente (touchez pour la charger)';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réponses d\'adresses masquées, cachées',
      one: '$count réponse d\'une adresse masquée, cachée',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles réponses',
      one: '$count nouvelle réponse',
    );
    return '$_temp0';
  }

  @override
  String get invitations => 'Invitations';

  @override
  String get createInvitations => 'Créer des invitations';

  @override
  String get inviteHowMany => 'Nombre de cartes';

  @override
  String get inviteFund => 'Approvisionner les cartes';

  @override
  String get inviteCardTitle => 'Invitation Murmur';

  @override
  String inviteCardSerial(int n, int total) {
    return '$n sur $total';
  }

  @override
  String inviteCardFrom(String name) {
    return 'De la part de $name';
  }

  @override
  String get inviteCardHow =>
      'Scannez le code ou ouvrez le lien pour rejoindre Murmur.';

  @override
  String get inviteClaimed => 'Récupérée';

  @override
  String get inviteChecking => 'Vérification…';

  @override
  String get claimTitle => 'Une invitation pour vous';

  @override
  String claimInvitedBy(String name) {
    return 'Invitation de $name';
  }

  @override
  String claimHolds(String amount) {
    return 'Cette invitation contient $amount : de quoi lancer vos premiers fils.';
  }

  @override
  String get claimCreateWallet => 'Créer mon portefeuille et récupérer';

  @override
  String get claimIntoWallet => 'Récupérer dans mon portefeuille';

  @override
  String get claimDone =>
      'Récupérée. Les jetons arrivent dans votre portefeuille avec le prochain bloc.';

  @override
  String get claimEmpty => 'Cette invitation a déjà été récupérée, ou reprise.';

  @override
  String get claimWrongNetwork =>
      'Cette invitation est pour un autre réseau que celui du nœud actuel.';

  @override
  String get claimInvalid => 'Ce n\'est pas un code d\'invitation valide.';

  @override
  String get haveInvitation => 'J\'ai une invitation';

  @override
  String get inviteCodeField => 'Code ou lien d\'invitation';

  @override
  String get claim => 'Récupérer';

  @override
  String get cancelInvitation => 'Annuler l\'invitation';

  @override
  String get inviteCancelled => 'Annulée';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Annuler $count invitations ?',
      one: 'Annuler cette invitation ?',
    );
    return '$_temp0';
  }

  @override
  String cancelInviteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Leurs jetons reviennent, et les personnes qui ont les cartes ne peuvent plus les récupérer.',
      one:
          'Ses jetons reviennent, et la personne qui a la carte ne peut plus la récupérer.',
    );
    return '$_temp0';
  }

  @override
  String get keepInvitation => 'La garder';

  @override
  String get printOne => 'Imprimer';

  @override
  String inviteDoneSection(int count) {
    return 'Récupérées ou annulées ($count)';
  }

  @override
  String get inviteEachLabel => 'Chaque carte';

  @override
  String get inviteEachCaption =>
      'Cinq fils aux frais d\'aujourd\'hui, plus les frais pour la récupérer.';

  @override
  String get inviteTotalLabel => 'Vous payez';

  @override
  String get inviteTotalCaption => 'Au total, frais compris.';

  @override
  String get inviteWaitingState => 'En attente de récupération';

  @override
  String get inviteCardSlogan => 'Votre voix a sa place ici.';

  @override
  String get inviteCardJoin => 'Scannez pour rejoindre';

  @override
  String get share => 'Partager…';

  @override
  String get inviteDetailFunded => 'Approvisionnée';

  @override
  String get inviteDetailClaimedBy => 'Récupérée par';

  @override
  String get inviteDetailReceived => 'Reçu';

  @override
  String get inviteDetailCancelled =>
      'Annulée : les jetons sont revenus dans votre portefeuille';

  @override
  String get inviteDetailReturned => 'Rendu';

  @override
  String get inviteDetailOnItsWay => 'En route vers un bloc';

  @override
  String get seedConfirmTitle => 'Afficher votre graine ?';

  @override
  String get seedConfirmBody =>
      'Quiconque voit la graine peut dépenser depuis ce portefeuille. Assurez-vous que personne d\'autre ne voit votre écran.';

  @override
  String get showAction => 'Afficher';

  @override
  String get authReasonSeed =>
      'Confirmez votre identité pour voir la graine du portefeuille';

  @override
  String get authReasonRemove =>
      'Confirmez votre identité pour supprimer ce portefeuille';

  @override
  String get authFailed => 'Non confirmé : rien n\'a été affiché ni modifié.';

  @override
  String get passphraseNewTitle => 'Choisissez une phrase secrète';

  @override
  String get passphraseNewWhat =>
      '**Une seule phrase secrète pour cette application.** Elle chiffre la clé de votre portefeuille et les codes de vos cartes d\'invitation sur cet appareil.';

  @override
  String get passphraseNewWhen =>
      'Vous la saisirez **à chaque fois** que vous envoyez, affichez la graine ou supprimez le portefeuille, et pour afficher, imprimer ou annuler une carte.';

  @override
  String get passphraseNewForget =>
      'Si vous l\'oubliez, seule la **sauvegarde de votre graine** permet de retrouver le portefeuille, et les cartes pas encore remises ne peuvent plus être affichées ni annulées.';

  @override
  String get passphraseField => 'Phrase secrète';

  @override
  String get passphraseRepeat => 'Répétez la phrase secrète';

  @override
  String passphraseTooShort(int min) {
    return 'Au moins $min caractères';
  }

  @override
  String get passphraseMismatch => 'Les deux ne correspondent pas';

  @override
  String get passphraseTitle => 'Phrase secrète';

  @override
  String get wrongPassphrase =>
      'Mauvaise phrase secrète : rien n\'a été affiché ni envoyé.';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get authReasonSend =>
      'Confirmez votre identité pour signer et envoyer';

  @override
  String get authReasonNewWallet =>
      'Protégez la clé de votre portefeuille sur cet appareil';

  @override
  String get authReasonInvite =>
      'Confirmez votre identité pour approvisionner les cartes';

  @override
  String get removeAnywayTitle => 'Supprimer sans confirmation ?';

  @override
  String get removeAnywayBody =>
      'Le portefeuille n\'a pas pu être déverrouillé. Le supprimer efface sa clé de cet appareil : seule la sauvegarde de votre graine permet de le retrouver.';

  @override
  String get forgetCardsKeyTitle =>
      'Impossible de déverrouiller vos cartes d\'invitation';

  @override
  String get forgetCardsKeyBody =>
      'Un nouveau portefeuille reprend la phrase secrète ou la clé d\'accès de vos cartes d\'invitation. Si vous ne l\'avez plus, abandonnez la clé des cartes : le portefeuille reçoit une nouvelle phrase secrète, et les cartes pas encore récupérées ne pourront plus être affichées, imprimées ni annulées depuis cet appareil. Leurs jetons restent sur les cartes.';

  @override
  String get forgetCardsKeyAction => 'Abandonner la clé des cartes';

  @override
  String get inviteCodeLost => 'Code absent de cet appareil';

  @override
  String get protectionDevice =>
      'Clé chiffrée avec le verrouillage de cet appareil';

  @override
  String get protectionPasskey =>
      'Clé chiffrée avec une clé d\'accès sur cet appareil';

  @override
  String get protectionPassphrase => 'Clé chiffrée avec votre phrase secrète';

  @override
  String get protectionLegacy =>
      'Clé pas encore chiffrée : elle le sera au prochain déverrouillage';

  @override
  String get confirmSendTitle => 'Vérifiez avant de signer';

  @override
  String get confirmSendFinal =>
      'Signer envoie ceci au nœud. Impossible de revenir en arrière : une fois minée, la transaction reste sur la chaîne.';

  @override
  String signAndSendShortcut(String keys) {
    return 'Signer et envoyer ($keys)';
  }

  @override
  String get threadWithdrawnMine =>
      'Vous l\'avez retiré : caché aux autres, et son texte effacé des applications Murmur';

  @override
  String get threadWithdrawnMineNote =>
      'Vous avez signalé votre propre fil, ce qui le retire. Les applications Murmur ne le montrent plus aux autres et effacent son texte, y compris sur cet appareil ; les nœuds peuvent cesser de garder son texte et ses réponses.';

  @override
  String get threadWithdrawnNote =>
      'Son auteur a signalé ce fil, ce qui le retire. Les applications Murmur ne le listent plus et effacent son texte, et les nœuds peuvent cesser de garder son texte et ses réponses.';

  @override
  String get flagOwnInfo =>
      'C\'est votre propre message. Le signaler le retire : les applications Murmur cessent de le montrer aux autres et effacent son texte, y compris sur cet appareil, et les nœuds peuvent cesser de garder son texte et ses réponses. C\'est irréversible.';

  @override
  String get inviteFromTitle => 'Nom sur les cartes';

  @override
  String get inviteFromBody =>
      'Chaque carte indique de qui elle vient. Les cartes ont été approvisionnées par le portefeuille qui invite, qui n\'est peut-être plus celui de cet appareil.';

  @override
  String get inviteFromOriginal => 'Adresse du portefeuille qui invite';

  @override
  String get inviteFromOriginalAlias =>
      'Votre nom pour le portefeuille qui invite';

  @override
  String get inviteFromOriginalPublic =>
      'Nom public du portefeuille qui invite';

  @override
  String get inviteFromCurrent => 'Adresse de ce portefeuille';

  @override
  String get inviteFromCurrentAlias => 'Votre nom pour ce portefeuille';

  @override
  String get inviteFromCurrentPublic => 'Nom public de ce portefeuille';

  @override
  String get inviteFromCustom => 'Autre texte';

  @override
  String get inviteFromCustomHint => 'Laissez vide pour n\'imprimer aucun nom';

  @override
  String get inviteFromNotSet => 'Aucun nom donné sur cet appareil';

  @override
  String get inviteFromMixed => 'Diffère entre les cartes sélectionnées';

  @override
  String get inviteFromChecking => 'Encore en cours de recherche sur la chaîne';

  @override
  String get cancelReturnTo => 'Envoyer les jetons à';

  @override
  String get cancelToFunder => 'Le portefeuille qui l\'a approvisionnée';

  @override
  String get cancelToCurrent => 'Ce portefeuille';

  @override
  String get publicName => 'Nom public';

  @override
  String get publicNameNone => 'Aucun connu';

  @override
  String get publicNameSet => 'Définir le nom public';

  @override
  String get publicNameField => 'Nom';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return 'Au plus $maxString octets';
  }

  @override
  String get aliasBadCharacter =>
      'Les caractères invisibles ou de contrôle ne sont pas autorisés';

  @override
  String get aliasEdgeSpace => 'Pas d\'espace au début ni à la fin';

  @override
  String aliasSetTo(String name) {
    return 'Nom public : $name';
  }

  @override
  String get aliasCleared => 'Nom public effacé';

  @override
  String profileSetTo(String name) {
    return 'Nom public et image : $name';
  }

  @override
  String get profilePictureOnly => 'Image publique, sans nom';

  @override
  String get nonTextMessage =>
      '(pas du texte : des données pour une convention d\'application)';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return 'Publie votre nom public. Comme un nouveau fil, il coûte $totalString × les frais : les frais vont au mineur, et $burnString × les frais sont brûlés.';
  }

  @override
  String get inviteFromNoPublic => 'Aucun nom public connu';

  @override
  String get starredTitle => 'Favoris';

  @override
  String get noStarred =>
      'Aucun favori pour l\'instant. Mettez en favori un fil, un message ou une personne depuis sa page, et il apparaîtra ici.';

  @override
  String get starredGone => 'N\'est plus sur la chaîne';

  @override
  String get feeSuggestedLabel => 'Frais suggérés';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return 'pour $weightString octets';
  }

  @override
  String get feeRoom => 'Les blocs ont de la place';

  @override
  String get feeFull => 'Les blocs sont pleins';

  @override
  String get feeNextBlock => 'Prochain bloc';

  @override
  String get feePoolEntry => 'Pour entrer dans la file d\'attente';

  @override
  String get feeMinimum => 'Minimum';

  @override
  String get feeWhy => 'Pourquoi ces frais';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**Les frais sont par octet** : $baseString octets plus votre message. Les messages plus longs coûtent plus quand les blocs sont pleins.';
  }

  @override
  String feeRecentPoint(String lowest, String median) {
    return '**Les blocs récents** ont pris des frais aussi bas que **$lowest** (médiane $median).';
  }

  @override
  String get feeRecentNonePoint =>
      '**Les blocs récents** n\'avaient aucune transaction.';

  @override
  String get inviteNoExpiryPoint =>
      '**Pas d\'expiration** : une carte fonctionne jusqu\'à ce que quelqu\'un la récupère.';

  @override
  String get inviteCancelPoint =>
      '**Annulable à tout moment** : ses jetons reviennent.';

  @override
  String get invitePublicPoint =>
      '**Public** : la chaîne montre que vous avez approvisionné chaque carte, et quel portefeuille l\'a récupérée.';

  @override
  String get inviteCashPoint =>
      '**Quiconque a le code** peut récupérer la carte. Gardez les cartes privées jusqu\'à les remettre.';

  @override
  String get inviteLocalPoint =>
      '**Gardées uniquement sur cet appareil.** Si ses données sont effacées ou l\'application supprimée, les codes sont **perdus pour de bon**, tout comme les jetons des cartes pas encore remises.';

  @override
  String get publicNameIntro =>
      'Votre nom public apparaît **à côté de votre adresse** dans les applications Murmur.';

  @override
  String publicNameShownAs(String name) {
    return 'Apparaît comme **$name**';
  }

  @override
  String get publicNameNotUnique =>
      '**Pas unique** : n\'importe qui peut choisir le même nom. L\'adresse à côté permet de distinguer les gens.';

  @override
  String get publicNameCost =>
      '**Coûte autant qu\'un nouveau fil**, chaque fois que vous le définissez ou le changez.';

  @override
  String get publicNameRemovable =>
      '**Un message sur la chaîne** : n\'importe quel nœud peut l\'effacer, et il disparaît alors.';

  @override
  String get publicNameClear => '**Laissez-le vide** pour l\'effacer.';

  @override
  String get publicNamePicture => 'Image';

  @override
  String get pictureFromPhotos => 'Depuis les photos';

  @override
  String get pictureFromFiles => 'Depuis les fichiers';

  @override
  String get pictureChoose => 'Choisir une image';

  @override
  String get pictureRemove => 'Retirer l\'image';

  @override
  String pictureTooLarge(String size) {
    return 'Ce fichier est trop volumineux : choisissez-en un de moins de $size Mo.';
  }

  @override
  String get pictureUnreadable =>
      'Ce fichier ne peut pas être lu comme une image.';

  @override
  String get picturePoint =>
      '**32 × 32 pixels, 16 couleurs**, affichée à la place de la marque de votre adresse.';

  @override
  String get pictureCost => '**Environ trois fois le coût** avec une image.';

  @override
  String get passkeyNoPrfTitle =>
      'Ce gestionnaire de clés d\'accès ne peut pas protéger le portefeuille';

  @override
  String get passkeyNoPrfWhy =>
      '**Il ne peut pas chiffrer.** Pour verrouiller la clé de votre portefeuille, un gestionnaire de clés d\'accès doit dériver une clé de la clé d\'accès (WebAuthn PRF). Celui que vous avez choisi ne le fait pas.';

  @override
  String get passkeyNoPrfTry =>
      '**Essayez un autre gestionnaire**, comme l\'app Mots de passe d\'Apple ou le Gestionnaire de mots de passe de Google, ou protégez le portefeuille par une **phrase secrète**.';

  @override
  String get passkeyNoPrfLeftover =>
      'La clé d\'accès qu\'il vient d\'enregistrer (**Murmur wallet**) ne déverrouille rien : vous pouvez la supprimer de ce gestionnaire.';

  @override
  String get passkeyTryAnother =>
      'Essayer un autre gestionnaire de clés d\'accès';

  @override
  String get passkeyUsePassphrase => 'Utiliser une phrase secrète';

  @override
  String inviteDetailCancelledTo(String name) {
    return 'Annulée : les jetons sont allés à $name';
  }

  @override
  String get seedNewTitle => 'Sauvegardez la graine de votre portefeuille';

  @override
  String get seedNewKeep =>
      '**Gardez-la en lieu sûr**, loin de cet appareil : écrite sur papier, ou dans un gestionnaire de mots de passe.';

  @override
  String get seedNewOnlyWay =>
      'C\'est le **seul moyen de retrouver** ce portefeuille si cet appareil est perdu ou sa phrase secrète oubliée. Personne ne peut la récupérer pour vous.';

  @override
  String get seedNewSecret =>
      '**Quiconque la possède contrôle le portefeuille.** Ne la partagez jamais, et ne la saisissez jamais sur un site qui la demande.';

  @override
  String get seedNewSaved => 'J\'ai sauvegardé ma graine';

  @override
  String get seedAsWords => 'En 24 mots';

  @override
  String get seedAsHex => 'En 64 caractères';

  @override
  String get seedEitherForm =>
      'Les deux sont la même graine : l\'une ou l\'autre suffit.';

  @override
  String get copyWords => 'Copier les mots';

  @override
  String get copyCharacters => 'Copier les caractères';

  @override
  String get seedOrWords => 'Graine : 24 mots ou 64 caractères';

  @override
  String seedUnknownWord(String word) {
    return '« $word » ne fait pas partie des mots de graine. Vérifiez son orthographe.';
  }

  @override
  String get seedBadChecksum =>
      'Ces 24 mots ne forment pas une graine : l\'un d\'eux est faux ou mal placé.';

  @override
  String get qrCode => 'Code QR';

  @override
  String get addressQrHint => 'Scannez pour ouvrir cette adresse dans Murmur.';

  @override
  String get starredPeople => 'Personnes';

  @override
  String get starredThreads => 'Messages';

  @override
  String get noStarredThreads =>
      'Aucun fil ni message favori. Mettez-en un en favori depuis sa page et il apparaîtra ici.';

  @override
  String get noStarredPeople =>
      'Aucune personne favorite. Mettez quelqu\'un en favori depuis sa page et il apparaîtra ici.';

  @override
  String get newActivity => 'Nouvelle activité';

  @override
  String starredNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count favoris avec du nouveau',
      one: '$count favori avec du nouveau',
    );
    return '$_temp0';
  }

  @override
  String get authReasonCards =>
      'Confirmez votre identité pour déverrouiller les cartes d\'invitation';

  @override
  String get inviteLockedPoint =>
      '**Les codes sont stockés chiffrés.** Afficher, imprimer ou annuler une carte vous demande de les **déverrouiller**.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifyReplies => 'Réponses à vos fils et à vos messages';

  @override
  String get notifyMentions => 'Quand on vous mentionne';

  @override
  String get notifyStarred => 'Nouveautés de vos favoris';

  @override
  String get notifyNeedsWallet => 'Nécessite un portefeuille sur cet appareil';

  @override
  String get notifyDenied =>
      'Les notifications sont désactivées pour Murmur dans les réglages du système.';

  @override
  String get notifyPointLocal =>
      '**Vérifiées par cette application**, sur le nœud que vous avez choisi : rien ne passe par Google, Apple ni personne d\'autre.';

  @override
  String get notifyPointBackground =>
      'Quand l\'application est fermée, elle vérifie **environ toutes les 15 minutes**, selon ce que le système permet.';

  @override
  String get notifyPointOpen =>
      'Seulement **quand l\'application est ouverte**, lorsqu\'elle n\'est pas au premier plan.';

  @override
  String get notifyPointLockScreen =>
      'L\'écran de verrouillage **masque leur contenu**.';

  @override
  String get notifyChannel => 'Messages';

  @override
  String get notifyOpen => 'Ouvrir';

  @override
  String notifyReply(String name) {
    return '$name a répondu à votre fil';
  }

  @override
  String notifyAnswer(String name) {
    return '$name vous a répondu';
  }

  @override
  String notifyMention(String name) {
    return '$name vous mentionne';
  }

  @override
  String notifyStarredReply(String name) {
    return '$name a répondu dans un fil favori';
  }

  @override
  String notifyStarredPerson(String name) {
    return 'Nouveau message de $name';
  }

  @override
  String notifyMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString autres nouveaux messages',
      one: '$countString autre nouveau message',
    );
    return '$_temp0';
  }

  @override
  String get faceIdReason =>
      'Confirmez votre identité avant que la clé de votre portefeuille soit utilisée ou affichée.';

  @override
  String get refresh => 'Actualiser';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get newAboveLastVisit =>
      'Au-dessus : nouveau depuis votre dernière visite';

  @override
  String get publicNameAndPicture => 'Nom public et image';

  @override
  String get publicNameAndPictureSet => 'Définir le nom public et l\'image';

  @override
  String get publicNameStandOut =>
      '**Démarquez-vous** : un nom et une image que les autres voient à côté de votre adresse.';

  @override
  String get pictureLarger => 'Agrandir l\'image';

  @override
  String get keepMessagesAvailable => 'Garder mes messages disponibles';

  @override
  String get keepMessagesAvailableExplain =>
      '**Tant que l\'application est ouverte**, les lecteurs obtiennent vos messages auprès de vous quand les nœuds ne les gardent plus. **Seulement les vôtres**, jamais ceux des autres.';

  @override
  String errBadSignature(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Le bloc $heightString contient une transaction dont la signature n\'est pas valide : la chaîne du nœud enfreint les règles que tout nœud applique. Ne faites pas confiance à ce nœud : connectez-vous à un autre.';
  }

  @override
  String receivedOmitted(String count) {
    return '**Le nœud a omis** une partie de ce que d\'autres ont fait vous concernant ($count). C\'est affiché quand même, trouvé dans les blocs eux-mêmes.';
  }

  @override
  String get keyringUnavailable =>
      'Le trousseau du système est verrouillé et ne peut pas demander son mot de passe : le portefeuille ne peut donc pas être enregistré sur cet appareil. Déverrouillez le trousseau (se connecter au bureau le fait en général) et relancez Murmur.';
}
