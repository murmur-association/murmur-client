// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => 'Tópico';

  @override
  String get kindReply => 'Resposta';

  @override
  String get kindTransfer => 'Transferência';

  @override
  String get kindFlag => 'Denúncia';

  @override
  String get contentUnavailable => '(conteúdo indisponível: o nó não o tem)';

  @override
  String get contentWithdrawn => '(retirado pelo autor)';

  @override
  String get contentLoading => '(a carregar a mensagem…)';

  @override
  String get pending => 'pendente';

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
      other: '$countString respostas',
      one: '1 resposta',
      zero: 'Sem respostas',
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
      other: '$countString denúncias',
      one: '1 denúncia',
      zero: 'Sem denúncias',
    );
    return '$_temp0';
  }

  @override
  String transferOf(String amount) {
    return 'Transferência de $amount';
  }

  @override
  String flagOn(String text) {
    return 'Denúncia de “$text”';
  }

  @override
  String flagOnTx(String txid) {
    return 'Denúncia de $txid';
  }

  @override
  String get replyNotThreaded => 'Resposta (fora de um tópico)';

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
    return 'Não foi possível contactar o nó: $detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return 'Não foi possível contactar a ponte WebSocket em $url. Inicie-a com: dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return 'Erro de conexão: $detail';
  }

  @override
  String get errClosed => 'O nó encerrou a conexão.';

  @override
  String get errTimeout => 'O nó não respondeu a tempo.';

  @override
  String errProtocol(String detail) {
    return 'Erro de protocolo: $detail';
  }

  @override
  String errVersion(int node, int ours) {
    return 'O nó usa o protocolo $node; este cliente usa o protocolo $ours.';
  }

  @override
  String get errAppOutdated =>
      'A rede passou a usar um protocolo mais recente do que esta aplicação. Atualize a aplicação para continuar a usá-la.';

  @override
  String get errAppOutdatedWeb =>
      'A rede passou a usar um protocolo mais recente do que esta página. Recarregue a página para obter a nova versão.';

  @override
  String get errAppOutdatedSystem =>
      'A rede passou a usar um protocolo mais recente do que esta aplicação. Atualize-a através das atualizações de software do seu sistema.';

  @override
  String get getNewVersion => 'Obter a nova versão';

  @override
  String get appMaybeOld =>
      'Esta versão da aplicação tem **mais de um mês**: provavelmente existe uma mais recente.';

  @override
  String get appMaybeOldSystem =>
      'Esta versão da aplicação tem **mais de um mês**: as atualizações de software do seu sistema provavelmente têm uma mais recente.';

  @override
  String get localNodeOutdated =>
      'A rede passou a usar um **protocolo mais recente**: este nó só a poderá seguir depois de a aplicação ser atualizada.';

  @override
  String get localNodeOutdatedSystem =>
      'A rede passou a usar um **protocolo mais recente**: este nó só a poderá seguir depois de a aplicação ser atualizada através das atualizações de software do seu sistema.';

  @override
  String errSyncFailed(String cause) {
    return 'A sincronização falhou: $cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return 'Um bloco retransmitido foi ignorado: $detail';
  }

  @override
  String get probFeeTooLow => 'A taxa está abaixo do mínimo da rede.';

  @override
  String get probMalformed => 'Esta transação não está bem formada.';

  @override
  String get probNeedsMessage => 'Escreva uma mensagem.';

  @override
  String get probNeedsRecipient => 'Indique um destinatário.';

  @override
  String probAmountBelowFee(String fee) {
    return 'O valor tem de ser pelo menos a taxa ($fee).';
  }

  @override
  String get probReplyParentNotMined =>
      'Só é possível responder a um tópico ou resposta que já esteja num bloco.';

  @override
  String get probFlagNotMessage =>
      'Só é possível denunciar tópicos e respostas.';

  @override
  String get probAlreadyFlagged => 'Esta carteira já denunciou essa mensagem.';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'A mensagem tem $lengthString bytes; o limite é $limitString.';
  }

  @override
  String probInsufficientBalance(String needed, String available) {
    return 'Saldo insuficiente: são precisos $needed e há $available disponíveis (saldo confirmado menos transações pendentes).';
  }

  @override
  String get probNotLive =>
      'Aguarde até o cliente estar conectado e sincronizado.';

  @override
  String get probConnectionLost => 'A conexão com o nó foi perdida.';

  @override
  String get probDuplicate =>
      'Uma transação idêntica já foi enviada neste mesmo segundo.';

  @override
  String get tabThreads => 'Tópicos';

  @override
  String get tabMessages => 'Mensagens';

  @override
  String get tabWallet => 'Carteira';

  @override
  String get tabChain => 'Cadeia';

  @override
  String get newThread => 'Novo tópico';

  @override
  String get createWalletFirst => 'Primeiro crie ou importe uma carteira.';

  @override
  String get syncNow => 'Sincronizar agora';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get changeNode => 'Mudar de nó';

  @override
  String get unknownNetwork =>
      'Este nó está numa rede que o cliente não reconhece. Não é possível verificar os seus ajustes de dificuldade, e as recompensas dos blocos são calculadas com os valores do whitepaper, por isso os saldos dos mineradores podem não estar certos.';

  @override
  String get linkOffline => 'Offline';

  @override
  String get linkConnecting => 'A conectar…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return 'A sincronizar $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Ao vivo · $heightString';
  }

  @override
  String get connectToNode => 'Conectar a um nó';

  @override
  String nodeAt(String address) {
    return 'Nó $address';
  }

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma do sistema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo escuro';

  @override
  String get node => 'Nó';

  @override
  String get connectHelpBridge =>
      'No navegador, o cliente liga-se por WebSocket: ao endereço WebSocket de um nó (como node.murmur.info, porta 443, com TLS) ou a uma ponte local (dart run tool/ws_bridge.dart, porta 7880).';

  @override
  String get connectHelpNative =>
      'O endereço peer-to-peer de um murmur-node (a sua --port, 7878 por omissão). A porta de controlo (7879) não funciona. A porta 443 chega a um nó atrás de um WebSocket seguro, como node.murmur.info.';

  @override
  String get host => 'Host';

  @override
  String get port => 'Porta';

  @override
  String get required => 'Obrigatório';

  @override
  String get enterPort => 'Indique um número de porta';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get connect => 'Conectar';

  @override
  String get syncingChain => 'A sincronizar a cadeia…';

  @override
  String get noThreads => 'Ainda não há tópicos. Comece um com Novo tópico.';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Segundo o bloco $heightString ($time, $elapsed)';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString blocos novos desde então',
      one: '1 bloco novo desde então',
      zero: 'atualizado',
    );
    return '$_temp0';
  }

  @override
  String agoSeconds(int s) {
    return 'há $s s';
  }

  @override
  String agoMinutes(int m, int s) {
    return 'há $m min $s s';
  }

  @override
  String agoHours(int h, int m) {
    return 'há $h h $m min';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return 'há $dString d $h h';
  }

  @override
  String threadStarted(String time) {
    return 'iniciado $time';
  }

  @override
  String threadLastReply(String time) {
    return 'última resposta $time';
  }

  @override
  String get messagesNeedWallet =>
      'Crie ou importe uma carteira no separador Carteira para ver as suas mensagens.';

  @override
  String get noMessages => 'Nenhuma mensagem corresponde a estes filtros.';

  @override
  String get filterThreads => 'Os meus tópicos';

  @override
  String get filterRepliesSent => 'Respostas enviadas';

  @override
  String get filterRepliesReceived => 'Respostas recebidas';

  @override
  String get filterFlagsSent => 'Denúncias feitas';

  @override
  String get filterFlagsReceived => 'Denúncias recebidas';

  @override
  String get filterMentions => 'Menções';

  @override
  String get mentionsLabel => 'Menciona';

  @override
  String get mentionPublicPoint =>
      '**Uma menção é pública:** qualquer pessoa pode ver quem nomeou.';

  @override
  String mentionsMax(int max) {
    return 'No máximo $max menções por mensagem';
  }

  @override
  String get balance => 'Saldo';

  @override
  String pendingCommitted(String amount) {
    return '$amount comprometidos em transações pendentes';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString blocos minerados',
      one: '1 bloco minerado',
      zero: 'Nenhum bloco minerado',
    );
    return '$_temp0';
  }

  @override
  String get address => 'Endereço';

  @override
  String get showSeed => 'Ver semente';

  @override
  String get removeWallet => 'Remover carteira';

  @override
  String get history => 'Histórico';

  @override
  String get filters => 'Filtros';

  @override
  String get noHistory => 'Nenhuma transação corresponde a estes filtros.';

  @override
  String get walletFilterTransfersSent => 'Transferências enviadas';

  @override
  String get walletFilterTransfersReceived => 'Transferências recebidas';

  @override
  String get walletFilterRepliesPaid => 'Pago por responder';

  @override
  String get walletFilterRepliesEarned => 'Ganho com respostas';

  @override
  String get walletFilterThreadCosts => 'Custos de tópicos';

  @override
  String get walletFilterFlagCosts => 'Taxas de denúncias';

  @override
  String get seedTitle => 'Semente da carteira';

  @override
  String get seedWarning =>
      'Quem tiver esta semente pode gastar desta carteira. Tem o mesmo formato de um ficheiro de chave criado com murmur-node keygen.';

  @override
  String get done => 'Concluído';

  @override
  String get removeWalletTitle => 'Remover a carteira?';

  @override
  String get removeWalletBody =>
      'A semente será apagada deste dispositivo. Sem uma cópia, qualquer saldo neste endereço perde-se.';

  @override
  String get remove => 'Remover';

  @override
  String get importWallet => 'Importar carteira';

  @override
  String get importHelp =>
      'Escreva ou cole a semente de uma carteira: as suas 24 palavras ou os seus 64 caracteres hexadecimais (por exemplo o conteúdo de um ficheiro de chave criado com murmur-node keygen, murmur.key, para usar as recompensas mineradas para o seu endereço).';

  @override
  String get seed => 'Semente';

  @override
  String get import => 'Importar';

  @override
  String get seedInvalid =>
      'Uma semente são 24 palavras ou exatamente 64 caracteres hexadecimais.';

  @override
  String get walletIntro =>
      'Uma carteira assina as transações que envia. A sua chave fica neste dispositivo.';

  @override
  String get createWallet => 'Criar carteira nova';

  @override
  String get importSeed => 'Importar semente';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return 'Não há bloco na altura $heightString (a ponta é $tipString).';
  }

  @override
  String get searchInvalid =>
      'Indique uma altura de bloco, ou um txid, hash de bloco ou endereço de 64 caracteres.';

  @override
  String get searchHint => 'Pesquisar altura, txid, hash de bloco ou endereço';

  @override
  String get noBlocks => 'Ainda não há blocos.';

  @override
  String blockTitle(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Bloco $heightString';
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
    return 'minerador $miner';
  }

  @override
  String get statNetwork => 'Rede';

  @override
  String get statHeight => 'Altura';

  @override
  String get statNodeHeight => 'Altura do nó';

  @override
  String get statNextReward => 'Recompensa do próximo bloco';

  @override
  String rewardPlusFees(String amount) {
    return '$amount + taxas';
  }

  @override
  String get statBurnPool => 'Fundo queimado';

  @override
  String get statCirculating => 'Em circulação';

  @override
  String get tip => 'Ponta';

  @override
  String get previousBlock => 'Bloco anterior';

  @override
  String get nextBlock => 'Bloco seguinte';

  @override
  String get blockGone => 'Este bloco já não está na melhor cadeia.';

  @override
  String get hash => 'Hash';

  @override
  String get previous => 'Anterior';

  @override
  String get time => 'Hora';

  @override
  String get confirmations => 'Confirmações';

  @override
  String get miner => 'Minerador';

  @override
  String get reward => 'Recompensa';

  @override
  String get merkleRoot => 'Raiz de Merkle';

  @override
  String get target => 'Alvo';

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
      other: '$countString transações',
      one: '1 transação',
      zero: 'Sem transações',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => 'O seu endereço';

  @override
  String get noTransactions => 'Sem transações.';

  @override
  String get sendToAddress => 'Enviar para este endereço';

  @override
  String get threadGone => 'Este tópico já não está na cadeia.';

  @override
  String paidToThreadAuthor(String amount) {
    return 'pagou $amount ao autor do tópico';
  }

  @override
  String get actionReply => 'Responder';

  @override
  String get actionFlag => 'Denunciar';

  @override
  String get flagged => 'Denunciado';

  @override
  String get details => 'Detalhes';

  @override
  String get txTitle => 'Transação';

  @override
  String get txNotFound =>
      'Transação não encontrada. Pode ter sido descartada das pendentes ou removida por uma reorganização.';

  @override
  String refNotLocal(String txid) {
    return 'Transação $txid (não está na cadeia local)';
  }

  @override
  String get flaggedMessage => 'Mensagem denunciada';

  @override
  String get inReplyTo => 'Em resposta a';

  @override
  String get notThreadedExplain =>
      'Refere esta mensagem, mas não faz parte do seu tópico: a mensagem tem de ser um tópico ou resposta minerado, e esta resposta tem de pagar ao seu autor. Conta apenas como pagamento.';

  @override
  String get message => 'Mensagem';

  @override
  String get openThread => 'Abrir tópico';

  @override
  String get transactionId => 'ID da transação';

  @override
  String get type => 'Tipo';

  @override
  String get from => 'De';

  @override
  String get to => 'Para';

  @override
  String get burned => 'Queimado';

  @override
  String burnedValue(String amount) {
    return '$amount (volta aos mineradores através do fundo queimado)';
  }

  @override
  String get amount => 'Valor';

  @override
  String get fee => 'Taxa';

  @override
  String get contentHash => 'Hash do conteúdo';

  @override
  String get contentSize => 'Tamanho do conteúdo';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString bytes (um sal de $salt bytes e uma mensagem de $messageString bytes)';
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

    return '$weightString bytes ($perByte de taxa por byte)';
  }

  @override
  String get publicKey => 'Chave pública';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'Confirmada no bloco $heightString';
  }

  @override
  String confirmationCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString confirmações',
      one: '1 confirmação',
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
      other: 'Não confirmada após $countString blocos',
      one: 'Não confirmada após 1 bloco',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused =>
      'O nó pode tê-la recusado (por exemplo, se o saldo mudou antes de ser minerada). O nó não avisa das transações recusadas.';

  @override
  String get sentWaiting => 'Enviada, à espera de um bloco';

  @override
  String get submittedHere => 'Enviada a partir deste dispositivo.';

  @override
  String get pendingTitle => 'Pendente';

  @override
  String get relayedPending =>
      'Retransmitida pelo nó, ainda não está num bloco.';

  @override
  String get viewBlock => 'Ver bloco';

  @override
  String get newTransaction => 'Nova transação';

  @override
  String get flagMessage => 'Denunciar mensagem';

  @override
  String flaggingInfo(String author) {
    return 'Vai denunciar esta mensagem de $author. Cada carteira pode denunciar uma mensagem uma só vez. Cada cliente decide o que fazer com as denúncias.';
  }

  @override
  String replyingTo(String author) {
    return 'A responder a $author';
  }

  @override
  String explainThread(int total, int burn) {
    return 'Começa um tópico novo. Custa $total × a taxa: a taxa vai para o minerador e $burn × a taxa é queimado. Os tokens queimados voltam aos mineradores nos blocos seguintes.';
  }

  @override
  String get explainReply =>
      'A sua resposta paga ao autor do tópico pelo menos a taxa (pode dar mais como gorjeta), mais a taxa ao minerador.';

  @override
  String get explainTransfer =>
      'Uma simples transferência de tokens sem mensagem. O valor tem de ser pelo menos a taxa.';

  @override
  String get recipientAddress => 'Endereço do destinatário';

  @override
  String get enterAddress => 'Indique um endereço hexadecimal de 64 caracteres';

  @override
  String get payToAuthor => 'Pagar ao autor do tópico';

  @override
  String get notAnAmount => 'Introduza uma quantidade';

  @override
  String atLeastFee(String fee) {
    return 'Pelo menos a taxa ($fee)';
  }

  @override
  String get feeToMiner => 'Taxa (para o minerador)';

  @override
  String suggestedFee(String fee) {
    return 'Sugerida: $fee';
  }

  @override
  String feeBelowSuggested(String fee) {
    return 'Abaixo da taxa sugerida ($fee): pode demorar a entrar num bloco.';
  }

  @override
  String feeAboveSuggested(String fee) {
    return 'Acima da taxa sugerida ($fee): oferece ao minerador mais do que o necessário.';
  }

  @override
  String atLeastMin(String min) {
    return 'Pelo menos $min';
  }

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

    return 'Demasiado longa: $countString bytes';
  }

  @override
  String get murmurEmoji => 'Emojis do Murmur';

  @override
  String murmurEmojiHint(String example) {
    return 'Desenhados apenas no Murmur. As outras aplicações mostram o nome, como $example.';
  }

  @override
  String get sendingNeedsLive =>
      'Poderá enviar quando o cliente estiver conectado e sincronizado.';

  @override
  String get signAndSend => 'Assinar e enviar';

  @override
  String get costFee => 'Taxa, para o minerador';

  @override
  String costBurn(int multiple) {
    return 'Queimado: $multiple × a taxa';
  }

  @override
  String get costPaid => 'Pago ao destinatário';

  @override
  String get costTotal => 'Custo total';

  @override
  String get costAvailable => 'Disponível: saldo menos transações pendentes';

  @override
  String get costRemaining => 'O que sobra depois de enviar';

  @override
  String get checkingFees => 'A consultar as taxas da rede…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Estimativa com base no que este cliente viu ($countString pendentes desde que se conectou); o relatório de taxas do nó não estava disponível.';
  }

  @override
  String get use => 'Usar';

  @override
  String balanceBeforeAfter(String before, String after) {
    return '$before → $after';
  }

  @override
  String balanceBeforeAfterTooltip(String before, String after) {
    return 'Saldo: $before antes, $after depois';
  }

  @override
  String get loadingOlder => 'A carregar blocos anteriores…';

  @override
  String get blockLoading => 'A carregar este bloco…';

  @override
  String get txSearching =>
      'A procurar esta transação nos blocos que ainda estão a carregar…';

  @override
  String get storageBanner =>
      'Guardar uma cópia da cadeia neste dispositivo? As próximas visitas abrem em segundos em vez de descarregar tudo de novo. Fica aqui e nunca é enviada a ninguém: sem cookies nem rastreamento. A chave da sua carteira e as suas definições ficam sempre neste dispositivo, porque a aplicação precisa delas para funcionar.';

  @override
  String get storageAllow => 'Permitir o armazenamento necessário';

  @override
  String get storageReject => 'Recusar (mais lento)';

  @override
  String get storageOn => 'Cópia local da cadeia: ativada';

  @override
  String get storageOff =>
      'Cópia local da cadeia: desativada (cada visita descarrega-a de novo)';

  @override
  String get storageTurnOn => 'Ativar';

  @override
  String get storageTurnOff => 'Desativar e apagar';

  @override
  String get checkingBalance => 'A verificar com o nó…';

  @override
  String get errTampered =>
      'A conexão foi alterada ou cortada: uma mensagem falhou a verificação de integridade.';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'O estado que o nó compromete no bloco $heightString não coincide com a contagem da cadeia feita por este cliente. Não confie neste nó: conecte-se a outro.';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Segundo o nó: $countString transações pendentes.',
      one: 'Segundo o nó: 1 transação pendente.',
      zero: 'Segundo o nó: nada pendente.',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => 'Aceite pelo nó e retransmitida.';

  @override
  String get statusRefused => 'Recusada pelo nó';

  @override
  String get statusInvalid => 'Rejeitada por ser inválida';

  @override
  String nodeReason(String reason) {
    return 'O nó diz: $reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'A cadeia não leva ao ponto de controlo desta versão no bloco $heightString: ou a versão ou todos os nós contactados estão errados. Parado; não se pode confiar em nada dela.';
  }

  @override
  String staleTip(String elapsed) {
    return 'O bloco mais recente é de $elapsed: este nó pode estar atrasado ou isolado da rede. O que vê pode estar desatualizado.';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return 'Iniciado a partir do ponto de controlo no bloco $heightString; a verificar os cabeçalhos até à génese ($doneString até agora).';
  }

  @override
  String get licenses => 'Licenças';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => 'Rede de testes: os tokens não têm valor';

  @override
  String get linkNodeRepo => 'Código do nó e do protocolo';

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

    return 'A verificar os cabeçalhos dos blocos: $doneString de $totalString';
  }

  @override
  String reconnectingIn(int seconds) {
    return 'Nova tentativa dentro de $seconds s.';
  }

  @override
  String get languagesFilter => 'Idiomas';

  @override
  String get languageUndetected => 'Não detetado';

  @override
  String get hideFlaggedThreads => 'Ocultar os tópicos que denunciei';

  @override
  String get star => 'Marcar com estrela';

  @override
  String get unstar => 'Tirar estrela';

  @override
  String get starredOnly => 'Só tópicos com estrela';

  @override
  String get localNodeRun => 'Executar um nó Murmur neste computador';

  @override
  String get localNodeExplain =>
      'O seu computador verifica por si toda a cadeia, ajuda a difundi-la e mantém disponíveis as suas próprias mensagens. Guarda apenas o último dia da cadeia, e nenhuma mensagem de mais ninguém para lá da verificação de uma hora.';

  @override
  String get localNodeStarting => 'A iniciar o nó…';

  @override
  String localNodeRunning(String address) {
    return 'O nó está a funcionar em $address. A app continua a ler do nó que escolheu.';
  }

  @override
  String localNodeFailed(String reason) {
    return 'O nó parou: $reason';
  }

  @override
  String get localNodeFailedUnknown => 'O nó parou inesperadamente.';

  @override
  String get localNodeFromCheckpoint =>
      'A começar pelos blocos mais recentes: os anteriores são verificados depois.';

  @override
  String localNodeCatchingUp(String height, String total) {
    return 'A acompanhar a cadeia: bloco $height de $total';
  }

  @override
  String localNodeCheckingHistory(String height, String total) {
    return 'A verificar os blocos anteriores em segundo plano: $height de $total';
  }

  @override
  String get localNodeMine => 'Minerar com este computador';

  @override
  String get localNodeMineNote =>
      'A mineração paga ao endereço da sua carteira, gasta eletricidade e faz o computador trabalhar mais. Na testnet, os tokens são só para testes.';

  @override
  String get localNodeMineNeedsWallet =>
      'Crie primeiro uma carteira: a mineração paga ao seu endereço.';

  @override
  String localNodeMinesTo(String name) {
    return 'A mineração paga a **$name**';
  }

  @override
  String localNodeCpu(int pct) {
    return 'Até $pct% de um núcleo do processador';
  }

  @override
  String get localNodeGpu => 'Minerar com a placa gráfica';

  @override
  String get localNodeGpuNote =>
      'Muito mais rápido do que o processador, e gasta mais eletricidade. Se a placa não puder ser usada, a mineração continua com o processador.';

  @override
  String get localNodeGpuStarting =>
      'A iniciar a placa gráfica. Entretanto minera o processador.';

  @override
  String localNodeGpuMining(String device) {
    return 'A minerar com **$device**';
  }

  @override
  String get localNodeGpuMiningAny => 'A minerar com **a placa gráfica**';

  @override
  String get localNodeGpuUnavailable =>
      'A placa gráfica não pode ser usada: **a mineração continua com o processador**.';

  @override
  String localNodeGpuDetail(String reason) {
    return 'O que o nó diz: $reason';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tópicos ocultos',
      one: '1 tópico oculto',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => 'Pesquisar nos tópicos carregados';

  @override
  String get noMatches => 'Nenhum tópico carregado corresponde.';

  @override
  String get timeJustNow => 'agora mesmo';

  @override
  String timeMinutesAgo(int n) {
    return 'há $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'há $n h';
  }

  @override
  String timeDaysAgo(int n) {
    return 'há $n d';
  }

  @override
  String get nameAddress => 'Nome';

  @override
  String get aliasTitle => 'Dar um nome a este endereço';

  @override
  String get aliasHelp =>
      'O nome fica guardado só neste dispositivo. Deixe-o vazio para o remover.';

  @override
  String get save => 'Guardar';

  @override
  String get mute => 'Silenciar';

  @override
  String get unmute => 'Deixar de silenciar';

  @override
  String get mutedNote =>
      'Silenciado: os seus tópicos e respostas ficam ocultos neste dispositivo.';

  @override
  String get earlierReplies => 'Respostas anteriores';

  @override
  String get quoteNotLoaded => 'Uma resposta anterior (toque para carregar)';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respostas de endereços silenciados ocultas',
      one: '1 resposta de um endereço silenciado oculta',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respostas novas',
      one: '1 resposta nova',
    );
    return '$_temp0';
  }

  @override
  String get invitations => 'Convites';

  @override
  String get createInvitations => 'Criar convites';

  @override
  String get inviteHowMany => 'Quantos cartões';

  @override
  String get inviteFund => 'Financiar os cartões';

  @override
  String get inviteCardTitle => 'Convite para o Murmur';

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
      'Leia o código ou abra a ligação para entrar no Murmur.';

  @override
  String get inviteClaimed => 'Resgatado';

  @override
  String get inviteChecking => 'A verificar…';

  @override
  String get claimTitle => 'Foi convidado';

  @override
  String claimInvitedBy(String name) {
    return 'Convite de $name';
  }

  @override
  String claimHolds(String amount) {
    return 'Este convite tem $amount: o suficiente para os seus primeiros tópicos.';
  }

  @override
  String get claimCreateWallet => 'Criar a minha carteira e resgatar';

  @override
  String get claimIntoWallet => 'Resgatar para a minha carteira';

  @override
  String get claimDone =>
      'Resgatado. Os tokens chegam à sua carteira com o próximo bloco.';

  @override
  String get claimEmpty => 'Este convite já foi resgatado ou recuperado.';

  @override
  String get claimWrongNetwork =>
      'Este convite é para outra rede que não a do nó a que está ligado.';

  @override
  String get claimInvalid => 'Esse não é um código de convite válido.';

  @override
  String get haveInvitation => 'Tenho um convite';

  @override
  String get inviteCodeField => 'Código ou ligação do convite';

  @override
  String get claim => 'Resgatar';

  @override
  String get cancelInvitation => 'Cancelar convite';

  @override
  String get inviteCancelled => 'Cancelado';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cancelar $count convites?',
      one: 'Cancelar este convite?',
    );
    return '$_temp0';
  }

  @override
  String cancelInviteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Os seus tokens voltam, e quem tiver os cartões deixa de os poder resgatar.',
      one:
          'Os seus tokens voltam, e quem tiver o cartão deixa de o poder resgatar.',
    );
    return '$_temp0';
  }

  @override
  String get keepInvitation => 'Manter';

  @override
  String get printOne => 'Imprimir';

  @override
  String inviteDoneSection(int count) {
    return 'Resgatados ou cancelados ($count)';
  }

  @override
  String get inviteEachLabel => 'Cada cartão';

  @override
  String get inviteEachCaption =>
      'Cinco tópicos à taxa de hoje, mais a taxa para o resgatar.';

  @override
  String get inviteTotalLabel => 'Paga';

  @override
  String get inviteTotalCaption => 'No total, taxas incluídas.';

  @override
  String get inviteWaitingState => 'À espera de resgate';

  @override
  String get inviteCardSlogan => 'A sua voz tem lugar aqui.';

  @override
  String get inviteCardJoin => 'Leia para entrar';

  @override
  String get share => 'Partilhar…';

  @override
  String get inviteDetailFunded => 'Financiado';

  @override
  String get inviteDetailClaimedBy => 'Resgatado por';

  @override
  String get inviteDetailReceived => 'Recebido';

  @override
  String get inviteDetailCancelled =>
      'Cancelado: os tokens voltaram para a sua carteira';

  @override
  String get inviteDetailReturned => 'Devolvido';

  @override
  String get inviteDetailOnItsWay => 'A caminho de um bloco';

  @override
  String get seedConfirmTitle => 'Mostrar a sua semente?';

  @override
  String get seedConfirmBody =>
      'Quem vir a semente pode gastar desta carteira. Certifique-se de que mais ninguém vê o ecrã.';

  @override
  String get showAction => 'Mostrar';

  @override
  String get authReasonSeed => 'Confirme que é você para ver a semente';

  @override
  String get authReasonRemove =>
      'Confirme que é você para remover esta carteira';

  @override
  String get authFailed => 'Não confirmado: nada foi mostrado nem alterado.';

  @override
  String get passphraseNewTitle => 'Escolha uma frase-passe';

  @override
  String get passphraseNewWhat =>
      '**Uma só frase-passe para esta app.** Cifra a chave da sua carteira e os códigos dos seus cartões de convite neste dispositivo.';

  @override
  String get passphraseNewWhen =>
      'Vai escrevê-la **sempre** que enviar, mostrar a semente ou remover a carteira, e para mostrar, imprimir ou cancelar um cartão.';

  @override
  String get passphraseNewForget =>
      'Se a esquecer, só a sua **cópia da semente** recupera a carteira, e os cartões ainda não entregues deixam de poder ser mostrados ou cancelados.';

  @override
  String get passphraseField => 'Frase-passe';

  @override
  String get passphraseRepeat => 'Repita a frase-passe';

  @override
  String passphraseTooShort(int min) {
    return 'Pelo menos $min caracteres';
  }

  @override
  String get passphraseMismatch => 'Não coincidem';

  @override
  String get passphraseTitle => 'Frase-passe';

  @override
  String get wrongPassphrase =>
      'Frase-passe errada: nada foi mostrado nem enviado.';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get authReasonSend => 'Confirme que é você para assinar e enviar';

  @override
  String get authReasonNewWallet =>
      'Proteja a chave da sua carteira neste dispositivo';

  @override
  String get authReasonInvite =>
      'Confirme que é você para financiar os cartões';

  @override
  String get removeAnywayTitle => 'Remover sem confirmar?';

  @override
  String get removeAnywayBody =>
      'Não foi possível desbloquear a carteira. Removê-la apaga a sua chave deste dispositivo: só a cópia da semente a pode recuperar.';

  @override
  String get forgetCardsKeyTitle =>
      'Não é possível desbloquear os seus cartões de convite';

  @override
  String get forgetCardsKeyBody =>
      'Uma carteira nova usa a frase-passe ou a chave de acesso dos seus cartões de convite. Se já não a tem, abdique da chave dos cartões: a carteira recebe uma frase-passe nova, e os cartões ainda por resgatar deixam de poder ser mostrados, impressos ou cancelados neste dispositivo. Os seus tokens ficam nos cartões.';

  @override
  String get forgetCardsKeyAction => 'Abdicar da chave dos cartões';

  @override
  String get inviteCodeLost => 'Código já não está neste dispositivo';

  @override
  String get protectionDevice =>
      'Chave cifrada com o bloqueio deste dispositivo';

  @override
  String get protectionPasskey =>
      'Chave cifrada com uma chave de acesso deste dispositivo';

  @override
  String get protectionPassphrase => 'Chave cifrada com a sua frase-passe';

  @override
  String get protectionLegacy =>
      'Chave ainda não cifrada: será no próximo desbloqueio';

  @override
  String get confirmSendTitle => 'Verifique antes de assinar';

  @override
  String get confirmSendFinal =>
      'Ao assinar, isto é enviado ao nó. Não pode ser desfeito: depois de minerado, fica na cadeia.';

  @override
  String signAndSendShortcut(String keys) {
    return 'Assinar e enviar ($keys)';
  }

  @override
  String get threadWithdrawnMine =>
      'Retirou-o: oculto para os outros, e o texto apagado das apps Murmur';

  @override
  String get threadWithdrawnMineNote =>
      'Denunciou o seu próprio tópico, o que o retira. As apps Murmur deixam de o mostrar aos outros e apagam o texto, também neste dispositivo; os nós podem deixar de guardar o texto e as respostas.';

  @override
  String get threadWithdrawnNote =>
      'O autor denunciou este tópico, o que o retira. As apps Murmur deixam de o listar e apagam o texto, e os nós podem deixar de guardar o texto e as respostas.';

  @override
  String get flagOwnInfo =>
      'Esta mensagem é sua. Denunciá-la retira-a: as apps Murmur deixam de a mostrar aos outros e apagam o texto, também neste dispositivo, e os nós podem deixar de guardar o texto e as respostas. Não pode ser desfeito.';

  @override
  String get inviteFromTitle => 'Nome nos cartões';

  @override
  String get inviteFromBody =>
      'Cada cartão diz de quem é. Foram financiados pela carteira que convida, que pode já não ser a deste dispositivo.';

  @override
  String get inviteFromOriginal => 'Endereço da carteira que convida';

  @override
  String get inviteFromOriginalAlias =>
      'O seu nome para a carteira que convida';

  @override
  String get inviteFromOriginalPublic => 'Nome público da carteira que convida';

  @override
  String get inviteFromCurrent => 'Endereço desta carteira';

  @override
  String get inviteFromCurrentAlias => 'O seu nome para esta carteira';

  @override
  String get inviteFromCurrentPublic => 'Nome público desta carteira';

  @override
  String get inviteFromCustom => 'Outro texto';

  @override
  String get inviteFromCustomHint =>
      'Deixe vazio para não imprimir nenhum nome';

  @override
  String get inviteFromNotSet => 'Sem nome neste dispositivo';

  @override
  String get inviteFromMixed => 'Difere entre os cartões escolhidos';

  @override
  String get inviteFromChecking => 'Ainda a procurar na cadeia';

  @override
  String get cancelReturnTo => 'Enviar os tokens para';

  @override
  String get cancelToFunder => 'A carteira que o financiou';

  @override
  String get cancelToCurrent => 'Esta carteira';

  @override
  String get publicName => 'Nome público';

  @override
  String get publicNameNone => 'Nenhum conhecido';

  @override
  String get publicNameSet => 'Definir nome público';

  @override
  String get publicNameField => 'Nome';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return 'No máximo $maxString bytes';
  }

  @override
  String get aliasBadCharacter =>
      'Não são permitidos caracteres invisíveis nem de controlo';

  @override
  String get aliasEdgeSpace => 'Sem espaços no início nem no fim';

  @override
  String aliasSetTo(String name) {
    return 'Nome público: $name';
  }

  @override
  String get aliasCleared => 'Nome público retirado';

  @override
  String profileSetTo(String name) {
    return 'Nome público e imagem: $name';
  }

  @override
  String get profilePictureOnly => 'Imagem pública, sem nome';

  @override
  String get nonTextMessage => '(não é texto: dados de uma convenção de apps)';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return 'Publica o seu nome público. Como um tópico novo, custa $totalString × a taxa: a taxa vai para o minerador e $burnString × a taxa é queimado.';
  }

  @override
  String get inviteFromNoPublic => 'Nenhum nome público conhecido';

  @override
  String get starredTitle => 'Com estrela';

  @override
  String get noStarred =>
      'Ainda não há nada com estrela. Marque um tópico, uma mensagem ou uma pessoa na sua página e aparece aqui.';

  @override
  String get starredGone => 'Já não está na cadeia';

  @override
  String get feeSuggestedLabel => 'Taxa sugerida';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return 'por $weightString bytes';
  }

  @override
  String get feeRoom => 'Os blocos têm espaço';

  @override
  String get feeFull => 'Os blocos estão cheios';

  @override
  String get feeNextBlock => 'Próximo bloco';

  @override
  String get feePoolEntry => 'Para entrar na fila';

  @override
  String get feeMinimum => 'Mínimo';

  @override
  String get feeWhy => 'Porquê esta taxa';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**A taxa é por byte**: $baseString bytes mais a sua mensagem. Mensagens longas custam mais quando os blocos estão cheios.';
  }

  @override
  String feeRecentPoint(String lowest, String median) {
    return '**Os blocos recentes** aceitaram taxas de apenas **$lowest** (mediana $median).';
  }

  @override
  String get feeRecentNonePoint =>
      '**Os blocos recentes** não tinham transações.';

  @override
  String get inviteNoExpiryPoint =>
      '**Não expira**: um cartão vale até alguém o resgatar.';

  @override
  String get inviteCancelPoint =>
      '**Cancele quando quiser**: os tokens voltam.';

  @override
  String get invitePublicPoint =>
      '**É público**: a cadeia mostra que financiou cada cartão e que carteira o resgatou.';

  @override
  String get inviteCashPoint =>
      '**Quem tiver o código** pode resgatar o cartão. Guarde-os em privado até os entregar.';

  @override
  String get inviteLocalPoint =>
      '**Guardados só neste dispositivo.** Se os dados forem apagados ou a app removida, os códigos **perdem-se para sempre**, e também os tokens dos cartões ainda não entregues.';

  @override
  String get publicNameIntro =>
      'O seu nome público aparece **junto ao seu endereço** nas apps Murmur.';

  @override
  String publicNameShownAs(String name) {
    return 'Vai aparecer como **$name**';
  }

  @override
  String get publicNameNotUnique =>
      '**Não é único**: qualquer pessoa pode escolher o mesmo nome. O endereço ao lado distingue as pessoas.';

  @override
  String get publicNameCost =>
      '**Custa tanto como um tópico novo**, sempre que o define ou muda.';

  @override
  String get publicNameRemovable =>
      '**É uma mensagem na cadeia**: qualquer nó a pode apagar, e então desaparece.';

  @override
  String get publicNameClear => '**Deixe vazio** para o retirar.';

  @override
  String get publicNamePicture => 'Imagem';

  @override
  String get pictureFromPhotos => 'Das fotos';

  @override
  String get pictureFromFiles => 'Dos ficheiros';

  @override
  String get pictureChoose => 'Escolher uma imagem';

  @override
  String get pictureRemove => 'Retirar a imagem';

  @override
  String pictureTooLarge(String size) {
    return 'O ficheiro é demasiado grande: escolha um com menos de $size MB.';
  }

  @override
  String get pictureUnreadable =>
      'Esse ficheiro não pode ser lido como imagem.';

  @override
  String get picturePoint =>
      '**32 × 32 píxeis, 16 cores**, em vez da marca do seu endereço.';

  @override
  String get pictureCost => '**Cerca de três vezes o custo** com imagem.';

  @override
  String get passkeyNoPrfTitle =>
      'Este gestor de chaves de acesso não pode proteger a carteira';

  @override
  String get passkeyNoPrfWhy =>
      '**Não consegue cifrar.** Para trancar a chave da carteira, o gestor tem de derivar uma chave da chave de acesso (WebAuthn PRF). O que escolheu não o faz.';

  @override
  String get passkeyNoPrfTry =>
      '**Experimente outro gestor**, como as Palavras-passe da Apple ou o Gestor de palavras-passe da Google, ou proteja a carteira com uma **frase-passe**.';

  @override
  String get passkeyNoPrfLeftover =>
      'A chave de acesso que acabou de guardar (**Murmur wallet**) não desbloqueia nada: pode apagá-la desse gestor.';

  @override
  String get passkeyTryAnother => 'Experimentar outro gestor';

  @override
  String get passkeyUsePassphrase => 'Usar uma frase-passe';

  @override
  String inviteDetailCancelledTo(String name) {
    return 'Cancelado: os tokens foram para $name';
  }

  @override
  String get seedNewTitle => 'Guarde a semente da sua carteira';

  @override
  String get seedNewKeep =>
      '**Guarde-a num lugar seguro**, fora deste dispositivo: escrita em papel ou num gestor de palavras-passe.';

  @override
  String get seedNewOnlyWay =>
      'É a **única forma de voltar** a esta carteira se perder este dispositivo ou esquecer a sua frase-passe. Ninguém a pode recuperar por si.';

  @override
  String get seedNewSecret =>
      '**Quem a tiver controla a carteira.** Nunca a partilhe nem a escreva num site que a peça.';

  @override
  String get seedNewSaved => 'Guardei a minha semente';

  @override
  String get seedAsWords => 'Em 24 palavras';

  @override
  String get seedAsHex => 'Em 64 caracteres';

  @override
  String get seedEitherForm => 'As duas são a mesma semente: basta uma.';

  @override
  String get copyWords => 'Copiar palavras';

  @override
  String get copyCharacters => 'Copiar caracteres';

  @override
  String get seedOrWords => 'Semente: 24 palavras ou 64 caracteres';

  @override
  String seedUnknownWord(String word) {
    return '«$word» não é uma das palavras de semente. Verifique como está escrita.';
  }

  @override
  String get seedBadChecksum =>
      'Estas 24 palavras não formam uma semente: uma está errada ou fora do lugar.';

  @override
  String get qrCode => 'Código QR';

  @override
  String get addressQrHint => 'Digitalize para abrir este endereço no Murmur.';

  @override
  String get starredPeople => 'Pessoas';

  @override
  String get starredThreads => 'Mensagens';

  @override
  String get noStarredThreads =>
      'Nenhum tópico ou mensagem com estrela. Marque um na sua página e aparece aqui.';

  @override
  String get noStarredPeople =>
      'Nenhuma pessoa com estrela. Marque alguém na sua página e aparece aqui.';

  @override
  String get newActivity => 'Atividade nova';

  @override
  String starredNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens com estrela têm atividade nova',
      one: '1 item com estrela tem atividade nova',
    );
    return '$_temp0';
  }

  @override
  String get authReasonCards =>
      'Confirme que é você para desbloquear os cartões de convite';

  @override
  String get inviteLockedPoint =>
      '**Os códigos são guardados cifrados.** Mostrar, imprimir ou cancelar um cartão pede-lhe para os **desbloquear**.';

  @override
  String get notifications => 'Notificações';

  @override
  String get notifyReplies => 'Respostas para si';

  @override
  String get notifyMentions => 'Menções a si';

  @override
  String get notifyStarred => 'Novidades no que tem estrela';

  @override
  String get notifyNeedsWallet => 'Precisa de uma carteira neste dispositivo';

  @override
  String get notifyDenied =>
      'As notificações do Murmur estão desligadas nas definições do sistema.';

  @override
  String get notifyPointLocal =>
      '**Esta app verifica sozinha**, no nó que escolheu: nada passa pela Google, pela Apple nem por mais ninguém.';

  @override
  String get notifyPointBackground =>
      'Com a app fechada, verifica **mais ou menos a cada 15 minutos**, como o sistema permitir.';

  @override
  String get notifyPointOpen =>
      'Só **enquanto a app está aberta**, quando não está à frente.';

  @override
  String get notifyPointLockScreen =>
      'O ecrã de bloqueio **esconde o conteúdo**.';

  @override
  String get notifyChannel => 'Mensagens';

  @override
  String get notifyOpen => 'Abrir';

  @override
  String notifyReply(String name) {
    return '$name respondeu no seu tópico';
  }

  @override
  String notifyAnswer(String name) {
    return '$name respondeu-lhe';
  }

  @override
  String notifyMention(String name) {
    return '$name mencionou-o';
  }

  @override
  String notifyStarredReply(String name) {
    return '$name respondeu num tópico com estrela';
  }

  @override
  String notifyStarredPerson(String name) {
    return 'Nova mensagem de $name';
  }

  @override
  String notifyMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mais $countString mensagens novas',
      one: 'Mais 1 mensagem nova',
    );
    return '$_temp0';
  }

  @override
  String get faceIdReason =>
      'Confirme que é você antes de a chave da sua carteira ser usada ou mostrada.';

  @override
  String get refresh => 'Atualizar';

  @override
  String get markAllRead => 'Marcar tudo como lido';

  @override
  String get newAboveLastVisit => 'Acima: novidades desde a sua última visita';

  @override
  String get publicNameAndPicture => 'Nome público e imagem';

  @override
  String get publicNameAndPictureSet => 'Definir nome público e imagem';

  @override
  String get publicNameStandOut =>
      '**Destaque-se**: um nome e uma imagem que os outros veem junto ao seu endereço.';

  @override
  String get pictureLarger => 'Ver a imagem maior';

  @override
  String get keepMessagesAvailable => 'Manter as minhas mensagens disponíveis';

  @override
  String get keepMessagesAvailableExplain =>
      '**Enquanto a app está aberta**, quem lê recebe as suas mensagens de si quando os nós já não as guardam. **Só as suas**, nunca as de outros.';

  @override
  String errBadSignature(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'O bloco $heightString contém uma transação com uma assinatura inválida: a cadeia do nó viola as regras que todos os nós aplicam. Não confie neste nó: ligue-se a outro.';
  }

  @override
  String receivedOmitted(String count) {
    return '**O nó omitiu** parte do que outros fizeram sobre si ($count). É mostrado na mesma, encontrado nos próprios blocos.';
  }

  @override
  String get keyringUnavailable =>
      'O porta-chaves do sistema está bloqueado e não pode pedir a palavra-passe, por isso a carteira não pode ser guardada neste dispositivo. Desbloqueie o porta-chaves (normalmente acontece ao iniciar sessão no ambiente de trabalho) e abra o Murmur de novo.';
}
