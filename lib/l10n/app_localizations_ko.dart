// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => '스레드';

  @override
  String get kindReply => '답글';

  @override
  String get kindTransfer => '송금';

  @override
  String get kindFlag => '신고';

  @override
  String get contentUnavailable => '(내용을 볼 수 없음: 노드에 없습니다)';

  @override
  String get contentWithdrawn => '(작성자가 철회함)';

  @override
  String get contentLoading => '(메시지를 불러오는 중…)';

  @override
  String get pending => '대기 중';

  @override
  String get copy => '복사';

  @override
  String get copied => '복사됨';

  @override
  String replyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '답글 $countString개',
      zero: '답글 없음',
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
      other: '신고 $countString건',
      zero: '신고 없음',
    );
    return '$_temp0';
  }

  @override
  String transferOf(String amount) {
    return '$amount 송금';
  }

  @override
  String flagOn(String text) {
    return '“$text”에 대한 신고';
  }

  @override
  String flagOnTx(String txid) {
    return '$txid에 대한 신고';
  }

  @override
  String get replyNotThreaded => '답글 (스레드에 속하지 않음)';

  @override
  String routeFrom(String address) {
    return '보낸 주소 $address';
  }

  @override
  String routeFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String errUnreachable(String detail) {
    return '노드에 연결할 수 없습니다: $detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return '$url의 WebSocket 브리지에 연결할 수 없습니다. 다음 명령으로 시작하세요: dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return '연결 오류: $detail';
  }

  @override
  String get errClosed => '노드가 연결을 끊었습니다.';

  @override
  String get errTimeout => '노드가 제시간에 응답하지 않았습니다.';

  @override
  String errProtocol(String detail) {
    return '프로토콜 오류: $detail';
  }

  @override
  String errVersion(int node, int ours) {
    return '노드의 프로토콜은 $node이고, 이 클라이언트의 프로토콜은 $ours입니다.';
  }

  @override
  String errSyncFailed(String cause) {
    return '동기화 실패: $cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return '전달된 블록을 무시했습니다: $detail';
  }

  @override
  String get probFeeTooLow => '수수료가 네트워크 최소값보다 낮습니다.';

  @override
  String get probMalformed => '이 트랜잭션은 형식이 올바르지 않습니다.';

  @override
  String get probNeedsMessage => '메시지를 작성하세요.';

  @override
  String get probNeedsRecipient => '받는 사람을 입력하세요.';

  @override
  String probAmountBelowFee(String fee) {
    return '금액은 수수료($fee) 이상이어야 합니다.';
  }

  @override
  String get probReplyParentNotMined => '이미 블록에 포함된 스레드나 답글에만 답할 수 있습니다.';

  @override
  String get probFlagNotMessage => '스레드와 답글만 신고할 수 있습니다.';

  @override
  String get probAlreadyFlagged => '이 지갑은 이미 그 메시지를 신고했습니다.';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '메시지가 $lengthString바이트입니다. 한도는 $limitString바이트입니다.';
  }

  @override
  String probInsufficientBalance(String needed, String available) {
    return '잔액 부족: $needed 필요, $available 사용 가능 (확정 잔액에서 대기 중인 트랜잭션을 뺀 값).';
  }

  @override
  String get probNotLive => '클라이언트가 연결되고 동기화될 때까지 기다리세요.';

  @override
  String get probConnectionLost => '노드와의 연결이 끊겼습니다.';

  @override
  String get probDuplicate => '같은 트랜잭션을 이번 초에 이미 보냈습니다.';

  @override
  String get tabThreads => '스레드';

  @override
  String get tabMessages => '메시지';

  @override
  String get tabWallet => '지갑';

  @override
  String get tabChain => '체인';

  @override
  String get newThread => '새 스레드';

  @override
  String get createWalletFirst => '먼저 지갑을 만들거나 가져오세요.';

  @override
  String get syncNow => '지금 동기화';

  @override
  String get reconnect => '다시 연결';

  @override
  String get changeNode => '노드 변경';

  @override
  String get unknownNetwork =>
      '이 노드는 클라이언트가 알지 못하는 네트워크에 있습니다. 난이도 조정을 확인할 수 없고, 블록 보상은 백서의 값으로 계산되므로 채굴자 잔액이 틀릴 수 있습니다.';

  @override
  String get linkOffline => '오프라인';

  @override
  String get linkConnecting => '연결 중…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return '동기화 중 $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '실시간 · $heightString';
  }

  @override
  String get connectToNode => '노드에 연결';

  @override
  String nodeAt(String address) {
    return '노드 $address';
  }

  @override
  String get language => '언어';

  @override
  String get systemLanguage => '시스템 언어';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get darkMode => '다크 모드';

  @override
  String get node => '노드';

  @override
  String get connectHelpBridge =>
      '브라우저에서 클라이언트는 WebSocket으로 연결합니다. 노드의 WebSocket 주소(예: node.murmur.info, 포트 443, TLS 사용)나 로컬 브리지(dart run tool/ws_bridge.dart, 포트 7880)에 연결합니다.';

  @override
  String get connectHelpNative =>
      'murmur-node의 P2P 주소입니다(--port, 기본값 7878). 제어 포트(7879)로는 연결되지 않습니다. 포트 443은 node.murmur.info처럼 보안 WebSocket 뒤에 있는 노드에 연결합니다.';

  @override
  String get host => '호스트';

  @override
  String get port => '포트';

  @override
  String get required => '필수';

  @override
  String get enterPort => '포트 번호를 입력하세요';

  @override
  String get disconnect => '연결 끊기';

  @override
  String get cancel => '취소';

  @override
  String get connect => '연결';

  @override
  String get syncingChain => '체인 동기화 중…';

  @override
  String get noThreads => '아직 스레드가 없습니다. 새 스레드로 시작해 보세요.';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '블록 $heightString 기준 ($time, $elapsed)';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '그 후 새 블록 $countString개',
      zero: '최신 상태',
    );
    return '$_temp0';
  }

  @override
  String agoSeconds(int s) {
    return '$s초 전';
  }

  @override
  String agoMinutes(int m, int s) {
    return '$m분 $s초 전';
  }

  @override
  String agoHours(int h, int m) {
    return '$h시간 $m분 전';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return '$dString일 $h시간 전';
  }

  @override
  String threadStarted(String time) {
    return '$time 시작';
  }

  @override
  String threadLastReply(String time) {
    return '마지막 답글 $time';
  }

  @override
  String get messagesNeedWallet => '메시지를 보려면 지갑 탭에서 지갑을 만들거나 가져오세요.';

  @override
  String get noMessages => '이 필터에 맞는 메시지가 없습니다.';

  @override
  String get filterThreads => '내 스레드';

  @override
  String get filterRepliesSent => '보낸 답글';

  @override
  String get filterRepliesReceived => '받은 답글';

  @override
  String get filterFlagsSent => '내가 한 신고';

  @override
  String get filterFlagsReceived => '받은 신고';

  @override
  String get filterMentions => '멘션';

  @override
  String get mentionsLabel => '멘션';

  @override
  String get mentionPublicPoint => '**멘션은 공개됩니다:** 누구를 언급했는지 누구나 볼 수 있습니다.';

  @override
  String mentionsMax(int max) {
    return '메시지 하나에 멘션은 최대 $max개';
  }

  @override
  String get balance => '잔액';

  @override
  String pendingCommitted(String amount) {
    return '대기 중인 트랜잭션에 $amount 묶여 있음';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '블록 $countString개 채굴',
      zero: '채굴한 블록 없음',
    );
    return '$_temp0';
  }

  @override
  String get address => '주소';

  @override
  String get showSeed => '시드 보기';

  @override
  String get removeWallet => '지갑 삭제';

  @override
  String get history => '기록';

  @override
  String get filters => '필터';

  @override
  String get noHistory => '이 필터에 맞는 트랜잭션이 없습니다.';

  @override
  String get walletFilterTransfersSent => '보낸 송금';

  @override
  String get walletFilterTransfersReceived => '받은 송금';

  @override
  String get walletFilterRepliesPaid => '답글에 지불';

  @override
  String get walletFilterRepliesEarned => '답글로 받음';

  @override
  String get walletFilterThreadCosts => '스레드 비용';

  @override
  String get walletFilterFlagCosts => '신고 수수료';

  @override
  String get seedTitle => '지갑 시드';

  @override
  String get seedWarning =>
      '이 시드를 가진 사람은 누구나 이 지갑의 토큰을 쓸 수 있습니다. murmur-node keygen으로 만든 키 파일과 같은 형식입니다.';

  @override
  String get done => '완료';

  @override
  String get removeWalletTitle => '지갑을 삭제할까요?';

  @override
  String get removeWalletBody =>
      '시드가 이 기기에서 삭제됩니다. 사본이 없으면 이 주소의 잔액은 모두 잃게 됩니다.';

  @override
  String get remove => '삭제';

  @override
  String get importWallet => '지갑 가져오기';

  @override
  String get importHelp =>
      '지갑의 시드를 입력하거나 붙여 넣으세요. 24개 단어 또는 16진수 64자입니다(예: murmur-node keygen으로 만든 키 파일 murmur.key의 내용. 그 주소로 채굴한 보상을 쓸 수 있습니다).';

  @override
  String get seed => '시드';

  @override
  String get import => '가져오기';

  @override
  String get seedInvalid => '시드는 24개 단어 또는 정확히 16진수 64자입니다.';

  @override
  String get walletIntro => '지갑은 보내는 트랜잭션에 서명합니다. 키는 이 기기에 남습니다.';

  @override
  String get createWallet => '새 지갑 만들기';

  @override
  String get importSeed => '시드 가져오기';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return '높이 $heightString에 블록이 없습니다 (최신 블록은 $tipString).';
  }

  @override
  String get searchInvalid => '블록 높이, 또는 64자 txid·블록 해시·주소를 입력하세요.';

  @override
  String get searchHint => '높이, txid, 블록 해시 또는 주소 검색';

  @override
  String get noBlocks => '아직 블록이 없습니다.';

  @override
  String blockTitle(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '블록 $heightString';
  }

  @override
  String txShortCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString건',
    );
    return '$_temp0';
  }

  @override
  String minerIs(String miner) {
    return '채굴자 $miner';
  }

  @override
  String get statNetwork => '네트워크';

  @override
  String get statHeight => '높이';

  @override
  String get statNodeHeight => '노드 높이';

  @override
  String get statNextReward => '다음 블록 보상';

  @override
  String rewardPlusFees(String amount) {
    return '$amount + 수수료';
  }

  @override
  String get statBurnPool => '소각 풀';

  @override
  String get statCirculating => '유통량';

  @override
  String get tip => '최신 블록';

  @override
  String get previousBlock => '이전 블록';

  @override
  String get nextBlock => '다음 블록';

  @override
  String get blockGone => '이 블록은 더 이상 주 체인에 없습니다.';

  @override
  String get hash => '해시';

  @override
  String get previous => '이전';

  @override
  String get time => '시간';

  @override
  String get confirmations => '확인 수';

  @override
  String get miner => '채굴자';

  @override
  String get reward => '보상';

  @override
  String get merkleRoot => '머클 루트';

  @override
  String get target => '목표값';

  @override
  String get nonce => '논스';

  @override
  String txCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '트랜잭션 $countString개',
      zero: '트랜잭션 없음',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => '내 주소';

  @override
  String get noTransactions => '트랜잭션이 없습니다.';

  @override
  String get sendToAddress => '이 주소로 보내기';

  @override
  String get threadGone => '이 스레드는 더 이상 체인에 없습니다.';

  @override
  String paidToThreadAuthor(String amount) {
    return '스레드 작성자에게 $amount 지불';
  }

  @override
  String get actionReply => '답글';

  @override
  String get actionFlag => '신고';

  @override
  String get flagged => '신고함';

  @override
  String get details => '세부 정보';

  @override
  String get txTitle => '트랜잭션';

  @override
  String get txNotFound =>
      '트랜잭션을 찾을 수 없습니다. 대기 목록에서 빠졌거나 체인 재구성으로 제거되었을 수 있습니다.';

  @override
  String refNotLocal(String txid) {
    return '트랜잭션 $txid (로컬 체인에 없음)';
  }

  @override
  String get flaggedMessage => '신고된 메시지';

  @override
  String get inReplyTo => '답글 대상';

  @override
  String get notThreadedExplain =>
      '이 상위 메시지를 지정하지만 그 스레드에 속하지 않습니다. 상위 메시지는 채굴된 스레드나 답글이어야 하고, 이 답글이 그 작성자에게 지불해야 합니다. 지불로만 계산됩니다.';

  @override
  String get message => '메시지';

  @override
  String get openThread => '스레드 열기';

  @override
  String get transactionId => '트랜잭션 ID';

  @override
  String get type => '유형';

  @override
  String get from => '보낸 사람';

  @override
  String get to => '받는 사람';

  @override
  String get burned => '소각됨';

  @override
  String burnedValue(String amount) {
    return '$amount (소각 풀을 통해 채굴자에게 돌아감)';
  }

  @override
  String get amount => '금액';

  @override
  String get fee => '수수료';

  @override
  String get contentHash => '내용 해시';

  @override
  String get contentSize => '내용 크기';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString바이트 ($salt바이트 솔트와 $messageString바이트 메시지)';
  }

  @override
  String get reports => '신고';

  @override
  String get repliesTo => '답글 대상';

  @override
  String get weight => '무게';

  @override
  String weightValue(int weight, String perByte) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString바이트 (바이트당 수수료 $perByte)';
  }

  @override
  String get publicKey => '공개 키';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '블록 $heightString에서 확인됨';
  }

  @override
  String confirmationCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '확인 $countString회',
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
      other: '블록 $countString개가 지나도록 확인되지 않음',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused =>
      '노드가 거부했을 수 있습니다(예: 채굴 전에 잔액이 바뀐 경우). 노드는 거부한 트랜잭션에 대해 알려 주지 않습니다.';

  @override
  String get sentWaiting => '보냄, 블록을 기다리는 중';

  @override
  String get submittedHere => '이 기기에서 제출했습니다.';

  @override
  String get pendingTitle => '대기 중';

  @override
  String get relayedPending => '노드가 전달했으며 아직 블록에 없습니다.';

  @override
  String get viewBlock => '블록 보기';

  @override
  String get newTransaction => '새 트랜잭션';

  @override
  String get flagMessage => '메시지 신고';

  @override
  String flaggingInfo(String author) {
    return '$author의 이 메시지를 신고합니다. 각 지갑은 한 메시지를 한 번만 신고할 수 있습니다. 신고를 어떻게 처리할지는 클라이언트가 정합니다.';
  }

  @override
  String replyingTo(String author) {
    return '$author에게 답글';
  }

  @override
  String explainThread(int total, int burn) {
    return '새 스레드를 시작합니다. 비용은 수수료의 $total배입니다. 수수료는 채굴자에게 가고, 수수료의 $burn배는 소각됩니다. 소각된 토큰은 이후 블록들에 걸쳐 채굴자에게 돌아갑니다.';
  }

  @override
  String get explainReply =>
      '답글은 스레드 작성자에게 최소한 수수료만큼 지불하고(더 줄 수도 있습니다), 채굴자에게 수수료를 냅니다.';

  @override
  String get explainTransfer => '메시지 없는 단순 토큰 송금입니다. 금액은 수수료 이상이어야 합니다.';

  @override
  String get recipientAddress => '받는 주소';

  @override
  String get enterAddress => '16진수 64자 주소를 입력하세요';

  @override
  String get payToAuthor => '스레드 작성자에게 지불';

  @override
  String get notAnAmount => '금액을 입력하세요';

  @override
  String atLeastFee(String fee) {
    return '수수료($fee) 이상';
  }

  @override
  String get feeToMiner => '수수료 (채굴자에게)';

  @override
  String suggestedFee(String fee) {
    return '권장: $fee';
  }

  @override
  String feeBelowSuggested(String fee) {
    return '권장 수수료($fee)보다 낮습니다. 블록에 들어가기까지 시간이 걸릴 수 있습니다.';
  }

  @override
  String feeAboveSuggested(String fee) {
    return '권장 수수료($fee)보다 높습니다. 채굴자에게 필요 이상을 제공합니다.';
  }

  @override
  String atLeastMin(String min) {
    return '$min 이상';
  }

  @override
  String bytesOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString바이트';
  }

  @override
  String tooLong(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '너무 깁니다: $countString바이트';
  }

  @override
  String get murmurEmoji => 'Murmur 이모지';

  @override
  String murmurEmojiHint(String example) {
    return 'Murmur에서만 그려집니다. 다른 앱은 $example처럼 이름을 표시합니다.';
  }

  @override
  String get sendingNeedsLive => '클라이언트가 연결되고 동기화되면 보낼 수 있습니다.';

  @override
  String get signAndSend => '서명하고 보내기';

  @override
  String get costFee => '수수료, 채굴자에게';

  @override
  String costBurn(int multiple) {
    return '소각: 수수료의 $multiple배';
  }

  @override
  String get costPaid => '받는 사람에게 지불';

  @override
  String get costTotal => '총비용';

  @override
  String get costAvailable => '사용 가능: 잔액에서 대기 중인 트랜잭션을 뺀 값';

  @override
  String get costRemaining => '보낸 후 남는 금액';

  @override
  String get checkingFees => '네트워크 수수료 확인 중…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '이 클라이언트가 본 것으로 추정했습니다(연결 후 대기 중 $countString건). 노드의 수수료 보고를 받을 수 없었습니다.';
  }

  @override
  String get use => '사용';

  @override
  String balanceBeforeAfter(String before, String after) {
    return '$before → $after';
  }

  @override
  String balanceBeforeAfterTooltip(String before, String after) {
    return '잔액: 이전 $before, 이후 $after';
  }

  @override
  String get loadingOlder => '이전 블록 불러오는 중…';

  @override
  String get blockLoading => '이 블록 불러오는 중…';

  @override
  String get txSearching => '아직 불러오는 블록에서 이 트랜잭션을 찾는 중…';

  @override
  String get storageBanner =>
      '이 기기에 체인 사본을 보관할까요? 그러면 다음 방문부터는 전부 다시 내려받지 않고 몇 초 만에 열립니다. 사본은 여기에만 있고 누구에게도 전송되지 않습니다. 쿠키도, 추적도 없습니다. 지갑 키와 설정은 앱이 작동하는 데 필요하므로 항상 이 기기에 보관됩니다.';

  @override
  String get storageAllow => '필요한 저장 허용';

  @override
  String get storageReject => '거부 (더 느림)';

  @override
  String get storageOn => '체인 로컬 사본: 켜짐';

  @override
  String get storageOff => '체인 로컬 사본: 꺼짐 (방문할 때마다 다시 내려받음)';

  @override
  String get storageTurnOn => '켜기';

  @override
  String get storageTurnOff => '끄고 삭제';

  @override
  String get checkingBalance => '노드에 확인하는 중…';

  @override
  String get errTampered => '연결이 변조되었거나 끊겼습니다. 메시지가 무결성 검사를 통과하지 못했습니다.';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '블록 $heightString에서 노드가 커밋한 상태가 이 클라이언트가 직접 계산한 체인과 일치하지 않습니다. 이 노드를 믿지 말고 다른 노드에 연결하세요.';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '노드 정보: 대기 중인 트랜잭션 $countString개.',
      zero: '노드 정보: 대기 중인 트랜잭션 없음.',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => '노드가 받아들여 전달했습니다.';

  @override
  String get statusRefused => '노드가 거부함';

  @override
  String get statusInvalid => '유효하지 않아 거절됨';

  @override
  String nodeReason(String reason) {
    return '노드 메시지: $reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '체인이 이 버전의 블록 $heightString 체크포인트로 이어지지 않습니다. 버전이 잘못되었거나 연결한 모든 노드가 잘못되었습니다. 중지했습니다. 이 체인의 어떤 것도 믿을 수 없습니다.';
  }

  @override
  String staleTip(String elapsed) {
    return '가장 최근 블록이 $elapsed에 만들어졌습니다. 이 노드가 뒤처졌거나 네트워크와 끊겼을 수 있습니다. 보이는 내용이 최신이 아닐 수 있습니다.';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return '블록 $heightString의 체크포인트에서 시작했습니다. 제네시스까지 헤더를 확인하는 중입니다(지금까지 $doneString개).';
  }

  @override
  String get licenses => '라이선스';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => '테스트넷: 토큰에는 가치가 없습니다';

  @override
  String get linkNodeRepo => '노드 및 프로토콜 소스';

  @override
  String get linkWhitepaper => '백서';

  @override
  String checkingHeaders(int done, int total) {
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '블록 헤더 확인 중: $totalString개 중 $doneString개';
  }

  @override
  String reconnectingIn(int seconds) {
    return '$seconds초 후 다시 시도합니다.';
  }

  @override
  String get languagesFilter => '언어';

  @override
  String get languageUndetected => '감지 안 됨';

  @override
  String get hideFlaggedThreads => '내가 신고한 스레드 숨기기';

  @override
  String get star => '별표';

  @override
  String get unstar => '별표 해제';

  @override
  String get starredOnly => '별표한 스레드만';

  @override
  String get localNodeRun => '이 컴퓨터에서 Murmur 노드 실행';

  @override
  String get localNodeExplain =>
      '컴퓨터가 직접 전체 체인을 확인하고, 전달을 돕고, 내 메시지를 계속 볼 수 있게 합니다. 체인은 최근 하루치만 보관하며, 1시간 확인 이후에는 다른 사람의 메시지를 보관하지 않습니다.';

  @override
  String get localNodeStarting => '노드 시작 중…';

  @override
  String localNodeRunning(String address) {
    return '노드가 $address에서 실행 중입니다. 앱은 계속 선택한 노드에서 읽습니다.';
  }

  @override
  String localNodeFailed(String reason) {
    return '노드가 멈췄습니다: $reason';
  }

  @override
  String get localNodeFailedUnknown => '노드가 예기치 않게 멈췄습니다.';

  @override
  String get localNodeFromCheckpoint => '최신 블록부터 시작합니다. 이전 블록은 나중에 확인합니다.';

  @override
  String localNodeCatchingUp(String height, String total) {
    return '체인 따라잡는 중: $total 중 블록 $height';
  }

  @override
  String localNodeCheckingHistory(String height, String total) {
    return '백그라운드에서 이전 블록 확인 중: $total 중 $height';
  }

  @override
  String get localNodeMine => '이 컴퓨터로 채굴';

  @override
  String get localNodeMineNote =>
      '채굴하면 지갑 주소로 보상이 지급되며, 전기를 쓰고 컴퓨터에 부하가 커집니다. 테스트넷에서 토큰은 테스트용일 뿐입니다.';

  @override
  String get localNodeMineNeedsWallet => '먼저 지갑을 만드세요. 채굴 보상은 그 주소로 지급됩니다.';

  @override
  String localNodeMinesTo(String name) {
    return '채굴 보상 지급 대상: **$name**';
  }

  @override
  String localNodeCpu(int pct) {
    return '프로세서 코어 하나의 최대 $pct%';
  }

  @override
  String get localNodeGpu => '그래픽 카드로 채굴';

  @override
  String get localNodeGpuNote =>
      '프로세서보다 훨씬 빠르지만 전기를 더 씁니다. 카드를 쓸 수 없으면 프로세서로 계속 채굴합니다.';

  @override
  String get localNodeGpuStarting => '그래픽 카드를 시작하는 중입니다. 그동안 프로세서가 채굴합니다.';

  @override
  String localNodeGpuMining(String device) {
    return '**$device**에서 채굴 중';
  }

  @override
  String get localNodeGpuMiningAny => '**그래픽 카드**에서 채굴 중';

  @override
  String get localNodeGpuUnavailable => '그래픽 카드를 쓸 수 없습니다. **프로세서로 계속 채굴합니다**.';

  @override
  String localNodeGpuDetail(String reason) {
    return '노드 메시지: $reason';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '스레드 $count개 숨김',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => '불러온 스레드 검색';

  @override
  String get noMatches => '일치하는 불러온 스레드가 없습니다.';

  @override
  String get timeJustNow => '방금';

  @override
  String timeMinutesAgo(int n) {
    return '$n분 전';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n시간 전';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n일 전';
  }

  @override
  String get nameAddress => '이름';

  @override
  String get aliasTitle => '이 주소에 이름 붙이기';

  @override
  String get aliasHelp => '이름은 이 기기에만 저장됩니다. 지우려면 비워 두세요.';

  @override
  String get save => '저장';

  @override
  String get mute => '뮤트';

  @override
  String get unmute => '뮤트 해제';

  @override
  String get mutedNote => '뮤트됨: 이 주소의 스레드와 답글은 이 기기에서 숨겨집니다.';

  @override
  String get earlierReplies => '이전 답글';

  @override
  String get quoteNotLoaded => '이전 답글 (탭하여 불러오기)';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '뮤트한 주소의 답글 $count개 숨김',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '새 답글 $count개',
    );
    return '$_temp0';
  }

  @override
  String get invitations => '초대장';

  @override
  String get createInvitations => '초대장 만들기';

  @override
  String get inviteHowMany => '카드 수';

  @override
  String get inviteFund => '카드 충전하기';

  @override
  String get inviteCardTitle => 'Murmur 초대장';

  @override
  String inviteCardSerial(int n, int total) {
    return '$n / $total';
  }

  @override
  String inviteCardFrom(String name) {
    return '보낸 사람: $name';
  }

  @override
  String get inviteCardHow => '코드를 스캔하거나 링크를 열어 Murmur에 참여하세요.';

  @override
  String get inviteClaimed => '받음';

  @override
  String get inviteChecking => '확인 중…';

  @override
  String get claimTitle => '초대받았습니다';

  @override
  String claimInvitedBy(String name) {
    return '초대한 사람: $name';
  }

  @override
  String claimHolds(String amount) {
    return '이 초대장에 담긴 금액: $amount. 첫 스레드를 시작하기에 충분합니다.';
  }

  @override
  String get claimCreateWallet => '지갑 만들고 받기';

  @override
  String get claimIntoWallet => '내 지갑으로 받기';

  @override
  String get claimDone => '받았습니다. 다음 블록과 함께 토큰이 지갑에 도착합니다.';

  @override
  String get claimEmpty => '이 초대장은 이미 받았거나 회수되었습니다.';

  @override
  String get claimWrongNetwork => '이 초대장은 연결된 노드와 다른 네트워크용입니다.';

  @override
  String get claimInvalid => '유효한 초대 코드가 아닙니다.';

  @override
  String get haveInvitation => '초대장이 있어요';

  @override
  String get inviteCodeField => '초대 코드 또는 링크';

  @override
  String get claim => '받기';

  @override
  String get cancelInvitation => '초대 취소';

  @override
  String get inviteCancelled => '취소됨';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '초대 $count개를 취소할까요?',
      one: '이 초대를 취소할까요?',
    );
    return '$_temp0';
  }

  @override
  String cancelInviteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '토큰이 돌아오고, 카드를 가진 사람들은 더 이상 받을 수 없습니다.',
      one: '토큰이 돌아오고, 카드를 가진 사람은 더 이상 받을 수 없습니다.',
    );
    return '$_temp0';
  }

  @override
  String get keepInvitation => '유지';

  @override
  String get printOne => '인쇄';

  @override
  String inviteDoneSection(int count) {
    return '받음 또는 취소됨 ($count)';
  }

  @override
  String get inviteEachLabel => '카드당';

  @override
  String get inviteEachCaption => '오늘 수수료로 스레드 다섯 개, 그리고 받을 때의 수수료.';

  @override
  String get inviteTotalLabel => '지불 금액';

  @override
  String get inviteTotalCaption => '수수료 포함 합계.';

  @override
  String get inviteWaitingState => '받기를 기다리는 중';

  @override
  String get inviteCardSlogan => '여기, 당신의 목소리를 위한 자리가 있습니다.';

  @override
  String get inviteCardJoin => '스캔하여 참여';

  @override
  String get share => '공유…';

  @override
  String get inviteDetailFunded => '충전됨';

  @override
  String get inviteDetailClaimedBy => '받은 사람';

  @override
  String get inviteDetailReceived => '받은 금액';

  @override
  String get inviteDetailCancelled => '취소됨: 토큰이 지갑으로 돌아왔습니다';

  @override
  String get inviteDetailReturned => '돌아온 금액';

  @override
  String get inviteDetailOnItsWay => '블록에 들어가는 중';

  @override
  String get seedConfirmTitle => '시드를 표시할까요?';

  @override
  String get seedConfirmBody =>
      '시드를 본 사람은 누구나 이 지갑에서 토큰을 쓸 수 있습니다. 다른 사람이 화면을 볼 수 없는지 확인하세요.';

  @override
  String get showAction => '표시';

  @override
  String get authReasonSeed => '지갑 시드를 보려면 본인임을 확인하세요';

  @override
  String get authReasonRemove => '이 지갑을 삭제하려면 본인임을 확인하세요';

  @override
  String get authFailed => '확인되지 않음: 아무것도 표시되거나 변경되지 않았습니다.';

  @override
  String get passphraseNewTitle => '암호 문구 정하기';

  @override
  String get passphraseNewWhat =>
      '**이 앱의 암호 문구는 하나입니다.** 이 기기에서 지갑 키와 초대 카드 코드를 암호화합니다.';

  @override
  String get passphraseNewWhen =>
      '보낼 때, 시드를 볼 때, 지갑을 삭제할 때, 그리고 카드를 표시·인쇄·취소할 때 **매번** 입력합니다.';

  @override
  String get passphraseNewForget =>
      '잊어버리면 **시드 백업**으로만 지갑을 되찾을 수 있고, 아직 건네지 않은 카드는 더 이상 표시하거나 취소할 수 없습니다.';

  @override
  String get passphraseField => '암호 문구';

  @override
  String get passphraseRepeat => '암호 문구 다시 입력';

  @override
  String passphraseTooShort(int min) {
    return '$min자 이상';
  }

  @override
  String get passphraseMismatch => '두 입력이 일치하지 않습니다';

  @override
  String get passphraseTitle => '암호 문구';

  @override
  String get wrongPassphrase => '암호 문구가 틀렸습니다: 아무것도 표시되거나 전송되지 않았습니다.';

  @override
  String get unlock => '잠금 해제';

  @override
  String get authReasonSend => '서명하고 보내려면 본인임을 확인하세요';

  @override
  String get authReasonNewWallet => '이 기기에서 지갑 키를 보호하세요';

  @override
  String get authReasonInvite => '카드를 충전하려면 본인임을 확인하세요';

  @override
  String get removeAnywayTitle => '확인 없이 삭제할까요?';

  @override
  String get removeAnywayBody =>
      '지갑의 잠금을 해제할 수 없었습니다. 삭제하면 이 기기에서 키가 지워지며, 시드 백업으로만 되찾을 수 있습니다.';

  @override
  String get protectionDevice => '이 기기의 잠금으로 암호화된 키';

  @override
  String get protectionPasskey => '이 기기의 패스키로 암호화된 키';

  @override
  String get protectionPassphrase => '암호 문구로 암호화된 키';

  @override
  String get protectionLegacy => '아직 암호화되지 않은 키: 다음 잠금 해제 때 암호화됩니다';

  @override
  String get confirmSendTitle => '서명 전에 확인하세요';

  @override
  String get confirmSendFinal =>
      '서명하면 노드로 전송됩니다. 되돌릴 수 없습니다. 한번 채굴되면 체인에 남습니다.';

  @override
  String signAndSendShortcut(String keys) {
    return '서명하고 보내기 ($keys)';
  }

  @override
  String get threadWithdrawnMine => '내가 철회함: 다른 사람에게 숨겨지고 Murmur 앱에서 텍스트가 삭제됨';

  @override
  String get threadWithdrawnMineNote =>
      '내 스레드를 신고하여 철회했습니다. Murmur 앱은 더 이상 다른 사람에게 보여 주지 않고, 이 기기를 포함해 텍스트를 삭제합니다. 노드는 텍스트와 답글 보관을 중단할 수 있습니다.';

  @override
  String get threadWithdrawnNote =>
      '작성자가 이 스레드를 신고하여 철회했습니다. Murmur 앱은 더 이상 목록에 표시하지 않고 텍스트를 삭제하며, 노드는 텍스트와 답글 보관을 중단할 수 있습니다.';

  @override
  String get flagOwnInfo =>
      '내 메시지입니다. 신고하면 철회됩니다. Murmur 앱은 다른 사람에게 보여 주지 않고 이 기기를 포함해 텍스트를 삭제하며, 노드는 텍스트와 답글 보관을 중단할 수 있습니다. 되돌릴 수 없습니다.';

  @override
  String get inviteFromTitle => '카드에 표시할 이름';

  @override
  String get inviteFromBody =>
      '각 카드에는 누가 보냈는지 표시됩니다. 카드는 초대한 지갑이 충전했으며, 지금 이 기기의 지갑과 다를 수 있습니다.';

  @override
  String get inviteFromOriginal => '초대한 지갑의 주소';

  @override
  String get inviteFromOriginalAlias => '초대한 지갑에 붙인 내 이름';

  @override
  String get inviteFromOriginalPublic => '초대한 지갑의 공개 이름';

  @override
  String get inviteFromCurrent => '이 지갑의 주소';

  @override
  String get inviteFromCurrentAlias => '이 지갑에 붙인 내 이름';

  @override
  String get inviteFromCurrentPublic => '이 지갑의 공개 이름';

  @override
  String get inviteFromCustom => '다른 텍스트';

  @override
  String get inviteFromCustomHint => '이름을 인쇄하지 않으려면 비워 두세요';

  @override
  String get inviteFromNotSet => '이 기기에서 붙인 이름 없음';

  @override
  String get inviteFromMixed => '선택한 카드마다 다름';

  @override
  String get inviteFromChecking => '아직 체인에서 찾는 중';

  @override
  String get cancelReturnTo => '토큰을 보낼 곳';

  @override
  String get cancelToFunder => '충전한 지갑';

  @override
  String get cancelToCurrent => '이 지갑';

  @override
  String get publicName => '공개 이름';

  @override
  String get publicNameNone => '알려진 이름 없음';

  @override
  String get publicNameSet => '공개 이름 설정';

  @override
  String get publicNameField => '이름';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '최대 $maxString바이트';
  }

  @override
  String get aliasBadCharacter => '보이지 않는 문자나 제어 문자는 쓸 수 없습니다';

  @override
  String get aliasEdgeSpace => '처음이나 끝에 공백을 둘 수 없습니다';

  @override
  String aliasSetTo(String name) {
    return '공개 이름: $name';
  }

  @override
  String get aliasCleared => '공개 이름 지움';

  @override
  String profileSetTo(String name) {
    return '공개 이름과 사진: $name';
  }

  @override
  String get profilePictureOnly => '이름 없는 공개 사진';

  @override
  String get nonTextMessage => '(텍스트 아님: 앱 규약용 데이터)';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return '공개 이름을 게시합니다. 새 스레드처럼 비용은 수수료의 $totalString배입니다. 수수료는 채굴자에게 가고, 수수료의 $burnString배는 소각됩니다.';
  }

  @override
  String get inviteFromNoPublic => '알려진 공개 이름 없음';

  @override
  String get starredTitle => '별표';

  @override
  String get noStarred =>
      '아직 별표한 항목이 없습니다. 스레드, 메시지, 사람의 페이지에서 별표하면 여기에 표시됩니다.';

  @override
  String get starredGone => '더 이상 체인에 없음';

  @override
  String get feeSuggestedLabel => '권장 수수료';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString바이트 기준';
  }

  @override
  String get feeRoom => '블록에 여유가 있음';

  @override
  String get feeFull => '블록이 가득 참';

  @override
  String get feeNextBlock => '다음 블록';

  @override
  String get feePoolEntry => '대기열 진입';

  @override
  String get feeMinimum => '최소';

  @override
  String get feeWhy => '이 수수료인 이유';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**수수료는 바이트 단위입니다**: $baseString바이트에 메시지가 더해집니다. 블록이 가득 차면 긴 메시지일수록 비쌉니다.';
  }

  @override
  String feeRecentPoint(String lowest, String median) {
    return '**최근 블록**은 수수료를 **$lowest**까지 낮게 받았습니다 (중앙값 $median).';
  }

  @override
  String get feeRecentNonePoint => '**최근 블록**에는 트랜잭션이 없었습니다.';

  @override
  String get inviteNoExpiryPoint => '**만료 없음**: 누군가 받을 때까지 카드는 유효합니다.';

  @override
  String get inviteCancelPoint => '**언제든 취소 가능**: 토큰이 돌아옵니다.';

  @override
  String get invitePublicPoint =>
      '**공개됨**: 내가 각 카드를 충전했다는 것과 어떤 지갑이 받았는지 체인에 드러납니다.';

  @override
  String get inviteCashPoint =>
      '**코드를 가진 사람이면 누구나** 카드를 받을 수 있습니다. 건네기 전까지 카드를 비공개로 보관하세요.';

  @override
  String get inviteLocalPoint =>
      '**이 기기에만 보관됩니다.** 데이터가 지워지거나 앱이 삭제되면 코드는 **영구히 사라지고**, 아직 건네지 않은 카드의 토큰도 함께 사라집니다.';

  @override
  String get publicNameIntro => '공개 이름은 Murmur 앱에서 **주소 옆에** 표시됩니다.';

  @override
  String publicNameShownAs(String name) {
    return '표시: **$name**';
  }

  @override
  String get publicNameNotUnique =>
      '**고유하지 않음**: 누구나 같은 이름을 고를 수 있습니다. 옆의 주소로 사람을 구별합니다.';

  @override
  String get publicNameCost => '설정하거나 바꿀 때마다 **새 스레드와 같은 비용**이 듭니다.';

  @override
  String get publicNameRemovable =>
      '**체인의 메시지입니다**: 어느 노드든 삭제할 수 있고, 그러면 사라집니다.';

  @override
  String get publicNameClear => '지우려면 **비워 두세요**.';

  @override
  String get publicNamePicture => '사진';

  @override
  String get pictureFromPhotos => '사진 보관함에서';

  @override
  String get pictureFromFiles => '파일에서';

  @override
  String get pictureChoose => '사진 선택';

  @override
  String get pictureRemove => '사진 삭제';

  @override
  String pictureTooLarge(String size) {
    return '파일이 너무 큽니다. ${size}MB 미만의 파일을 선택하세요.';
  }

  @override
  String get pictureUnreadable => '이 파일을 사진으로 읽을 수 없습니다.';

  @override
  String get picturePoint => '**32 × 32 픽셀, 16색**, 주소 표식 대신 표시됩니다.';

  @override
  String get pictureCost => '사진을 넣으면 **비용이 약 세 배**입니다.';

  @override
  String get passkeyNoPrfTitle => '이 패스키 관리자는 지갑을 보호할 수 없습니다';

  @override
  String get passkeyNoPrfWhy =>
      '**암호화할 수 없습니다.** 지갑 키를 잠그려면 패스키 관리자가 패스키에서 키를 파생해야 합니다(WebAuthn PRF). 선택한 관리자는 이를 지원하지 않습니다.';

  @override
  String get passkeyNoPrfTry =>
      'Apple 암호나 Google 비밀번호 관리자 같은 **다른 관리자를 사용해 보거나**, **암호 문구**로 지갑을 보호하세요.';

  @override
  String get passkeyNoPrfLeftover =>
      '방금 저장된 패스키(**Murmur wallet**)는 아무것도 잠금 해제하지 않습니다. 그 관리자에서 삭제해도 됩니다.';

  @override
  String get passkeyTryAnother => '다른 패스키 관리자 사용';

  @override
  String get passkeyUsePassphrase => '암호 문구 사용';

  @override
  String inviteDetailCancelledTo(String name) {
    return '취소됨: 토큰을 $name에게 보냄';
  }

  @override
  String get seedNewTitle => '지갑 시드를 저장하세요';

  @override
  String get seedNewKeep => '종이에 적거나 비밀번호 관리자에 넣어, 이 기기와 떨어진 **안전한 곳에 보관하세요**.';

  @override
  String get seedNewOnlyWay =>
      '이 기기를 잃어버리거나 암호 문구를 잊었을 때 이 지갑으로 돌아갈 **유일한 방법**입니다. 아무도 대신 복구해 줄 수 없습니다.';

  @override
  String get seedNewSecret =>
      '**시드를 가진 사람이 지갑을 통제합니다.** 절대 공유하지 말고, 시드를 요구하는 사이트에 절대 입력하지 마세요.';

  @override
  String get seedNewSaved => '시드를 저장했습니다';

  @override
  String get seedAsWords => '24개 단어';

  @override
  String get seedAsHex => '64자';

  @override
  String get seedEitherForm => '둘 다 같은 시드입니다. 하나만 있어도 됩니다.';

  @override
  String get copyWords => '단어 복사';

  @override
  String get copyCharacters => '문자 복사';

  @override
  String get seedOrWords => '시드: 24개 단어 또는 64자';

  @override
  String seedUnknownWord(String word) {
    return '시드 단어 목록에 없는 단어입니다: “$word”. 철자를 확인하세요.';
  }

  @override
  String get seedBadChecksum =>
      '이 24개 단어로는 시드가 만들어지지 않습니다. 그중 하나가 틀렸거나 순서가 잘못되었습니다.';

  @override
  String get qrCode => 'QR 코드';

  @override
  String get addressQrHint => '스캔하면 Murmur에서 이 주소가 열립니다.';

  @override
  String get starredPeople => '사람';

  @override
  String get starredThreads => '메시지';

  @override
  String get noStarredThreads => '별표한 스레드나 메시지가 없습니다. 페이지에서 별표하면 여기에 표시됩니다.';

  @override
  String get noStarredPeople => '별표한 사람이 없습니다. 그 사람의 페이지에서 별표하면 여기에 표시됩니다.';

  @override
  String get newActivity => '새 활동';

  @override
  String starredNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '새 활동이 있는 별표 항목 $count개',
    );
    return '$_temp0';
  }

  @override
  String get authReasonCards => '초대 카드 잠금을 해제하려면 본인임을 확인하세요';

  @override
  String get inviteLockedPoint =>
      '**코드는 암호화되어 저장됩니다.** 카드를 표시·인쇄·취소하려면 **잠금 해제**가 필요합니다.';

  @override
  String get notifications => '알림';

  @override
  String get notifyReplies => '나에게 온 답글과 응답';

  @override
  String get notifyMentions => '나를 멘션한 메시지';

  @override
  String get notifyStarred => '별표한 항목의 새 소식';

  @override
  String get notifyNeedsWallet => '이 기기에 지갑이 필요합니다';

  @override
  String get notifyDenied => '시스템 설정에서 Murmur의 알림이 꺼져 있습니다.';

  @override
  String get notifyPointLocal =>
      '선택한 노드에서 **이 앱이 직접 확인합니다**. Google, Apple 등 누구도 거치지 않습니다.';

  @override
  String get notifyPointBackground =>
      '앱이 닫혀 있을 때는 시스템이 허용하는 대로 **약 15분마다** 확인합니다.';

  @override
  String get notifyPointOpen => '**앱이 열려 있고** 화면 앞에 있지 않을 때만 알립니다.';

  @override
  String get notifyPointLockScreen => '잠금 화면에서는 **내용이 숨겨집니다**.';

  @override
  String get notifyChannel => '메시지';

  @override
  String get notifyOpen => '열기';

  @override
  String notifyReply(String name) {
    return '$name님이 내 스레드에 답글을 남겼습니다';
  }

  @override
  String notifyAnswer(String name) {
    return '$name님이 나에게 답했습니다';
  }

  @override
  String notifyMention(String name) {
    return '$name님이 나를 멘션했습니다';
  }

  @override
  String notifyStarredReply(String name) {
    return '$name님이 별표한 스레드에 답글을 남겼습니다';
  }

  @override
  String notifyStarredPerson(String name) {
    return '$name님의 새 메시지';
  }

  @override
  String notifyMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '새 메시지 $countString개 더',
    );
    return '$_temp0';
  }

  @override
  String get faceIdReason => '지갑 키를 사용하거나 표시하기 전에 본인임을 확인하세요.';

  @override
  String get refresh => '새로고침';

  @override
  String get markAllRead => '모두 읽음으로 표시';

  @override
  String get newAboveLastVisit => '위: 지난 방문 이후 새 항목';

  @override
  String get publicNameAndPicture => '공개 이름과 사진';

  @override
  String get publicNameAndPictureSet => '공개 이름과 사진 설정';

  @override
  String get publicNameStandOut => '**눈에 띄세요**: 다른 사람이 주소 옆에서 보는 이름과 사진입니다.';

  @override
  String get pictureLarger => '사진 크게 보기';

  @override
  String get keepMessagesAvailable => '내 메시지를 계속 제공';

  @override
  String get keepMessagesAvailableExplain =>
      '**앱이 열려 있는 동안**, 노드가 더 이상 보관하지 않는 내 메시지를 독자가 나에게서 받아 갑니다. **내 것만**, 다른 사람의 것은 절대 아닙니다.';

  @override
  String errBadSignature(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '블록 $heightString에 서명이 유효하지 않은 트랜잭션이 있습니다. 이 노드의 체인은 모든 노드가 적용하는 규칙을 어깁니다. 이 노드를 믿지 말고 다른 노드에 연결하세요.';
  }

  @override
  String receivedOmitted(String count) {
    return '다른 사람들이 나와 관련해 한 일 중 일부를 **노드가 빠뜨렸습니다** ($count). 블록에서 직접 찾아 그대로 표시합니다.';
  }

  @override
  String get keyringUnavailable =>
      '시스템 키링이 잠겨 있고 암호를 물어볼 수 없어 이 기기에 지갑을 저장할 수 없습니다. 키링 잠금을 해제하고(보통 데스크톱에 로그인하면 됩니다) Murmur를 다시 시작하세요.';
}
