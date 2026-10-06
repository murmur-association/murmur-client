// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => 'Hilo';

  @override
  String get kindReply => 'Respuesta';

  @override
  String get kindTransfer => 'Transferencia';

  @override
  String get kindFlag => 'Denuncia';

  @override
  String get contentUnavailable =>
      '(contenido no disponible: el nodo no lo tiene)';

  @override
  String get contentWithdrawn => '(retirado por su autor)';

  @override
  String get contentLoading => '(cargando el mensaje…)';

  @override
  String get pending => 'pendiente';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String replyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString respuestas',
      one: '1 respuesta',
      zero: 'Sin respuestas',
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
      other: '$countString denuncias',
      one: '1 denuncia',
      zero: 'Sin denuncias',
    );
    return '$_temp0';
  }

  @override
  String transferOf(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Transferencia de $amountString';
  }

  @override
  String flagOn(String text) {
    return 'Denuncia de «$text»';
  }

  @override
  String flagOnTx(String txid) {
    return 'Denuncia de $txid';
  }

  @override
  String get replyNotThreaded => 'Respuesta (fuera de un hilo)';

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
    return 'No se pudo contactar con el nodo: $detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return 'No se pudo contactar con el puente WebSocket en $url. Inícialo con: dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return 'Error de conexión: $detail';
  }

  @override
  String get errClosed => 'El nodo cerró la conexión.';

  @override
  String get errTimeout => 'El nodo no respondió a tiempo.';

  @override
  String errProtocol(String detail) {
    return 'Error de protocolo: $detail';
  }

  @override
  String errVersion(int node, int ours) {
    return 'El nodo usa el protocolo $node; este cliente usa el protocolo $ours.';
  }

  @override
  String errSyncFailed(String cause) {
    return 'Falló la sincronización: $cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return 'Se ignoró un bloque retransmitido: $detail';
  }

  @override
  String get probFeeTooLow => 'La comisión debe ser al menos 1.';

  @override
  String get probMalformed => 'Esta transacción no está bien formada.';

  @override
  String get probNeedsMessage => 'Escribe un mensaje.';

  @override
  String get probNeedsRecipient => 'Indica un destinatario.';

  @override
  String probAmountBelowFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'La cantidad debe ser al menos la comisión ($feeString).';
  }

  @override
  String get probReplyParentNotMined =>
      'Solo puedes responder a un hilo o respuesta que ya esté en un bloque.';

  @override
  String get probReplyWrongRecipient =>
      'Una respuesta debe pagar al autor del mensaje al que responde.';

  @override
  String get probFlagNotMessage =>
      'Solo se pueden denunciar hilos y respuestas.';

  @override
  String get probAlreadyFlagged => 'Esta cartera ya denunció ese mensaje.';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'El mensaje ocupa $lengthString bytes; el límite es $limitString.';
  }

  @override
  String probInsufficientBalance(int needed, int available) {
    final intl.NumberFormat neededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String neededString = neededNumberFormat.format(needed);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return 'Saldo insuficiente: se necesitan $neededString y hay $availableString disponibles (saldo confirmado menos transacciones pendientes).';
  }

  @override
  String get probNotLive =>
      'Espera a que el cliente esté conectado y sincronizado.';

  @override
  String get probConnectionLost => 'Se perdió la conexión con el nodo.';

  @override
  String get probDuplicate =>
      'Ya se envió una transacción idéntica en este mismo segundo.';

  @override
  String get tabThreads => 'Hilos';

  @override
  String get tabMessages => 'Mensajes';

  @override
  String get tabWallet => 'Cartera';

  @override
  String get tabChain => 'Cadena';

  @override
  String get newThread => 'Nuevo hilo';

  @override
  String get createWalletFirst => 'Primero crea o importa una cartera.';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get changeNode => 'Cambiar de nodo';

  @override
  String get unknownNetwork =>
      'Este nodo está en una red que el cliente no reconoce. No se pueden comprobar sus ajustes de dificultad, y las recompensas de bloque se calculan con los valores del whitepaper, así que los saldos de los mineros pueden no ser exactos.';

  @override
  String get linkOffline => 'Sin conexión';

  @override
  String get linkConnecting => 'Conectando…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return 'Sincronizando $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'En directo · $heightString';
  }

  @override
  String get connectToNode => 'Conectar a un nodo';

  @override
  String nodeAt(String address) {
    return 'Nodo $address';
  }

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma del sistema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get node => 'Nodo';

  @override
  String get connectHelpBridge =>
      'En el navegador, el cliente se conecta por WebSocket: a la dirección WebSocket de un nodo (como node.murmur.info, puerto 443, con TLS) o a un puente local (dart run tool/ws_bridge.dart, puerto 7880).';

  @override
  String get connectHelpNative =>
      'La dirección peer-to-peer de un murmur-node (su --port, 7878 por defecto). El puerto de control (7879) no funcionará.';

  @override
  String get host => 'Host';

  @override
  String get port => 'Puerto';

  @override
  String get required => 'Obligatorio';

  @override
  String get enterPort => 'Indica un número de puerto';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get connect => 'Conectar';

  @override
  String get syncingChain => 'Sincronizando la cadena…';

  @override
  String get noThreads => 'Aún no hay hilos. Empieza uno con Nuevo hilo.';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Según el bloque $heightString ($time, $elapsed)';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bloques nuevos desde entonces',
      one: '1 bloque nuevo desde entonces',
      zero: 'al día',
    );
    return '$_temp0';
  }

  @override
  String agoSeconds(int s) {
    return 'hace $s s';
  }

  @override
  String agoMinutes(int m, int s) {
    return 'hace $m min $s s';
  }

  @override
  String agoHours(int h, int m) {
    return 'hace $h h $m min';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return 'hace $dString d $h h';
  }

  @override
  String get refresh => 'Actualizar';

  @override
  String threadStarted(String time) {
    return 'iniciado $time';
  }

  @override
  String threadLastReply(String time) {
    return 'última respuesta $time';
  }

  @override
  String get messagesNeedWallet =>
      'Crea o importa una cartera en la pestaña Cartera para ver tus mensajes.';

  @override
  String get noMessages => 'Ningún mensaje coincide con estos filtros.';

  @override
  String get filterThreads => 'Mis hilos';

  @override
  String get filterRepliesSent => 'Respuestas enviadas';

  @override
  String get filterRepliesReceived => 'Respuestas recibidas';

  @override
  String get filterFlagsSent => 'Denuncias hechas';

  @override
  String get filterFlagsReceived => 'Denuncias recibidas';

  @override
  String get balance => 'Saldo';

  @override
  String pendingCommitted(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString comprometidos en transacciones pendientes';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bloques minados',
      one: '1 bloque minado',
      zero: 'Ningún bloque minado',
    );
    return '$_temp0';
  }

  @override
  String get address => 'Dirección';

  @override
  String get showSeed => 'Ver semilla';

  @override
  String get removeWallet => 'Quitar cartera';

  @override
  String get history => 'Historial';

  @override
  String get filters => 'Filtros';

  @override
  String get noHistory => 'Ninguna transacción coincide con estos filtros.';

  @override
  String get walletFilterTransfersSent => 'Transferencias enviadas';

  @override
  String get walletFilterTransfersReceived => 'Transferencias recibidas';

  @override
  String get walletFilterRepliesPaid => 'Pagado por responder';

  @override
  String get walletFilterRepliesEarned => 'Ganado con respuestas';

  @override
  String get walletFilterThreadCosts => 'Coste de hilos';

  @override
  String get walletFilterFlagCosts => 'Comisiones de denuncias';

  @override
  String get seedTitle => 'Semilla de la cartera';

  @override
  String get seedWarning =>
      'Cualquiera que tenga esta semilla puede gastar esta cartera. Tiene el mismo formato que un archivo de clave creado con murmur-node keygen.';

  @override
  String get done => 'Hecho';

  @override
  String get removeWalletTitle => '¿Quitar la cartera?';

  @override
  String get removeWalletBody =>
      'La semilla se borrará de este dispositivo. Sin una copia, cualquier saldo de esta dirección se pierde.';

  @override
  String get remove => 'Quitar';

  @override
  String get importWallet => 'Importar cartera';

  @override
  String get importHelp =>
      'Escribe o pega la semilla de una cartera: sus 24 palabras o sus 64 caracteres hexadecimales (por ejemplo el contenido de un archivo de clave creado con murmur-node keygen, murmur.key, para usar las recompensas minadas a su dirección).';

  @override
  String get seed => 'Semilla';

  @override
  String get import => 'Importar';

  @override
  String get seedInvalid =>
      'Una semilla son 24 palabras o exactamente 64 caracteres hexadecimales.';

  @override
  String get walletIntro =>
      'Una cartera firma las transacciones que envías. Su clave se queda en este dispositivo.';

  @override
  String get createWallet => 'Crear cartera nueva';

  @override
  String get importSeed => 'Importar semilla';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return 'No hay bloque a la altura $heightString (la punta es $tipString).';
  }

  @override
  String get searchInvalid =>
      'Indica una altura de bloque, o un txid, hash de bloque o dirección de 64 caracteres.';

  @override
  String get searchHint => 'Buscar altura, txid, hash de bloque o dirección';

  @override
  String get noBlocks => 'Aún no hay bloques.';

  @override
  String blockTitle(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Bloque $heightString';
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
    return 'minero $miner';
  }

  @override
  String get statNetwork => 'Red';

  @override
  String get statHeight => 'Altura';

  @override
  String get statNodeHeight => 'Altura del nodo';

  @override
  String get statNextReward => 'Recompensa del próximo bloque';

  @override
  String rewardPlusFees(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString + comisiones';
  }

  @override
  String get statBurnPool => 'Fondo quemado';

  @override
  String get statCirculating => 'En circulación';

  @override
  String get tip => 'Punta';

  @override
  String get previousBlock => 'Bloque anterior';

  @override
  String get nextBlock => 'Bloque siguiente';

  @override
  String get blockGone => 'Este bloque ya no está en la mejor cadena.';

  @override
  String get hash => 'Hash';

  @override
  String get previous => 'Anterior';

  @override
  String get time => 'Hora';

  @override
  String get confirmations => 'Confirmaciones';

  @override
  String get miner => 'Minero';

  @override
  String get reward => 'Recompensa';

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

    return '$subsidyString de subsidio + $payoutString del fondo quemado + $feesString de comisiones';
  }

  @override
  String get merkleRoot => 'Raíz de Merkle';

  @override
  String get target => 'Objetivo';

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
      other: '$countString transacciones',
      one: '1 transacción',
      zero: 'Sin transacciones',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => 'Tu dirección';

  @override
  String get noTransactions => 'Sin transacciones.';

  @override
  String get sendToAddress => 'Enviar a esta dirección';

  @override
  String get threadGone => 'Este hilo ya no está en la cadena.';

  @override
  String paidToParent(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'pagó $amountString al autor del mensaje original';
  }

  @override
  String get actionReply => 'Responder';

  @override
  String get actionFlag => 'Denunciar';

  @override
  String get flagged => 'Denunciado';

  @override
  String get details => 'Detalles';

  @override
  String get txTitle => 'Transacción';

  @override
  String get txNotFound =>
      'No se encontró la transacción. Puede que se haya descartado de las pendientes o que una reorganización la haya quitado.';

  @override
  String refNotLocal(String txid) {
    return 'Transacción $txid (no está en la cadena local)';
  }

  @override
  String get flaggedMessage => 'Mensaje denunciado';

  @override
  String get inReplyTo => 'En respuesta a';

  @override
  String get notThreadedExplain =>
      'Nombra este mensaje, pero no forma parte de su hilo: el mensaje debe ser un hilo o respuesta minado, y esta respuesta debe pagar a su autor. Solo cuenta como un pago.';

  @override
  String get message => 'Mensaje';

  @override
  String get openThread => 'Abrir hilo';

  @override
  String get transactionId => 'ID de transacción';

  @override
  String get type => 'Tipo';

  @override
  String get from => 'De';

  @override
  String get to => 'Para';

  @override
  String get burned => 'Quemado';

  @override
  String burnedValue(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString (vuelve a los mineros a través del fondo quemado)';
  }

  @override
  String get amount => 'Cantidad';

  @override
  String get fee => 'Comisión';

  @override
  String get signedAt => 'Firmada el';

  @override
  String get contentHash => 'Hash del contenido';

  @override
  String get contentSize => 'Tamaño del contenido';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString bytes (una sal de $salt bytes y un mensaje de $messageString bytes)';
  }

  @override
  String get reports => 'Denuncia';

  @override
  String get repliesTo => 'Responde a';

  @override
  String get weight => 'Peso';

  @override
  String weightValue(int weight, String perByte) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString bytes ($perByte de comisión por byte)';
  }

  @override
  String get publicKey => 'Clave pública';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Confirmada en el bloque $heightString';
  }

  @override
  String confirmationCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString confirmaciones',
      one: '1 confirmación',
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
      other: 'Sin confirmar tras $countString bloques',
      one: 'Sin confirmar tras 1 bloque',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused =>
      'Puede que el nodo la haya rechazado (por ejemplo, si el saldo cambió antes de minarla). El nodo no avisa de las transacciones rechazadas.';

  @override
  String get sentWaiting => 'Enviada, esperando un bloque';

  @override
  String get submittedHere => 'Enviada desde este dispositivo.';

  @override
  String get pendingTitle => 'Pendiente';

  @override
  String get relayedPending =>
      'Retransmitida por el nodo, aún no está en un bloque.';

  @override
  String get viewBlock => 'Ver bloque';

  @override
  String get newTransaction => 'Nueva transacción';

  @override
  String get flagMessage => 'Denunciar mensaje';

  @override
  String flaggingInfo(String author) {
    return 'Vas a denunciar este mensaje de $author. Cada cartera puede denunciar un mensaje una sola vez. Cada cliente decide qué hacer con las denuncias.';
  }

  @override
  String replyingTo(String author) {
    return 'Respondiendo a $author';
  }

  @override
  String explainThread(int total, int burn) {
    return 'Empieza un hilo nuevo. Cuesta $total × la comisión: la comisión va al minero y se queman $burn × la comisión. Lo quemado vuelve a los mineros en los bloques siguientes.';
  }

  @override
  String get explainReply =>
      'Tu respuesta paga al autor del mensaje al menos la comisión (puedes dar más de propina), más la comisión para el minero.';

  @override
  String get explainTransfer =>
      'Una transferencia de tokens sin mensaje. La cantidad debe ser al menos la comisión.';

  @override
  String get recipientAddress => 'Dirección del destinatario';

  @override
  String get enterAddress =>
      'Indica una dirección hexadecimal de 64 caracteres';

  @override
  String get payToAuthor => 'Pagar al autor';

  @override
  String get wholeNumber => 'Número entero';

  @override
  String atLeastFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Al menos la comisión ($feeString)';
  }

  @override
  String get feeToMiner => 'Comisión (para el minero)';

  @override
  String suggestedFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'Sugerida: $feeString';
  }

  @override
  String get atLeastOne => 'Al menos 1';

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

    return 'Demasiado largo: $countString bytes';
  }

  @override
  String get sendingNeedsLive =>
      'Podrás enviar cuando el cliente esté conectado y sincronizado.';

  @override
  String get signAndSend => 'Firmar y enviar';

  @override
  String get costFee => 'Comisión, para el minero';

  @override
  String costBurn(int multiple) {
    return 'Quemado: $multiple × la comisión';
  }

  @override
  String get costPaid => 'Pagado al destinatario';

  @override
  String get costTotal => 'Coste total';

  @override
  String get costAvailable =>
      'Disponible: saldo menos transacciones pendientes';

  @override
  String get costRemaining => 'Lo que queda tras enviar';

  @override
  String get checkingFees => 'Consultando las comisiones de la red…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Estimada a partir de lo que ha visto este cliente ($countString pendientes desde que se conectó); el informe de comisiones del nodo no estaba disponible.';
  }

  @override
  String get use => 'Usar';

  @override
  String get checkAgain => 'Volver a consultar';

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

    return 'Saldo: $beforeString antes, $afterString después';
  }

  @override
  String chainCounted(int counted, int total) {
    final intl.NumberFormat countedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countedString = countedNumberFormat.format(counted);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$countedString de $totalString bloques contados';
  }

  @override
  String get loadingOlder => 'Cargando bloques anteriores…';

  @override
  String get blockLoading => 'Cargando este bloque…';

  @override
  String get txSearching =>
      'Buscando esta transacción en los bloques que aún se están cargando…';

  @override
  String get storageBanner =>
      '¿Guardar una copia de la cadena en este dispositivo? Así las próximas visitas se abren en segundos en lugar de descargarlo todo de nuevo. Se queda aquí y nunca se envía a nadie: sin cookies ni rastreo. La clave de tu cartera y tus ajustes siempre se guardan en este dispositivo, porque la aplicación los necesita para funcionar.';

  @override
  String get storageAllow => 'Permitir el almacenamiento necesario';

  @override
  String get storageReject => 'Rechazar (más lento)';

  @override
  String get storageOn => 'Copia local de la cadena: activada';

  @override
  String get storageOff =>
      'Copia local de la cadena: desactivada (cada visita la descarga de nuevo)';

  @override
  String get storageTurnOn => 'Activar';

  @override
  String get storageTurnOff => 'Desactivar y borrar';

  @override
  String get checkingBalance => 'Comprobando con el nodo…';

  @override
  String get errTampered =>
      'La conexión se alteró o se cortó: un mensaje no superó su comprobación de integridad.';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'El estado que el nodo compromete en el bloque $heightString no coincide con el recuento de la cadena de este cliente. No te fíes de este nodo: conéctate a otro.';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Según el nodo: $countString transacciones pendientes.',
      one: 'Según el nodo: 1 transacción pendiente.',
      zero: 'Según el nodo: nada pendiente.',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => 'El nodo la aceptó y la retransmitió.';

  @override
  String get statusRefused => 'Rechazada por el nodo';

  @override
  String get statusInvalid => 'Rechazada por no ser válida';

  @override
  String nodeReason(String reason) {
    return 'El nodo dice: $reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'La cadena no lleva al punto de control de esta versión en el bloque $heightString: o la versión o todos los nodos alcanzados están mal. Detenido; no se puede confiar en nada de ella.';
  }

  @override
  String staleTip(String elapsed) {
    return 'El bloque más reciente es de $elapsed: puede que este nodo vaya retrasado o esté aislado de la red. Lo que ves puede no estar al día.';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return 'Se empezó desde el punto de control en el bloque $heightString; comprobando las cabeceras hasta el génesis ($doneString de momento).';
  }

  @override
  String get licenses => 'Licencias';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => 'Red de pruebas: los tokens no tienen valor';

  @override
  String get linkNodeRepo => 'Código del nodo y del protocolo';

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

    return 'Comprobando las cabeceras de bloque: $doneString de $totalString';
  }

  @override
  String reconnectingIn(int seconds) {
    return 'Nuevo intento en $seconds s.';
  }

  @override
  String get languagesFilter => 'Idiomas';

  @override
  String get languageUndetected => 'Sin detectar';

  @override
  String get hideFlaggedThreads => 'Ocultar los hilos que he denunciado';

  @override
  String get star => 'Destacar';

  @override
  String get unstar => 'Quitar destacado';

  @override
  String get starredOnly => 'Solo hilos destacados';

  @override
  String get localNodeRun => 'Ejecutar un nodo de Murmur en este ordenador';

  @override
  String get localNodeExplain =>
      'Tu ordenador comprueba la cadena por sí mismo, ayuda a difundirla y mantiene disponibles tus propios mensajes. No guarda mensajes de nadie más pasada la comprobación de una hora.';

  @override
  String get localNodeStarting => 'Iniciando el nodo…';

  @override
  String get localNodeRunning => 'El nodo está en marcha y la app lo usa.';

  @override
  String localNodeFailed(String reason) {
    return 'El nodo se detuvo: $reason';
  }

  @override
  String get localNodeFailedUnknown => 'El nodo se detuvo inesperadamente.';

  @override
  String get localNodeMine => 'Minar con este ordenador';

  @override
  String get localNodeMineNote =>
      'La minería paga a la dirección de tu cartera, consume electricidad y hace trabajar más a tu ordenador. En la testnet, los tokens son solo para pruebas.';

  @override
  String get localNodeMineNeedsWallet =>
      'Crea primero una cartera: la minería paga a su dirección.';

  @override
  String localNodeCpu(int pct) {
    return 'Hasta un $pct % de un núcleo del procesador';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hilos ocultos',
      one: '1 hilo oculto',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => 'Buscar en los hilos cargados';

  @override
  String get noMatches => 'Ningún hilo cargado coincide.';

  @override
  String get timeJustNow => 'ahora mismo';

  @override
  String timeMinutesAgo(int n) {
    return 'hace $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'hace $n h';
  }

  @override
  String timeDaysAgo(int n) {
    return 'hace $n d';
  }

  @override
  String get nameAddress => 'Nombre';

  @override
  String get aliasTitle => 'Poner nombre a esta dirección';

  @override
  String get aliasHelp =>
      'El nombre solo se guarda en este dispositivo. Déjalo vacío para quitarlo.';

  @override
  String get save => 'Guardar';

  @override
  String get mute => 'Silenciar';

  @override
  String get unmute => 'Dejar de silenciar';

  @override
  String get mutedNote =>
      'Silenciada: sus hilos y respuestas se ocultan en este dispositivo.';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas de direcciones silenciadas ocultas',
      one: '1 respuesta de una dirección silenciada oculta',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas nuevas',
      one: '1 respuesta nueva',
    );
    return '$_temp0';
  }

  @override
  String get invitations => 'Invitaciones';

  @override
  String get createInvitations => 'Crear invitaciones';

  @override
  String get inviteHowMany => 'Cuántas tarjetas';

  @override
  String get inviteFund => 'Financiar las tarjetas';

  @override
  String get inviteCardTitle => 'Invitación a Murmur';

  @override
  String inviteCardSerial(int n, int total) {
    return '$n de $total';
  }

  @override
  String inviteCardFrom(String name) {
    return 'De $name';
  }

  @override
  String get inviteCardHow =>
      'Escanea el código o abre el enlace para unirte a Murmur.';

  @override
  String get inviteClaimed => 'Canjeada';

  @override
  String get inviteChecking => 'Comprobando…';

  @override
  String get claimTitle => 'Te han invitado';

  @override
  String claimInvitedBy(String name) {
    return 'Invitación de $name';
  }

  @override
  String claimHolds(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'Esta invitación lleva $amountString: suficiente para tus primeros hilos.';
  }

  @override
  String get claimCreateWallet => 'Crear mi cartera y canjear';

  @override
  String get claimIntoWallet => 'Canjear en mi cartera';

  @override
  String get claimDone =>
      'Canjeada. Los tokens llegan a tu cartera con el próximo bloque.';

  @override
  String get claimEmpty => 'Esta invitación ya se ha canjeado o recuperado.';

  @override
  String get claimWrongNetwork =>
      'Esta invitación es de otra red que la del nodo al que estás conectado.';

  @override
  String get claimInvalid => 'Ese no es un código de invitación válido.';

  @override
  String get haveInvitation => 'Tengo una invitación';

  @override
  String get inviteCodeField => 'Código o enlace de invitación';

  @override
  String get claim => 'Canjear';

  @override
  String get cancelInvitation => 'Cancelar invitación';

  @override
  String get inviteCancelled => 'Cancelada';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Cancelar $count invitaciones?',
      one: '¿Cancelar esta invitación?',
    );
    return '$_temp0';
  }

  @override
  String cancelInviteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Sus tokens vuelven, y quien tenga las tarjetas ya no podrá canjearlas.',
      one:
          'Sus tokens vuelven, y quien tenga la tarjeta ya no podrá canjearla.',
    );
    return '$_temp0';
  }

  @override
  String get keepInvitation => 'Mantenerla';

  @override
  String get printOne => 'Imprimir';

  @override
  String inviteDoneSection(int count) {
    return 'Canjeadas o canceladas ($count)';
  }

  @override
  String get inviteEachLabel => 'Cada tarjeta';

  @override
  String get inviteEachCaption =>
      'Cinco hilos con la comisión de hoy, más la comisión para canjearla.';

  @override
  String get inviteTotalLabel => 'Pagas';

  @override
  String get inviteTotalCaption => 'En total, comisiones incluidas.';

  @override
  String get inviteWaitingState => 'Pendiente de canjear';

  @override
  String get inviteCardSlogan => 'Tu voz tiene un sitio aquí.';

  @override
  String get inviteCardJoin => 'Escanea para unirte';

  @override
  String get share => 'Compartir…';

  @override
  String get inviteDetailFunded => 'Financiada';

  @override
  String get inviteDetailClaimedBy => 'Canjeada por';

  @override
  String get inviteDetailReceived => 'Recibido';

  @override
  String get inviteDetailCancelled =>
      'Cancelada: los tokens volvieron a tu cartera';

  @override
  String get inviteDetailReturned => 'Devuelto';

  @override
  String get inviteDetailOnItsWay => 'De camino a un bloque';

  @override
  String get seedConfirmTitle => '¿Mostrar tu semilla?';

  @override
  String get seedConfirmBody =>
      'Quien vea la semilla puede gastar de esta cartera. Asegúrate de que nadie más ve tu pantalla.';

  @override
  String get showAction => 'Mostrar';

  @override
  String get authReasonSeed => 'Confirma que eres tú para ver la semilla';

  @override
  String get authReasonRemove =>
      'Confirma que eres tú para quitar esta cartera';

  @override
  String get authFailed => 'Sin confirmar: no se ha mostrado ni cambiado nada.';

  @override
  String get passphraseNewTitle => 'Elige una frase de paso';

  @override
  String get passphraseNewBody =>
      'Cifra la clave de tu cartera en este dispositivo. La escribirás para enviar, mostrar la semilla o quitar la cartera. Si la olvidas, solo tu copia de la semilla podrá recuperar la cartera.';

  @override
  String get passphraseField => 'Frase de paso';

  @override
  String get passphraseRepeat => 'Repite la frase de paso';

  @override
  String passphraseTooShort(int min) {
    return 'Al menos $min caracteres';
  }

  @override
  String get passphraseMismatch => 'No coinciden';

  @override
  String get passphraseTitle => 'Frase de paso';

  @override
  String get wrongPassphrase =>
      'Frase de paso incorrecta: no se ha mostrado ni enviado nada.';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get authReasonSend => 'Confirma que eres tú para firmar y enviar';

  @override
  String get authReasonNewWallet =>
      'Protege la clave de tu cartera en este dispositivo';

  @override
  String get authReasonInvite =>
      'Confirma que eres tú para financiar las tarjetas';

  @override
  String get removeAnywayTitle => '¿Quitar sin confirmar?';

  @override
  String get removeAnywayBody =>
      'No se ha podido desbloquear la cartera. Quitarla borra su clave de este dispositivo: solo tu copia de la semilla podrá recuperarla.';

  @override
  String get protectionDevice =>
      'Clave cifrada con el bloqueo de este dispositivo';

  @override
  String get protectionPasskey =>
      'Clave cifrada con una llave de acceso de este dispositivo';

  @override
  String get protectionPassphrase => 'Clave cifrada con tu frase de contraseña';

  @override
  String get protectionLegacy =>
      'Clave aún sin cifrar: se cifrará en el próximo desbloqueo';

  @override
  String get confirmSendTitle => 'Revisa antes de firmar';

  @override
  String get confirmSendFinal =>
      'Al firmar, esto se envía al nodo. No se puede deshacer: una vez minado, queda en la cadena.';

  @override
  String signAndSendShortcut(String keys) {
    return 'Firmar y enviar ($keys)';
  }

  @override
  String get threadWithdrawnMine =>
      'Lo retiraste: oculto para los demás, y su texto borrado de las apps de Murmur';

  @override
  String get threadWithdrawnMineNote =>
      'Denunciaste tu propio hilo, y eso lo retira. Las apps de Murmur ya no lo muestran a los demás y borran su texto, también en este dispositivo; los nodos pueden dejar de guardar su texto y sus respuestas.';

  @override
  String get threadWithdrawnNote =>
      'Su autor denunció este hilo, y eso lo retira. Las apps de Murmur ya no lo listan y borran su texto, y los nodos pueden dejar de guardar su texto y sus respuestas.';

  @override
  String get flagOwnInfo =>
      'Este mensaje es tuyo. Denunciarlo lo retira: las apps de Murmur dejan de mostrarlo a los demás y borran su texto, también en este dispositivo, y los nodos pueden dejar de guardar su texto y sus respuestas. No se puede deshacer.';

  @override
  String get inviteFromTitle => 'Nombre en las tarjetas';

  @override
  String get inviteFromBody =>
      'Cada tarjeta dice de quién es. Las financió la cartera que invita, que puede no ser la de este dispositivo ahora.';

  @override
  String get inviteFromOriginal => 'Dirección de la cartera que invita';

  @override
  String get inviteFromOriginalAlias => 'Tu nombre para la cartera que invita';

  @override
  String get inviteFromOriginalPublic =>
      'Nombre público de la cartera que invita';

  @override
  String get inviteFromCurrent => 'Dirección de esta cartera';

  @override
  String get inviteFromCurrentAlias => 'Tu nombre para esta cartera';

  @override
  String get inviteFromCurrentPublic => 'Nombre público de esta cartera';

  @override
  String get inviteFromCustom => 'Otro texto';

  @override
  String get inviteFromCustomHint =>
      'Déjalo vacío para no imprimir ningún nombre';

  @override
  String get inviteFromNotSet => 'Sin nombre en este dispositivo';

  @override
  String get inviteFromMixed => 'Es distinto entre las tarjetas elegidas';

  @override
  String get inviteFromChecking => 'Aún se está buscando en la cadena';

  @override
  String get cancelReturnTo => 'Enviar los tokens a';

  @override
  String get cancelToFunder => 'La cartera que la financió';

  @override
  String get cancelToCurrent => 'Esta cartera';

  @override
  String get publicName => 'Nombre público';

  @override
  String get publicNameNone => 'Ninguno conocido';

  @override
  String get publicNameSet => 'Poner nombre público';

  @override
  String get publicNameField => 'Nombre';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return 'Como máximo $maxString bytes';
  }

  @override
  String get aliasBadCharacter =>
      'No se permiten caracteres invisibles ni de control';

  @override
  String get aliasEdgeSpace => 'Sin espacios al principio ni al final';

  @override
  String aliasSetTo(String name) {
    return 'Nombre público: $name';
  }

  @override
  String get aliasCleared => 'Nombre público quitado';

  @override
  String get nonTextMessage => '(no es texto: datos de una convención de apps)';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return 'Publica tu nombre público. Como un hilo nuevo, cuesta $totalString × la comisión: la comisión va al minero y se queman $burnString × la comisión.';
  }

  @override
  String get inviteFromNoPublic => 'Sin nombre público conocido';

  @override
  String get starredTitle => 'Destacados';

  @override
  String get noStarred =>
      'Aún no has destacado nada. Destaca un hilo o un mensaje desde su página y aparecerá aquí.';

  @override
  String get starredGone => 'Ya no está en la cadena';

  @override
  String get feeSuggestedLabel => 'Comisión sugerida';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return 'por $weightString bytes';
  }

  @override
  String get feeRoom => 'Los bloques tienen sitio';

  @override
  String get feeFull => 'Los bloques están llenos';

  @override
  String get feeNextBlock => 'Próximo bloque';

  @override
  String get feePoolEntry => 'Para entrar en la cola';

  @override
  String get feeMinimum => 'Mínimo';

  @override
  String get feeWhy => 'Por qué esta comisión';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**La comisión es por byte**: $baseString bytes más tu mensaje. Los mensajes largos cuestan más cuando los bloques están llenos.';
  }

  @override
  String feeRecentPoint(int lowest, int median) {
    final intl.NumberFormat lowestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lowestString = lowestNumberFormat.format(lowest);
    final intl.NumberFormat medianNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String medianString = medianNumberFormat.format(median);

    return '**Los bloques recientes** aceptaron comisiones de solo **$lowestString** (mediana $medianString).';
  }

  @override
  String get feeRecentNonePoint =>
      '**Los bloques recientes** no tenían transacciones.';

  @override
  String get inviteNoExpiryPoint =>
      '**No caduca**: una tarjeta sirve hasta que alguien la reclama.';

  @override
  String get inviteCancelPoint =>
      '**Cancela cuando quieras**: sus tokens vuelven.';

  @override
  String get invitePublicPoint =>
      '**Es público**: la cadena muestra que financiaste cada tarjeta y qué cartera la reclamó.';

  @override
  String get inviteCashPoint =>
      '**Quien tenga el código** puede reclamar la tarjeta. Guárdalas en privado hasta entregarlas.';

  @override
  String get inviteLocalPoint =>
      '**Se guardan solo en este dispositivo.** Si se borran sus datos o se elimina la app, los códigos **se pierden para siempre**, y también los tokens de las tarjetas aún no entregadas.';

  @override
  String get publicNameIntro =>
      'Tu nombre público aparece **junto a tu dirección** en las apps de Murmur.';

  @override
  String publicNameShownAs(String name) {
    return 'Se verá como **$name**';
  }

  @override
  String get publicNameNotUnique =>
      '**No es único**: cualquiera puede elegir el mismo nombre. La dirección que lo acompaña distingue a cada uno.';

  @override
  String get publicNameCost =>
      '**Cuesta lo mismo que un hilo nuevo**, cada vez que lo pones o lo cambias.';

  @override
  String get publicNameRemovable =>
      '**Es un mensaje en la cadena**: cualquier nodo puede borrarlo, y entonces desaparece.';

  @override
  String get publicNameClear => '**Déjalo vacío** para quitarlo.';

  @override
  String get passkeyNoPrfTitle =>
      'Este gestor de llaves de acceso no puede proteger la cartera';

  @override
  String get passkeyNoPrfWhy =>
      '**No puede cifrar.** Para bloquear la clave de tu cartera, el gestor tiene que derivar una clave de la llave de acceso (WebAuthn PRF). El que elegiste no lo hace.';

  @override
  String get passkeyNoPrfTry =>
      '**Prueba otro gestor**, como Contraseñas de Apple o el Gestor de contraseñas de Google, o protege la cartera con una **frase de contraseña**.';

  @override
  String get passkeyNoPrfLeftover =>
      'La llave de acceso que acaba de guardar (**Murmur wallet**) no desbloquea nada: puedes borrarla de ese gestor.';

  @override
  String get passkeyTryAnother => 'Probar otro gestor';

  @override
  String get passkeyUsePassphrase => 'Usar una frase de contraseña';

  @override
  String inviteDetailCancelledTo(String name) {
    return 'Cancelada: los tokens fueron a $name';
  }

  @override
  String get seedNewTitle => 'Guarda la semilla de tu cartera';

  @override
  String get seedNewKeep =>
      '**Guárdala en un lugar seguro**, fuera de este dispositivo: escrita en papel o en un gestor de contraseñas.';

  @override
  String get seedNewOnlyWay =>
      'Es la **única forma de volver** a esta cartera si pierdes este dispositivo u olvidas su frase de contraseña. Nadie puede recuperarla por ti.';

  @override
  String get seedNewSecret =>
      '**Quien la tenga controla la cartera.** No la compartas nunca ni la escribas en un sitio que te la pida.';

  @override
  String get seedNewSaved => 'He guardado mi semilla';

  @override
  String get seedAsWords => 'En 24 palabras';

  @override
  String get seedAsHex => 'En 64 caracteres';

  @override
  String get seedEitherForm => 'Las dos son la misma semilla: basta con una.';

  @override
  String get copyWords => 'Copiar palabras';

  @override
  String get copyCharacters => 'Copiar caracteres';

  @override
  String get seedOrWords => 'Semilla: 24 palabras o 64 caracteres';

  @override
  String seedUnknownWord(String word) {
    return '«$word» no es una de las palabras de semilla. Revisa cómo está escrita.';
  }

  @override
  String get seedBadChecksum =>
      'Estas 24 palabras no forman una semilla: alguna es incorrecta o está fuera de lugar.';
}
