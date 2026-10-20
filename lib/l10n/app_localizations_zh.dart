// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => '话题';

  @override
  String get kindReply => '回复';

  @override
  String get kindTransfer => '转账';

  @override
  String get kindFlag => '举报';

  @override
  String get contentUnavailable => '（内容不可用：节点没有该内容）';

  @override
  String get contentWithdrawn => '（已被作者撤回）';

  @override
  String get contentLoading => '（正在加载消息…）';

  @override
  String get pending => '待确认';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String replyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 条回复',
      zero: '没有回复',
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
      other: '$countString 条举报',
      zero: '没有举报',
    );
    return '$_temp0';
  }

  @override
  String transferOf(String amount) {
    return '转账 $amount';
  }

  @override
  String flagOn(String text) {
    return '举报“$text”';
  }

  @override
  String flagOnTx(String txid) {
    return '举报 $txid';
  }

  @override
  String get replyNotThreaded => '回复（不属于任何话题）';

  @override
  String routeFrom(String address) {
    return '来自 $address';
  }

  @override
  String routeFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String errUnreachable(String detail) {
    return '无法连接节点：$detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return '无法连接 $url 上的 WebSocket 网桥。请用以下命令启动：dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return '连接错误：$detail';
  }

  @override
  String get errClosed => '节点关闭了连接。';

  @override
  String get errTimeout => '节点未能及时响应。';

  @override
  String errProtocol(String detail) {
    return '协议错误：$detail';
  }

  @override
  String errVersion(int node, int ours) {
    return '节点使用协议 $node；本客户端使用协议 $ours。';
  }

  @override
  String errSyncFailed(String cause) {
    return '同步失败：$cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return '已忽略一个转发的区块：$detail';
  }

  @override
  String get probFeeTooLow => '手续费低于网络的最低要求。';

  @override
  String get probMalformed => '此交易格式不正确。';

  @override
  String get probNeedsMessage => '请输入消息。';

  @override
  String get probNeedsRecipient => '请输入收款人。';

  @override
  String probAmountBelowFee(String fee) {
    return '金额不能低于手续费（$fee）。';
  }

  @override
  String get probReplyParentNotMined => '只能回复已经打包进区块的话题或回复。';

  @override
  String get probFlagNotMessage => '只能举报话题和回复。';

  @override
  String get probAlreadyFlagged => '此钱包已经举报过该消息。';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return '消息为 $lengthString 字节；上限为 $limitString。';
  }

  @override
  String probInsufficientBalance(String needed, String available) {
    return '余额不足：需要 $needed，可用 $available（已确认余额减去待确认交易）。';
  }

  @override
  String get probNotLive => '请等待客户端连接并完成同步。';

  @override
  String get probConnectionLost => '与节点的连接已断开。';

  @override
  String get probDuplicate => '这一秒内已经发送过一笔相同的交易。';

  @override
  String get tabThreads => '话题';

  @override
  String get tabMessages => '消息';

  @override
  String get tabWallet => '钱包';

  @override
  String get tabChain => '区块链';

  @override
  String get newThread => '新话题';

  @override
  String get createWalletFirst => '请先创建或导入钱包。';

  @override
  String get syncNow => '立即同步';

  @override
  String get reconnect => '重新连接';

  @override
  String get changeNode => '更换节点';

  @override
  String get unknownNetwork =>
      '此节点所在的网络客户端无法识别。无法检查其难度调整，且区块奖励按白皮书数值计算，因此矿工余额可能不准确。';

  @override
  String get linkOffline => '离线';

  @override
  String get linkConnecting => '正在连接…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return '正在同步 $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '实时 · $heightString';
  }

  @override
  String get connectToNode => '连接到节点';

  @override
  String nodeAt(String address) {
    return '节点 $address';
  }

  @override
  String get language => '语言';

  @override
  String get systemLanguage => '系统语言';

  @override
  String get lightMode => '浅色模式';

  @override
  String get darkMode => '深色模式';

  @override
  String get node => '节点';

  @override
  String get connectHelpBridge =>
      '在浏览器中，客户端通过 WebSocket 连接：连接到节点的 WebSocket 地址（例如 node.murmur.info，端口 443，经 TLS），或连接到本地网桥（dart run tool/ws_bridge.dart，端口 7880）。';

  @override
  String get connectHelpNative =>
      'murmur-node 的点对点地址（其 --port，默认 7878）。控制端口（7879）无法使用。端口 443 连接位于安全 WebSocket 之后的节点，例如 node.murmur.info。';

  @override
  String get host => '主机';

  @override
  String get port => '端口';

  @override
  String get required => '必填';

  @override
  String get enterPort => '请输入端口号';

  @override
  String get disconnect => '断开连接';

  @override
  String get cancel => '取消';

  @override
  String get connect => '连接';

  @override
  String get syncingChain => '正在同步区块链…';

  @override
  String get noThreads => '还没有话题。点击“新话题”发起一个。';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '截至区块 $heightString（$time，$elapsed）';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此后新增 $countString 个区块',
      zero: '已是最新',
    );
    return '$_temp0';
  }

  @override
  String agoSeconds(int s) {
    return '$s 秒前';
  }

  @override
  String agoMinutes(int m, int s) {
    return '$m 分 $s 秒前';
  }

  @override
  String agoHours(int h, int m) {
    return '$h 小时 $m 分前';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return '$dString 天 $h 小时前';
  }

  @override
  String threadStarted(String time) {
    return '$time发起';
  }

  @override
  String threadLastReply(String time) {
    return '最后回复 $time';
  }

  @override
  String get messagesNeedWallet => '请在“钱包”标签页中创建或导入钱包，以查看你的消息。';

  @override
  String get noMessages => '没有符合这些筛选条件的消息。';

  @override
  String get filterThreads => '我的话题';

  @override
  String get filterRepliesSent => '已发回复';

  @override
  String get filterRepliesReceived => '收到的回复';

  @override
  String get filterFlagsSent => '我的举报';

  @override
  String get filterFlagsReceived => '收到的举报';

  @override
  String get filterMentions => '提及';

  @override
  String get mentionsLabel => '提及';

  @override
  String get mentionPublicPoint => '**提及是公开的：**任何人都能看到你提到了谁。';

  @override
  String mentionsMax(int max) {
    return '每条消息最多提及$max人';
  }

  @override
  String get balance => '余额';

  @override
  String pendingCommitted(String amount) {
    return '$amount 已用于待确认交易';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已挖出 $countString 个区块',
      zero: '未挖出区块',
    );
    return '$_temp0';
  }

  @override
  String get address => '地址';

  @override
  String get showSeed => '显示种子';

  @override
  String get removeWallet => '移除钱包';

  @override
  String get history => '历史记录';

  @override
  String get filters => '筛选';

  @override
  String get noHistory => '没有符合这些筛选条件的交易。';

  @override
  String get walletFilterTransfersSent => '转出';

  @override
  String get walletFilterTransfersReceived => '转入';

  @override
  String get walletFilterRepliesPaid => '回复支出';

  @override
  String get walletFilterRepliesEarned => '回复收入';

  @override
  String get walletFilterThreadCosts => '话题费用';

  @override
  String get walletFilterFlagCosts => '举报手续费';

  @override
  String get seedTitle => '钱包种子';

  @override
  String get seedWarning =>
      '任何拥有此种子的人都能动用这个钱包。它与 murmur-node keygen 生成的密钥文件格式相同。';

  @override
  String get done => '完成';

  @override
  String get removeWalletTitle => '移除钱包？';

  @override
  String get removeWalletBody => '种子将从此设备上删除。如果没有备份，此地址上的余额将全部丢失。';

  @override
  String get remove => '移除';

  @override
  String get importWallet => '导入钱包';

  @override
  String get importHelp =>
      '输入或粘贴钱包的种子：它的 24 个单词，或 64 个十六进制字符（例如用 murmur-node keygen 生成的密钥文件 murmur.key 的内容，以使用挖到该地址的奖励）。';

  @override
  String get seed => '种子';

  @override
  String get import => '导入';

  @override
  String get seedInvalid => '种子是 24 个单词，或恰好 64 个十六进制字符。';

  @override
  String get walletIntro => '钱包为你发送的交易签名。其密钥保留在此设备上。';

  @override
  String get createWallet => '创建新钱包';

  @override
  String get importSeed => '导入种子';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return '高度 $heightString 处没有区块（最高为 $tipString）。';
  }

  @override
  String get searchInvalid => '请输入区块高度，或 64 个字符的交易 ID、区块哈希或地址。';

  @override
  String get searchHint => '搜索高度、交易 ID、区块哈希或地址';

  @override
  String get noBlocks => '还没有区块。';

  @override
  String blockTitle(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '区块 $heightString';
  }

  @override
  String txShortCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 笔交易',
    );
    return '$_temp0';
  }

  @override
  String minerIs(String miner) {
    return '矿工 $miner';
  }

  @override
  String get statNetwork => '网络';

  @override
  String get statHeight => '高度';

  @override
  String get statNodeHeight => '节点高度';

  @override
  String get statNextReward => '下一区块奖励';

  @override
  String rewardPlusFees(String amount) {
    return '$amount + 手续费';
  }

  @override
  String get statBurnPool => '销毁池';

  @override
  String get statCirculating => '流通量';

  @override
  String get tip => '最新区块';

  @override
  String get previousBlock => '上一个区块';

  @override
  String get nextBlock => '下一个区块';

  @override
  String get blockGone => '此区块已不在最佳链上。';

  @override
  String get hash => '哈希';

  @override
  String get previous => '上一个';

  @override
  String get time => '时间';

  @override
  String get confirmations => '确认数';

  @override
  String get miner => '矿工';

  @override
  String get reward => '奖励';

  @override
  String get merkleRoot => '默克尔根';

  @override
  String get target => '目标值';

  @override
  String get nonce => '随机数';

  @override
  String txCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 笔交易',
      zero: '没有交易',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => '你的地址';

  @override
  String get noTransactions => '没有交易。';

  @override
  String get sendToAddress => '向此地址转账';

  @override
  String get threadGone => '此话题已不在链上。';

  @override
  String paidToThreadAuthor(String amount) {
    return '向话题作者支付了 $amount';
  }

  @override
  String get actionReply => '回复';

  @override
  String get actionFlag => '举报';

  @override
  String get flagged => '已举报';

  @override
  String get details => '详情';

  @override
  String get txTitle => '交易';

  @override
  String get txNotFound => '找不到该交易。它可能已从待确认列表中丢弃，或因链重组而被移除。';

  @override
  String refNotLocal(String txid) {
    return '交易 $txid（不在本地链上）';
  }

  @override
  String get flaggedMessage => '被举报的消息';

  @override
  String get inReplyTo => '回复给';

  @override
  String get notThreadedExplain =>
      '指向这条消息，但不属于它的话题：该消息必须是已上链的话题或回复，且此回复必须向其作者付款。它只算作一笔付款。';

  @override
  String get message => '消息';

  @override
  String get openThread => '打开话题';

  @override
  String get transactionId => '交易 ID';

  @override
  String get type => '类型';

  @override
  String get from => '付款方';

  @override
  String get to => '收款方';

  @override
  String get burned => '销毁';

  @override
  String burnedValue(String amount) {
    return '$amount（通过销毁池返还给矿工）';
  }

  @override
  String get amount => '金额';

  @override
  String get fee => '手续费';

  @override
  String get contentHash => '内容哈希';

  @override
  String get contentSize => '内容大小';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString 字节（$salt 字节的盐和 $messageString 字节的消息）';
  }

  @override
  String get reports => '举报对象';

  @override
  String get repliesTo => '回复对象';

  @override
  String get weight => '权重';

  @override
  String weightValue(int weight, String perByte) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString 字节（每字节手续费 $perByte）';
  }

  @override
  String get publicKey => '公钥';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '已在区块 $heightString 中确认';
  }

  @override
  String confirmationCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 次确认',
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
      other: '$countString 个区块后仍未确认',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused => '节点可能拒绝了它（例如在打包前余额发生了变化）。节点不会反馈被拒绝的交易。';

  @override
  String get sentWaiting => '已发送，等待打包';

  @override
  String get submittedHere => '从此设备提交。';

  @override
  String get pendingTitle => '待确认';

  @override
  String get relayedPending => '由节点转发，尚未进入区块。';

  @override
  String get viewBlock => '查看区块';

  @override
  String get newTransaction => '新交易';

  @override
  String get flagMessage => '举报消息';

  @override
  String flaggingInfo(String author) {
    return '你正在举报 $author 的这条消息。每个钱包对同一条消息只能举报一次。如何处理举报由各客户端自行决定。';
  }

  @override
  String replyingTo(String author) {
    return '回复 $author';
  }

  @override
  String explainThread(int total, int burn) {
    return '发起一个新话题。费用为手续费的 $total 倍：手续费归矿工，另有手续费的 $burn 倍被销毁。销毁的代币会在之后的区块中返还给矿工。';
  }

  @override
  String get explainReply => '你的回复至少向话题作者支付一份手续费（可以多给作为小费），另外还要向矿工支付手续费。';

  @override
  String get explainTransfer => '不带消息的普通代币转账。金额不能低于手续费。';

  @override
  String get recipientAddress => '收款地址';

  @override
  String get enterAddress => '请输入 64 个字符的十六进制地址';

  @override
  String get payToAuthor => '支付给话题作者';

  @override
  String get notAnAmount => '请输入数量';

  @override
  String atLeastFee(String fee) {
    return '不低于手续费（$fee）';
  }

  @override
  String get feeToMiner => '手续费（归矿工）';

  @override
  String suggestedFee(String fee) {
    return '建议：$fee';
  }

  @override
  String feeBelowSuggested(String fee) {
    return '低于建议手续费（$fee）：可能要过一段时间才能进入区块。';
  }

  @override
  String feeAboveSuggested(String fee) {
    return '高于建议手续费（$fee）：你给矿工的比所需的多。';
  }

  @override
  String atLeastMin(String min) {
    return '至少 $min';
  }

  @override
  String bytesOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString 字节';
  }

  @override
  String tooLong(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '太长：$countString 字节';
  }

  @override
  String get murmurEmoji => 'Murmur 表情';

  @override
  String murmurEmojiHint(String example) {
    return '仅在 Murmur 中显示为图形。其他应用会显示名称，例如 $example。';
  }

  @override
  String get sendingNeedsLive => '客户端连接并同步完成后即可发送。';

  @override
  String get signAndSend => '签名并发送';

  @override
  String get costFee => '手续费，归矿工';

  @override
  String costBurn(int multiple) {
    return '销毁：手续费的 $multiple 倍';
  }

  @override
  String get costPaid => '支付给收款人';

  @override
  String get costTotal => '总费用';

  @override
  String get costAvailable => '可用：余额减去待确认交易';

  @override
  String get costRemaining => '发送后剩余';

  @override
  String get checkingFees => '正在查询网络手续费…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '根据本客户端所见估算（自连接以来 $countString 笔待确认）；节点自身的手续费报告不可用。';
  }

  @override
  String get use => '使用';

  @override
  String balanceBeforeAfter(String before, String after) {
    return '$before → $after';
  }

  @override
  String balanceBeforeAfterTooltip(String before, String after) {
    return '余额：之前 $before，之后 $after';
  }

  @override
  String get loadingOlder => '正在加载更早的区块…';

  @override
  String get blockLoading => '正在加载此区块…';

  @override
  String get txSearching => '正在尚未加载完的区块中查找此交易…';

  @override
  String get storageBanner =>
      '要在此设备上保留一份链的副本吗？这样之后打开只需几秒，无需重新下载全部数据。副本只保存在这里，绝不会发送给任何人：没有 Cookie，也没有跟踪。你的钱包密钥和设置始终保存在此设备上，因为应用运行需要它们。';

  @override
  String get storageAllow => '允许必要的存储';

  @override
  String get storageReject => '拒绝（较慢）';

  @override
  String get storageOn => '链的本地副本：已开启';

  @override
  String get storageOff => '链的本地副本：已关闭（每次访问都会重新下载）';

  @override
  String get storageTurnOn => '开启';

  @override
  String get storageTurnOff => '关闭并删除';

  @override
  String get checkingBalance => '正在向节点核实…';

  @override
  String get errTampered => '连接被篡改或中断：有一条消息未通过完整性校验。';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '节点在区块 $heightString 承诺的状态与本客户端对链的统计不符。请勿信任此节点，改为连接其他节点。';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '来自节点：$countString 笔待确认交易。',
      zero: '来自节点：没有待确认交易。',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => '节点已接受并转发。';

  @override
  String get statusRefused => '被节点拒绝';

  @override
  String get statusInvalid => '因无效被拒绝';

  @override
  String nodeReason(String reason) {
    return '节点称：$reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return '链没有通向此版本在区块 $heightString 的检查点：要么版本有误，要么所连接的所有节点都有误。已停止；其中的内容都不可信。';
  }

  @override
  String staleTip(String elapsed) {
    return '最新区块来自 $elapsed：此节点可能落后或与网络断开。你看到的内容可能已过时。';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return '已从区块 $heightString 的检查点开始；正在向创世区块回溯校验区块头（目前 $doneString 个）。';
  }

  @override
  String get licenses => '许可证';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => '测试网：代币没有价值';

  @override
  String get linkNodeRepo => '节点与协议源代码';

  @override
  String get linkWhitepaper => '白皮书';

  @override
  String checkingHeaders(int done, int total) {
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '正在检查区块头：$doneString / $totalString';
  }

  @override
  String reconnectingIn(int seconds) {
    return '$seconds 秒后重试。';
  }

  @override
  String get languagesFilter => '语言';

  @override
  String get languageUndetected => '未识别';

  @override
  String get hideFlaggedThreads => '隐藏我举报过的话题';

  @override
  String get star => '加星标';

  @override
  String get unstar => '取消星标';

  @override
  String get starredOnly => '只看加星标的话题';

  @override
  String get localNodeRun => '在这台电脑上运行 Murmur 节点';

  @override
  String get localNodeExplain =>
      '你的电脑会自行校验区块链、帮助传播，并保持你自己的消息可用。超过一小时的校验期后，它不保留任何其他人的消息。';

  @override
  String get localNodeStarting => '正在启动节点…';

  @override
  String localNodeRunning(String address) {
    return '节点正在 $address 运行。应用仍从你选择的节点读取。';
  }

  @override
  String localNodeFailed(String reason) {
    return '节点已停止：$reason';
  }

  @override
  String get localNodeFailedUnknown => '节点意外停止。';

  @override
  String get localNodeMine => '用这台电脑挖矿';

  @override
  String get localNodeMineNote => '挖矿收益付给你的钱包地址，会耗电并让电脑更吃力。在测试网上，代币仅供测试。';

  @override
  String get localNodeMineNeedsWallet => '请先创建钱包：挖矿收益付给它的地址。';

  @override
  String localNodeMinesTo(String name) {
    return '挖矿收益付给 **$name**';
  }

  @override
  String localNodeCpu(int pct) {
    return '最多使用一个处理器核心的 $pct%';
  }

  @override
  String get localNodeGpu => '用显卡挖矿';

  @override
  String get localNodeGpuNote => '比处理器快得多，也更耗电。显卡无法使用时，改用处理器继续挖矿。';

  @override
  String get localNodeGpuStarting => '正在启动显卡。此时由处理器挖矿。';

  @override
  String localNodeGpuMining(String device) {
    return '正在用 **$device** 挖矿';
  }

  @override
  String get localNodeGpuMiningAny => '正在用**显卡**挖矿';

  @override
  String get localNodeGpuUnavailable => '显卡无法使用：**改用处理器继续挖矿**。';

  @override
  String localNodeGpuDetail(String reason) {
    return '节点的说明：$reason';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已隐藏 $count 个话题',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => '搜索已加载的话题';

  @override
  String get noMatches => '没有匹配的已加载话题。';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int n) {
    return '$n 分钟前';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n 小时前';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n 天前';
  }

  @override
  String get nameAddress => '名称';

  @override
  String get aliasTitle => '为此地址命名';

  @override
  String get aliasHelp => '名称只保存在此设备上。留空即可删除。';

  @override
  String get save => '保存';

  @override
  String get mute => '屏蔽';

  @override
  String get unmute => '取消屏蔽';

  @override
  String get mutedNote => '已屏蔽：其话题和回复在此设备上隐藏。';

  @override
  String get earlierReplies => '更早的回复';

  @override
  String get quoteNotLoaded => '更早的一条回复（点击加载）';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已隐藏 $count 条来自被屏蔽地址的回复',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条新回复',
    );
    return '$_temp0';
  }

  @override
  String get invitations => '邀请';

  @override
  String get createInvitations => '创建邀请';

  @override
  String get inviteHowMany => '卡片数量';

  @override
  String get inviteFund => '为卡片注资';

  @override
  String get inviteCardTitle => 'Murmur 邀请';

  @override
  String inviteCardSerial(int n, int total) {
    return '第 $n 张，共 $total 张';
  }

  @override
  String inviteCardFrom(String name) {
    return '来自 $name';
  }

  @override
  String get inviteCardHow => '扫描二维码或打开链接加入 Murmur。';

  @override
  String get inviteClaimed => '已领取';

  @override
  String get inviteChecking => '正在检查…';

  @override
  String get claimTitle => '你受到了邀请';

  @override
  String claimInvitedBy(String name) {
    return '来自 $name 的邀请';
  }

  @override
  String claimHolds(String amount) {
    return '这份邀请含 $amount：足够发起你的第一批话题。';
  }

  @override
  String get claimCreateWallet => '创建我的钱包并领取';

  @override
  String get claimIntoWallet => '领取到我的钱包';

  @override
  String get claimDone => '已领取。代币将随下一个区块到达你的钱包。';

  @override
  String get claimEmpty => '这份邀请已被领取或取回。';

  @override
  String get claimWrongNetwork => '这份邀请属于另一个网络，与你连接的节点不同。';

  @override
  String get claimInvalid => '这不是有效的邀请码。';

  @override
  String get haveInvitation => '我有邀请';

  @override
  String get inviteCodeField => '邀请码或链接';

  @override
  String get claim => '领取';

  @override
  String get cancelInvitation => '取消邀请';

  @override
  String get inviteCancelled => '已取消';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '取消 $count 份邀请？',
    );
    return '$_temp0';
  }

  @override
  String cancelInviteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '其代币会退回，持有卡片的人将无法再领取。',
    );
    return '$_temp0';
  }

  @override
  String get keepInvitation => '保留';

  @override
  String get printOne => '打印';

  @override
  String inviteDoneSection(int count) {
    return '已领取或已取消（$count）';
  }

  @override
  String get inviteEachLabel => '每张卡片';

  @override
  String get inviteEachCaption => '按今天的手续费可发起五个话题，另含领取手续费。';

  @override
  String get inviteTotalLabel => '你支付';

  @override
  String get inviteTotalCaption => '总计，含手续费。';

  @override
  String get inviteWaitingState => '等待领取';

  @override
  String get inviteCardSlogan => '这里有你发声的位置。';

  @override
  String get inviteCardJoin => '扫码加入';

  @override
  String get share => '分享…';

  @override
  String get inviteDetailFunded => '已注资';

  @override
  String get inviteDetailClaimedBy => '领取人';

  @override
  String get inviteDetailReceived => '收到';

  @override
  String get inviteDetailCancelled => '已取消：代币已退回你的钱包';

  @override
  String get inviteDetailReturned => '退回';

  @override
  String get inviteDetailOnItsWay => '正在进入区块';

  @override
  String get seedConfirmTitle => '显示你的种子？';

  @override
  String get seedConfirmBody => '任何看到种子的人都能动用这个钱包。请确保没有其他人能看到你的屏幕。';

  @override
  String get showAction => '显示';

  @override
  String get authReasonSeed => '请确认是你本人以查看钱包种子';

  @override
  String get authReasonRemove => '请确认是你本人以移除此钱包';

  @override
  String get authFailed => '未确认：没有显示或更改任何内容。';

  @override
  String get passphraseNewTitle => '设置口令';

  @override
  String get passphraseNewWhat => '**此应用只用一个口令。**它在本设备上加密你的钱包密钥和邀请卡的代码。';

  @override
  String get passphraseNewWhen => '**每次**发送、显示种子或移除钱包，以及显示、打印或取消邀请卡时，都要输入它。';

  @override
  String get passphraseNewForget => '如果忘记，只有**种子备份**能恢复钱包，尚未交出的邀请卡将无法再显示或取消。';

  @override
  String get passphraseField => '口令';

  @override
  String get passphraseRepeat => '再次输入口令';

  @override
  String passphraseTooShort(int min) {
    return '至少 $min 个字符';
  }

  @override
  String get passphraseMismatch => '两次输入不一致';

  @override
  String get passphraseTitle => '口令';

  @override
  String get wrongPassphrase => '口令错误：没有显示或发送任何内容。';

  @override
  String get unlock => '解锁';

  @override
  String get authReasonSend => '请确认是你本人以签名并发送';

  @override
  String get authReasonNewWallet => '在此设备上保护你的钱包密钥';

  @override
  String get authReasonInvite => '请确认是你本人以为卡片注资';

  @override
  String get removeAnywayTitle => '不经确认就移除？';

  @override
  String get removeAnywayBody => '无法解锁钱包。移除会从此设备删除其密钥：只有种子备份能找回它。';

  @override
  String get protectionDevice => '密钥已用本设备的锁屏加密';

  @override
  String get protectionPasskey => '密钥已用本设备上的通行密钥加密';

  @override
  String get protectionPassphrase => '密钥已用你的密码短语加密';

  @override
  String get protectionLegacy => '密钥尚未加密：下次解锁时加密';

  @override
  String get confirmSendTitle => '签名前请核对';

  @override
  String get confirmSendFinal => '签名后会发送到节点，无法撤回：一旦被打包，就会永久留在链上。';

  @override
  String signAndSendShortcut(String keys) {
    return '签名并发送（$keys）';
  }

  @override
  String get threadWithdrawnMine => '你已撤回：对他人隐藏，Murmur 应用已删除其文字';

  @override
  String get threadWithdrawnMineNote =>
      '你举报了自己的话题，即将其撤回。Murmur 应用不再向他人显示它，并删除其文字，本设备也不例外；节点也可能不再保存其文字和回复。';

  @override
  String get threadWithdrawnNote =>
      '作者举报了这个话题，即将其撤回。Murmur 应用不再列出它并删除其文字，节点也可能不再保存其文字和回复。';

  @override
  String get flagOwnInfo =>
      '这是你自己的消息。举报它即撤回：Murmur 应用不再向他人显示，并删除其文字，本设备也不例外；节点也可能不再保存其文字和回复。此操作无法撤销。';

  @override
  String get inviteFromTitle => '卡片上的名字';

  @override
  String get inviteFromBody => '每张卡片都写明来自谁。卡片由邀请钱包出资，它现在可能已不是本设备上的钱包。';

  @override
  String get inviteFromOriginal => '邀请钱包的地址';

  @override
  String get inviteFromOriginalAlias => '你给邀请钱包起的名字';

  @override
  String get inviteFromOriginalPublic => '邀请钱包的公开名字';

  @override
  String get inviteFromCurrent => '本钱包的地址';

  @override
  String get inviteFromCurrentAlias => '你给本钱包起的名字';

  @override
  String get inviteFromCurrentPublic => '本钱包的公开名字';

  @override
  String get inviteFromCustom => '其他文字';

  @override
  String get inviteFromCustomHint => '留空则不打印名字';

  @override
  String get inviteFromNotSet => '本设备上未起名字';

  @override
  String get inviteFromMixed => '所选卡片之间各不相同';

  @override
  String get inviteFromChecking => '仍在链上查找';

  @override
  String get cancelReturnTo => '把代币发送到';

  @override
  String get cancelToFunder => '为它出资的钱包';

  @override
  String get cancelToCurrent => '本钱包';

  @override
  String get publicName => '公开名字';

  @override
  String get publicNameNone => '未知';

  @override
  String get publicNameSet => '设置公开名字';

  @override
  String get publicNameField => '名字';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '最多 $maxString 字节';
  }

  @override
  String get aliasBadCharacter => '不允许使用不可见字符或控制字符';

  @override
  String get aliasEdgeSpace => '开头和结尾不能有空格';

  @override
  String aliasSetTo(String name) {
    return '公开名字：$name';
  }

  @override
  String get aliasCleared => '已清除公开名字';

  @override
  String get nonTextMessage => '（不是文字：应用约定的数据）';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return '发布你的公开名字。与新话题一样，费用为 $totalString × 手续费：手续费归矿工，另有 $burnString × 手续费被销毁。';
  }

  @override
  String get inviteFromNoPublic => '没有已知的公开名字';

  @override
  String get starredTitle => '已加星标';

  @override
  String get noStarred => '还没有加星标的内容。在话题、消息或用户的页面上加星标，它就会出现在这里。';

  @override
  String get starredGone => '已不在链上';

  @override
  String get feeSuggestedLabel => '建议手续费';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '适用于 $weightString 字节';
  }

  @override
  String get feeRoom => '区块有空间';

  @override
  String get feeFull => '区块已满';

  @override
  String get feeNextBlock => '下一个区块';

  @override
  String get feePoolEntry => '进入交易池';

  @override
  String get feeMinimum => '最低';

  @override
  String get feeWhy => '为什么是这个手续费';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**手续费按字节计算**：$baseString 字节加上你的消息。区块满时，长消息更贵。';
  }

  @override
  String feeRecentPoint(String lowest, String median) {
    return '**最近的区块**接受的手续费低至 **$lowest**（中位数 $median）。';
  }

  @override
  String get feeRecentNonePoint => '**最近的区块**没有交易。';

  @override
  String get inviteNoExpiryPoint => '**不会过期**：卡片在有人领取前一直有效。';

  @override
  String get inviteCancelPoint => '**随时可取消**：代币会退回。';

  @override
  String get invitePublicPoint => '**公开可见**：链上会显示每张卡由你出资，以及由哪个钱包领取。';

  @override
  String get inviteCashPoint => '**持有代码的人**都能领取卡片。交出之前请妥善保管。';

  @override
  String get inviteLocalPoint =>
      '**只保存在本设备上。**如果清除其数据或删除应用，代码会**永久丢失**，尚未交出的卡片上的代币也会一并丢失。';

  @override
  String get publicNameIntro => '你的公开名字会显示在 Murmur 应用中**你的地址旁边**。';

  @override
  String publicNameShownAs(String name) {
    return '显示为 **$name**';
  }

  @override
  String get publicNameNotUnique => '**并不唯一**：任何人都能取同样的名字。旁边的地址用来区分不同的人。';

  @override
  String get publicNameCost => '**费用与新话题相同**，每次设置或修改都要付。';

  @override
  String get publicNameRemovable => '**是链上的一条消息**：任何节点都可能删除它，删除后就消失了。';

  @override
  String get publicNameClear => '**留空**即可清除。';

  @override
  String get passkeyNoPrfTitle => '这个通行密钥管理器无法保护钱包';

  @override
  String get passkeyNoPrfWhy =>
      '**它无法加密。**要锁住钱包密钥，管理器必须能从通行密钥派生出密钥（WebAuthn PRF）。你选的这个不支持。';

  @override
  String get passkeyNoPrfTry =>
      '**换一个管理器试试**，例如 Apple 密码或 Google 密码管理器，或用**密码短语**保护钱包。';

  @override
  String get passkeyNoPrfLeftover =>
      '它刚保存的通行密钥（**Murmur wallet**）解锁不了任何东西：你可以在那个管理器里删除它。';

  @override
  String get passkeyTryAnother => '换一个通行密钥管理器';

  @override
  String get passkeyUsePassphrase => '使用密码短语';

  @override
  String inviteDetailCancelledTo(String name) {
    return '已取消：代币已转给 $name';
  }

  @override
  String get seedNewTitle => '保存你的钱包种子';

  @override
  String get seedNewKeep => '**把它存放在安全的地方**，不要放在这台设备上：写在纸上，或存入密码管理器。';

  @override
  String get seedNewOnlyWay => '如果这台设备丢失或忘记了密码短语，它是回到这个钱包的**唯一途径**。没有人能替你找回。';

  @override
  String get seedNewSecret => '**谁拥有它，谁就控制这个钱包。**绝不要分享它，也不要在任何索要它的网站上输入。';

  @override
  String get seedNewSaved => '我已保存好种子';

  @override
  String get seedAsWords => '24 个单词';

  @override
  String get seedAsHex => '64 个字符';

  @override
  String get seedEitherForm => '两者是同一个种子：有其中一种就够了。';

  @override
  String get copyWords => '复制单词';

  @override
  String get copyCharacters => '复制字符';

  @override
  String get seedOrWords => '种子：24 个单词或 64 个字符';

  @override
  String seedUnknownWord(String word) {
    return '“$word”不是种子单词。请检查拼写。';
  }

  @override
  String get seedBadChecksum => '这 24 个单词不能组成种子：其中一个有误或位置不对。';

  @override
  String get qrCode => '二维码';

  @override
  String get addressQrHint => '扫描即可在 Murmur 中打开此地址。';

  @override
  String get starredPeople => '用户';

  @override
  String get starredThreads => '话题和消息';

  @override
  String get newActivity => '有新动态';

  @override
  String starredNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个星标项有新动态',
    );
    return '$_temp0';
  }

  @override
  String get authReasonCards => '请确认是您本人以解锁邀请卡';

  @override
  String get inviteLockedPoint => '**代码以加密方式保存。** 显示、打印或取消邀请卡时需要**解锁**。';
}
