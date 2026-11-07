// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => 'スレッド';

  @override
  String get kindReply => '返信';

  @override
  String get kindTransfer => '送金';

  @override
  String get kindFlag => '通報';

  @override
  String get contentUnavailable => '（内容を表示できません：ノードが保持していません）';

  @override
  String get contentWithdrawn => '（投稿者が取り下げました）';

  @override
  String get contentLoading => '（メッセージを読み込み中…）';

  @override
  String get pending => '未確認';

  @override
  String get copy => 'コピー';

  @override
  String get copied => 'コピーしました';

  @override
  String replyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '返信 $countString 件',
      zero: '返信なし',
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
      other: '通報 $countString 件',
      zero: '通報なし',
    );
    return '$_temp0';
  }

  @override
  String transferOf(String amount) {
    return '$amount の送金';
  }

  @override
  String flagOn(String text) {
    return '「$text」への通報';
  }

  @override
  String flagOnTx(String txid) {
    return '$txid への通報';
  }

  @override
  String get replyNotThreaded => '返信（スレッド外）';

  @override
  String routeFrom(String address) {
    return '送信元 $address';
  }

  @override
  String routeFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String errUnreachable(String detail) {
    return 'ノードに接続できません：$detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return '$url の WebSocket ブリッジに接続できません。次のコマンドで起動してください：dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return '接続エラー：$detail';
  }

  @override
  String get errClosed => 'ノードが接続を閉じました。';

  @override
  String get errTimeout => 'ノードが時間内に応答しませんでした。';

  @override
  String errProtocol(String detail) {
    return 'プロトコルエラー：$detail';
  }

  @override
  String errVersion(int node, int ours) {
    return 'ノードはプロトコル $node、このクライアントはプロトコル $ours を使用しています。';
  }

  @override
  String get errAppOutdated =>
      'ネットワークはこのアプリより新しいプロトコルに移行しました。引き続き使うにはアプリを更新してください。';

  @override
  String get errAppOutdatedWeb =>
      'ネットワークはこのページより新しいプロトコルに移行しました。ページを再読み込みして新しいバージョンを取得してください。';

  @override
  String get errAppOutdatedSystem =>
      'ネットワークはこのアプリより新しいプロトコルに移行しました。システムのソフトウェア更新からアプリを更新してください。';

  @override
  String get getNewVersion => '新しいバージョンを入手';

  @override
  String get appMaybeOld =>
      'このバージョンのアプリは**1か月以上前**のものです。より新しいバージョンが出ている可能性があります。';

  @override
  String get appMaybeOldSystem =>
      'このバージョンのアプリは**1か月以上前**のものです。システムのソフトウェア更新に新しいバージョンがある可能性があります。';

  @override
  String get localNodeOutdated =>
      'ネットワークは**新しいプロトコル**に移行しました。アプリを更新するまで、このノードはネットワークに追従できません。';

  @override
  String get localNodeOutdatedSystem =>
      'ネットワークは**新しいプロトコル**に移行しました。システムのソフトウェア更新でアプリを更新するまで、このノードはネットワークに追従できません。';

  @override
  String errSyncFailed(String cause) {
    return '同期に失敗しました：$cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return '中継されたブロックを無視しました：$detail';
  }

  @override
  String get probFeeTooLow => '手数料がネットワークの最低額を下回っています。';

  @override
  String get probMalformed => 'このトランザクションは正しい形式ではありません。';

  @override
  String get probNeedsMessage => 'メッセージを入力してください。';

  @override
  String get probNeedsRecipient => '受取人を入力してください。';

  @override
  String probAmountBelowFee(String fee) {
    return '金額は手数料（$fee）以上にしてください。';
  }

  @override
  String get probReplyParentNotMined => '返信できるのは、すでにブロックに含まれているスレッドか返信だけです。';

  @override
  String get probFlagNotMessage => '通報できるのはスレッドと返信だけです。';

  @override
  String get probAlreadyFlagged => 'このウォレットはそのメッセージをすでに通報しています。';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'メッセージは $lengthString バイトです。上限は $limitString です。';
  }

  @override
  String probInsufficientBalance(String needed, String available) {
    return '残高不足です：$needed 必要ですが、利用可能なのは $available です（確認済み残高から未確認トランザクションを引いた額）。';
  }

  @override
  String get probNotLive => 'クライアントが接続して同期するまでお待ちください。';

  @override
  String get probConnectionLost => 'ノードとの接続が切れました。';

  @override
  String get probDuplicate => '同じトランザクションがこの 1 秒以内にすでに送信されています。';

  @override
  String get tabThreads => 'スレッド';

  @override
  String get tabMessages => 'メッセージ';

  @override
  String get tabWallet => 'ウォレット';

  @override
  String get tabChain => 'チェーン';

  @override
  String get newThread => '新しいスレッド';

  @override
  String get createWalletFirst => 'まずウォレットを作成するか、インポートしてください。';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String get reconnect => '再接続';

  @override
  String get changeNode => 'ノードを変更';

  @override
  String get unknownNetwork =>
      'このノードは、クライアントが認識できないネットワーク上にあります。難易度調整は検証できず、ブロック報酬はホワイトペーパーの値で計算されるため、マイナーの残高が正確でない場合があります。';

  @override
  String get linkOffline => 'オフライン';

  @override
  String get linkConnecting => '接続中…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return '同期中 $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'ライブ · $heightString';
  }

  @override
  String get connectToNode => 'ノードに接続';

  @override
  String nodeAt(String address) {
    return 'ノード $address';
  }

  @override
  String get language => '言語';

  @override
  String get systemLanguage => 'システムの言語';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get node => 'ノード';

  @override
  String get connectHelpBridge =>
      'ブラウザでは、クライアントは WebSocket で接続します。接続先はノードの WebSocket アドレス（例：node.murmur.info、ポート 443、TLS 経由）か、ローカルのブリッジ（dart run tool/ws_bridge.dart、ポート 7880）です。';

  @override
  String get connectHelpNative =>
      'murmur-node のピアツーピアアドレス（その --port、既定は 7878）。制御ポート（7879）では接続できません。ポート 443 は、node.murmur.info のようにセキュア WebSocket の背後にあるノードに接続します。';

  @override
  String get host => 'ホスト';

  @override
  String get port => 'ポート';

  @override
  String get required => '必須';

  @override
  String get enterPort => 'ポート番号を入力してください';

  @override
  String get disconnect => '切断';

  @override
  String get cancel => 'キャンセル';

  @override
  String get connect => '接続';

  @override
  String get syncingChain => 'チェーンを同期しています…';

  @override
  String get noThreads => 'まだスレッドはありません。「新しいスレッド」から始めましょう。';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'ブロック $heightString 時点（$time、$elapsed）';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'その後の新しいブロック $countString 件',
      zero: '最新',
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
    return '$h 時間 $m 分前';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return '$dString 日 $h 時間前';
  }

  @override
  String threadStarted(String time) {
    return '$timeに開始';
  }

  @override
  String threadLastReply(String time) {
    return '最終返信 $time';
  }

  @override
  String get messagesNeedWallet =>
      'メッセージを表示するには、「ウォレット」タブでウォレットを作成またはインポートしてください。';

  @override
  String get noMessages => 'この条件に一致するメッセージはありません。';

  @override
  String get filterThreads => '自分のスレッド';

  @override
  String get filterRepliesSent => '送った返信';

  @override
  String get filterRepliesReceived => '受け取った返信';

  @override
  String get filterFlagsSent => '自分の通報';

  @override
  String get filterFlagsReceived => '受けた通報';

  @override
  String get filterMentions => 'メンション';

  @override
  String get mentionsLabel => 'メンション';

  @override
  String get mentionPublicPoint => '**メンションは公開されます：**誰を指名したかは誰でも見られます。';

  @override
  String mentionsMax(int max) {
    return '1件のメッセージにつきメンションは最大$max件です';
  }

  @override
  String get balance => '残高';

  @override
  String pendingCommitted(String amount) {
    return '$amount が未確認トランザクションに充てられています';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '採掘したブロック $countString 件',
      zero: '採掘したブロックなし',
    );
    return '$_temp0';
  }

  @override
  String get address => 'アドレス';

  @override
  String get showSeed => 'シードを表示';

  @override
  String get removeWallet => 'ウォレットを削除';

  @override
  String get history => '履歴';

  @override
  String get filters => 'フィルター';

  @override
  String get noHistory => 'この条件に一致するトランザクションはありません。';

  @override
  String get walletFilterTransfersSent => '送金（送信）';

  @override
  String get walletFilterTransfersReceived => '送金（受取）';

  @override
  String get walletFilterRepliesPaid => '返信での支払い';

  @override
  String get walletFilterRepliesEarned => '返信での収入';

  @override
  String get walletFilterThreadCosts => 'スレッドの費用';

  @override
  String get walletFilterFlagCosts => '通報の手数料';

  @override
  String get seedTitle => 'ウォレットのシード';

  @override
  String get seedWarning =>
      'このシードを持つ人は誰でもこのウォレットから支払えます。murmur-node keygen で作成した鍵ファイルと同じ形式です。';

  @override
  String get done => '完了';

  @override
  String get removeWalletTitle => 'ウォレットを削除しますか？';

  @override
  String get removeWalletBody =>
      'シードはこの端末から削除されます。コピーがなければ、このアドレスの残高はすべて失われます。';

  @override
  String get remove => '削除';

  @override
  String get importWallet => 'ウォレットをインポート';

  @override
  String get importHelp =>
      'ウォレットのシードを入力または貼り付けます。24 個の単語、または 64 文字の 16 進数です（たとえば murmur-node keygen で作った鍵ファイル murmur.key の内容。そのアドレスに採掘された報酬を使えます）。';

  @override
  String get seed => 'シード';

  @override
  String get import => 'インポート';

  @override
  String get seedInvalid => 'シードは 24 個の単語、またはちょうど 64 文字の 16 進数です。';

  @override
  String get walletIntro => 'ウォレットは、あなたが送るトランザクションに署名します。鍵はこの端末から出ません。';

  @override
  String get createWallet => '新しいウォレットを作成';

  @override
  String get importSeed => 'シードをインポート';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return '高さ $heightString にブロックはありません（最新は $tipString）。';
  }

  @override
  String get searchInvalid =>
      'ブロックの高さ、または 64 文字のトランザクション ID、ブロックハッシュ、アドレスを入力してください。';

  @override
  String get searchHint => '高さ、トランザクション ID、ブロックハッシュ、アドレスで検索';

  @override
  String get noBlocks => 'まだブロックはありません。';

  @override
  String blockTitle(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'ブロック $heightString';
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
    );
    return '$_temp0';
  }

  @override
  String minerIs(String miner) {
    return 'マイナー $miner';
  }

  @override
  String get statNetwork => 'ネットワーク';

  @override
  String get statHeight => '高さ';

  @override
  String get statNodeHeight => 'ノードの高さ';

  @override
  String get statNextReward => '次のブロック報酬';

  @override
  String rewardPlusFees(String amount) {
    return '$amount + 手数料';
  }

  @override
  String get statBurnPool => 'バーンプール';

  @override
  String get statCirculating => '流通量';

  @override
  String get tip => '最新ブロック';

  @override
  String get previousBlock => '前のブロック';

  @override
  String get nextBlock => '次のブロック';

  @override
  String get blockGone => 'このブロックはもう最良チェーン上にありません。';

  @override
  String get hash => 'ハッシュ';

  @override
  String get previous => '前';

  @override
  String get time => '時刻';

  @override
  String get confirmations => '承認数';

  @override
  String get miner => 'マイナー';

  @override
  String get reward => '報酬';

  @override
  String get merkleRoot => 'マークルルート';

  @override
  String get target => 'ターゲット';

  @override
  String get nonce => 'ナンス';

  @override
  String txCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'トランザクション $countString 件',
      zero: 'トランザクションなし',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => 'あなたのアドレス';

  @override
  String get noTransactions => 'トランザクションはありません。';

  @override
  String get sendToAddress => 'このアドレスに送金';

  @override
  String get threadGone => 'このスレッドはもうチェーン上にありません。';

  @override
  String paidToThreadAuthor(String amount) {
    return 'スレッドの作成者に $amount を支払い';
  }

  @override
  String get actionReply => '返信';

  @override
  String get actionFlag => '通報';

  @override
  String get flagged => '通報済み';

  @override
  String get details => '詳細';

  @override
  String get txTitle => 'トランザクション';

  @override
  String get txNotFound => 'トランザクションが見つかりません。未確認の一覧から外れたか、再編成で取り除かれた可能性があります。';

  @override
  String refNotLocal(String txid) {
    return 'トランザクション $txid（ローカルのチェーンにありません）';
  }

  @override
  String get flaggedMessage => '通報されたメッセージ';

  @override
  String get inReplyTo => '返信先';

  @override
  String get notThreadedExplain =>
      'このメッセージを指していますが、そのスレッドには含まれません。返信先は採掘済みのスレッドか返信である必要があり、この返信はその投稿者に支払う必要があります。支払いとしてのみ扱われます。';

  @override
  String get message => 'メッセージ';

  @override
  String get openThread => 'スレッドを開く';

  @override
  String get transactionId => 'トランザクション ID';

  @override
  String get type => '種類';

  @override
  String get from => '送信元';

  @override
  String get to => '送信先';

  @override
  String get burned => 'バーン';

  @override
  String burnedValue(String amount) {
    return '$amount（バーンプールを通じてマイナーに戻ります）';
  }

  @override
  String get amount => '金額';

  @override
  String get fee => '手数料';

  @override
  String get contentHash => '内容のハッシュ';

  @override
  String get contentSize => '内容のサイズ';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString バイト（$salt バイトのソルトと $messageString バイトのメッセージ）';
  }

  @override
  String get reports => '通報先';

  @override
  String get repliesTo => '返信先';

  @override
  String get weight => '重み';

  @override
  String weightValue(int weight, String perByte) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString バイト（1 バイトあたりの手数料 $perByte）';
  }

  @override
  String get publicKey => '公開鍵';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'ブロック $heightString で承認済み';
  }

  @override
  String confirmationCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString 承認',
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
      other: '$countString ブロック経っても未承認',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused =>
      'ノードが拒否した可能性があります（たとえば採掘前に残高が変わった場合）。拒否されたトランザクションについてノードは通知しません。';

  @override
  String get sentWaiting => '送信済み、ブロック待ち';

  @override
  String get submittedHere => 'この端末から送信しました。';

  @override
  String get pendingTitle => '未確認';

  @override
  String get relayedPending => 'ノードが中継しました。まだブロックに含まれていません。';

  @override
  String get viewBlock => 'ブロックを表示';

  @override
  String get newTransaction => '新しいトランザクション';

  @override
  String get flagMessage => 'メッセージを通報';

  @override
  String flaggingInfo(String author) {
    return '$author のこのメッセージを通報します。1 つのウォレットが同じメッセージを通報できるのは 1 回だけです。通報をどう扱うかは各クライアントが決めます。';
  }

  @override
  String replyingTo(String author) {
    return '$author への返信';
  }

  @override
  String explainThread(int total, int burn) {
    return '新しいスレッドを始めます。費用は手数料の $total 倍です。手数料はマイナーに渡り、手数料の $burn 倍がバーンされます。バーンされたトークンは、その後のブロックでマイナーに戻ります。';
  }

  @override
  String get explainReply =>
      '返信では、スレッドの作成者に少なくとも手数料と同額を支払い（チップとして多めに払うこともできます）、さらにマイナーに手数料を支払います。';

  @override
  String get explainTransfer => 'メッセージのない通常のトークン送金です。金額は手数料以上にしてください。';

  @override
  String get recipientAddress => '受取人のアドレス';

  @override
  String get enterAddress => '64 文字の 16 進アドレスを入力してください';

  @override
  String get payToAuthor => 'スレッド作成者への支払い';

  @override
  String get notAnAmount => '数量を入力してください';

  @override
  String atLeastFee(String fee) {
    return '手数料（$fee）以上';
  }

  @override
  String get feeToMiner => '手数料（マイナーへ）';

  @override
  String suggestedFee(String fee) {
    return '推奨：$fee';
  }

  @override
  String feeBelowSuggested(String fee) {
    return '推奨手数料（$fee）より低い：ブロックに入るまで時間がかかることがあります。';
  }

  @override
  String feeAboveSuggested(String fee) {
    return '推奨手数料（$fee）より高い：マイナーに必要以上を支払います。';
  }

  @override
  String atLeastMin(String min) {
    return '$min 以上';
  }

  @override
  String bytesOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString バイト';
  }

  @override
  String tooLong(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '長すぎます：$countString バイト';
  }

  @override
  String get murmurEmoji => 'Murmur の絵文字';

  @override
  String murmurEmojiHint(String example) {
    return 'Murmur でのみ絵として表示されます。ほかのアプリでは $example のように名前が表示されます。';
  }

  @override
  String get sendingNeedsLive => 'クライアントが接続して同期すると送信できます。';

  @override
  String get signAndSend => '署名して送信';

  @override
  String get costFee => '手数料（マイナーへ）';

  @override
  String costBurn(int multiple) {
    return 'バーン：手数料の $multiple 倍';
  }

  @override
  String get costPaid => '受取人への支払い';

  @override
  String get costTotal => '合計費用';

  @override
  String get costAvailable => '利用可能：残高から未確認トランザクションを引いた額';

  @override
  String get costRemaining => '送信後の残り';

  @override
  String get checkingFees => 'ネットワークの手数料を確認しています…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'このクライアントが見たものから推定しています（接続後の未確認 $countString 件）。ノード自身の手数料レポートは利用できませんでした。';
  }

  @override
  String get use => '使う';

  @override
  String balanceBeforeAfter(String before, String after) {
    return '$before → $after';
  }

  @override
  String balanceBeforeAfterTooltip(String before, String after) {
    return '残高：前 $before、後 $after';
  }

  @override
  String get loadingOlder => '古いブロックを読み込み中…';

  @override
  String get blockLoading => 'このブロックを読み込み中…';

  @override
  String get txSearching => 'まだ読み込み中のブロックからこのトランザクションを探しています…';

  @override
  String get storageBanner =>
      'このデバイスにチェーンのコピーを保存しますか？ 次回からはすべてを再ダウンロードせず、数秒で開けます。コピーはここにだけ保存され、誰にも送信されません。Cookie もトラッキングもありません。ウォレットの鍵と設定は、アプリの動作に必要なため常にこのデバイスに保存されます。';

  @override
  String get storageAllow => '必要な保存を許可';

  @override
  String get storageReject => '拒否（遅くなります）';

  @override
  String get storageOn => 'チェーンのローカルコピー：オン';

  @override
  String get storageOff => 'チェーンのローカルコピー：オフ（毎回再ダウンロードします）';

  @override
  String get storageTurnOn => 'オンにする';

  @override
  String get storageTurnOff => 'オフにして削除';

  @override
  String get checkingBalance => 'ノードに確認中…';

  @override
  String get errTampered => '接続が改ざんまたは切断されました。メッセージが整合性チェックに失敗しました。';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'ブロック $heightString でノードがコミットした状態が、このクライアントによるチェーンの集計と一致しません。このノードは信頼せず、別のノードに接続してください。';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ノードより：未確認のトランザクション $countString 件。',
      zero: 'ノードより：未確認のトランザクションはありません。',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => 'ノードが受け付けて中継しました。';

  @override
  String get statusRefused => 'ノードに拒否されました';

  @override
  String get statusInvalid => '無効として拒否されました';

  @override
  String nodeReason(String reason) {
    return 'ノードの説明：$reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'チェーンがこのリリースのブロック $heightString のチェックポイントにつながりません。リリースか、接続したすべてのノードが誤っています。停止しました。その内容は信頼できません。';
  }

  @override
  String staleTip(String elapsed) {
    return '最新のブロックは $elapsed のものです。このノードは遅れているか、ネットワークから切り離されている可能性があります。表示内容は古いかもしれません。';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return 'ブロック $heightString のチェックポイントから開始しました。ジェネシスまでのヘッダーを確認中です（これまでに $doneString 件）。';
  }

  @override
  String get licenses => 'ライセンス';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => 'テストネット：トークンに価値はありません';

  @override
  String get linkNodeRepo => 'ノードとプロトコルのソースコード';

  @override
  String get linkWhitepaper => 'ホワイトペーパー';

  @override
  String checkingHeaders(int done, int total) {
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'ブロックヘッダーを検証中：$doneString / $totalString';
  }

  @override
  String reconnectingIn(int seconds) {
    return '$seconds 秒後に再試行します。';
  }

  @override
  String get languagesFilter => '言語';

  @override
  String get languageUndetected => '判定不能';

  @override
  String get hideFlaggedThreads => '自分が通報したスレッドを隠す';

  @override
  String get star => 'スターを付ける';

  @override
  String get unstar => 'スターを外す';

  @override
  String get starredOnly => 'スター付きのスレッドのみ';

  @override
  String get localNodeRun => 'このコンピューターで Murmur ノードを動かす';

  @override
  String get localNodeExplain =>
      'このコンピューターがチェーン全体を自分で検証し、中継を手伝い、あなた自身のメッセージを読める状態に保ちます。保持するのはチェーンの直近 1 日分だけで、1 時間の検証を過ぎた他の人のメッセージは保持しません。';

  @override
  String get localNodeStarting => 'ノードを起動しています…';

  @override
  String localNodeRunning(String address) {
    return 'ノードは $address で動作中です。アプリは引き続き、選択したノードから読み込みます。';
  }

  @override
  String localNodeFailed(String reason) {
    return 'ノードが停止しました：$reason';
  }

  @override
  String get localNodeFailedUnknown => 'ノードが予期せず停止しました。';

  @override
  String get localNodeFromCheckpoint => '最新のブロックから開始しています。古いブロックはその後に検証します。';

  @override
  String localNodeCatchingUp(String height, String total) {
    return 'チェーンに追いついています：ブロック $height / $total';
  }

  @override
  String localNodeCheckingHistory(String height, String total) {
    return '古いブロックをバックグラウンドで検証中：$height / $total';
  }

  @override
  String get localNodeMine => 'このコンピューターでマイニングする';

  @override
  String get localNodeMineNote =>
      'マイニングの報酬はウォレットのアドレスに支払われます。電気を使い、コンピューターの負荷が増えます。テストネットのトークンはテスト用です。';

  @override
  String get localNodeMineNeedsWallet =>
      'まずウォレットを作成してください。マイニングの報酬はそのアドレスに支払われます。';

  @override
  String localNodeMinesTo(String name) {
    return 'マイニングの支払い先：**$name**';
  }

  @override
  String localNodeCpu(int pct) {
    return 'プロセッサーコア 1 つの最大 $pct%';
  }

  @override
  String get localNodeGpu => 'グラフィックカードでマイニングする';

  @override
  String get localNodeGpuNote =>
      'プロセッサよりはるかに高速ですが、電力も多く使います。カードが使えないときは、プロセッサでマイニングを続けます。';

  @override
  String get localNodeGpuStarting => 'グラフィックカードを起動しています。その間はプロセッサでマイニングします。';

  @override
  String localNodeGpuMining(String device) {
    return '**$device** でマイニング中';
  }

  @override
  String get localNodeGpuMiningAny => '**グラフィックカード**でマイニング中';

  @override
  String get localNodeGpuUnavailable => 'グラフィックカードを使えません。**プロセッサでマイニングを続けます**。';

  @override
  String localNodeGpuDetail(String reason) {
    return 'ノードからの報告：$reason';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のスレッドを非表示',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => '読み込み済みのスレッドを検索';

  @override
  String get noMatches => '一致する読み込み済みのスレッドはありません。';

  @override
  String get timeJustNow => 'たった今';

  @override
  String timeMinutesAgo(int n) {
    return '$n 分前';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n 時間前';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n 日前';
  }

  @override
  String get nameAddress => '名前';

  @override
  String get aliasTitle => 'このアドレスに名前を付ける';

  @override
  String get aliasHelp => '名前はこの端末にだけ保存されます。空にすると削除されます。';

  @override
  String get save => '保存';

  @override
  String get mute => 'ミュート';

  @override
  String get unmute => 'ミュート解除';

  @override
  String get mutedNote => 'ミュート中：このアドレスのスレッドと返信はこの端末で非表示になります。';

  @override
  String get earlierReplies => '以前の返信';

  @override
  String get quoteNotLoaded => '以前の返信（タップして読み込む）';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ミュート中のアドレスからの返信 $count 件を非表示',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新しい返信 $count 件',
    );
    return '$_temp0';
  }

  @override
  String get invitations => '招待';

  @override
  String get createInvitations => '招待を作成';

  @override
  String get inviteHowMany => 'カードの枚数';

  @override
  String get inviteFund => 'カードに入金';

  @override
  String get inviteCardTitle => 'Murmur への招待';

  @override
  String inviteCardSerial(int n, int total) {
    return '$total 枚中 $n 枚目';
  }

  @override
  String inviteCardFrom(String name) {
    return '$name より';
  }

  @override
  String get inviteCardHow => 'コードを読み取るかリンクを開いて Murmur に参加しましょう。';

  @override
  String get inviteClaimed => '受け取り済み';

  @override
  String get inviteChecking => '確認中…';

  @override
  String get claimTitle => '招待されています';

  @override
  String claimInvitedBy(String name) {
    return '$name からの招待';
  }

  @override
  String claimHolds(String amount) {
    return 'この招待には $amount が入っています。最初のスレッドを始めるのに十分です。';
  }

  @override
  String get claimCreateWallet => 'ウォレットを作って受け取る';

  @override
  String get claimIntoWallet => '自分のウォレットに受け取る';

  @override
  String get claimDone => '受け取りました。トークンは次のブロックでウォレットに届きます。';

  @override
  String get claimEmpty => 'この招待はすでに受け取られたか、取り戻されています。';

  @override
  String get claimWrongNetwork => 'この招待は、接続中のノードとは別のネットワーク用です。';

  @override
  String get claimInvalid => '有効な招待コードではありません。';

  @override
  String get haveInvitation => '招待を持っています';

  @override
  String get inviteCodeField => '招待コードまたはリンク';

  @override
  String get claim => '受け取る';

  @override
  String get cancelInvitation => '招待をキャンセル';

  @override
  String get inviteCancelled => 'キャンセル済み';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の招待をキャンセルしますか？',
    );
    return '$_temp0';
  }

  @override
  String cancelInviteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'トークンは戻り、カードを持っている人は受け取れなくなります。',
    );
    return '$_temp0';
  }

  @override
  String get keepInvitation => '残す';

  @override
  String get printOne => '印刷';

  @override
  String inviteDoneSection(int count) {
    return '受け取り済み・キャンセル済み（$count）';
  }

  @override
  String get inviteEachLabel => '各カード';

  @override
  String get inviteEachCaption => '今日の手数料でスレッド 5 件分と、受け取りの手数料。';

  @override
  String get inviteTotalLabel => '支払い';

  @override
  String get inviteTotalCaption => '合計（手数料込み）。';

  @override
  String get inviteWaitingState => '受け取り待ち';

  @override
  String get inviteCardSlogan => 'ここには、あなたの声の居場所があります。';

  @override
  String get inviteCardJoin => '読み取って参加';

  @override
  String get share => '共有…';

  @override
  String get inviteDetailFunded => '入金';

  @override
  String get inviteDetailClaimedBy => '受け取った人';

  @override
  String get inviteDetailReceived => '受け取り額';

  @override
  String get inviteDetailCancelled => 'キャンセル済み：トークンはあなたのウォレットに戻りました';

  @override
  String get inviteDetailReturned => '戻った額';

  @override
  String get inviteDetailOnItsWay => 'ブロックに取り込まれるのを待っています';

  @override
  String get seedConfirmTitle => 'シードを表示しますか？';

  @override
  String get seedConfirmBody =>
      'シードを見た人は誰でもこのウォレットから支払えます。画面を他の人に見られていないか確認してください。';

  @override
  String get showAction => '表示';

  @override
  String get authReasonSeed => 'ウォレットのシードを見るには本人確認をしてください';

  @override
  String get authReasonRemove => 'このウォレットを削除するには本人確認をしてください';

  @override
  String get authFailed => '確認できませんでした。何も表示・変更していません。';

  @override
  String get passphraseNewTitle => 'パスフレーズを設定';

  @override
  String get passphraseNewWhat =>
      '**このアプリのパスフレーズは 1 つです。**このデバイス上で、ウォレットの鍵と招待カードのコードを暗号化します。';

  @override
  String get passphraseNewWhen =>
      '送信、シードの表示、ウォレットの削除、カードの表示・印刷・取り消しの**たびに**入力します。';

  @override
  String get passphraseNewForget =>
      '忘れた場合、ウォレットを戻せるのは**シードのバックアップ**だけで、まだ渡していないカードは表示も取り消しもできなくなります。';

  @override
  String get passphraseField => 'パスフレーズ';

  @override
  String get passphraseRepeat => 'パスフレーズを再入力';

  @override
  String passphraseTooShort(int min) {
    return '$min 文字以上';
  }

  @override
  String get passphraseMismatch => '一致しません';

  @override
  String get passphraseTitle => 'パスフレーズ';

  @override
  String get wrongPassphrase => 'パスフレーズが違います。何も表示・送信していません。';

  @override
  String get unlock => 'ロック解除';

  @override
  String get authReasonSend => '署名して送信するには本人確認をしてください';

  @override
  String get authReasonNewWallet => 'この端末でウォレットの鍵を保護します';

  @override
  String get authReasonInvite => 'カードに入金するには本人確認をしてください';

  @override
  String get removeAnywayTitle => '確認せずに削除しますか？';

  @override
  String get removeAnywayBody =>
      'ウォレットのロックを解除できませんでした。削除するとこの端末から鍵が消えます。戻せるのはシードのバックアップだけです。';

  @override
  String get forgetCardsKeyTitle => '招待カードのロックを解除できません';

  @override
  String get forgetCardsKeyBody =>
      '新しいウォレットは、招待カードと同じパスフレーズまたはパスキーを使います。それがもう手元にない場合は、カードの鍵を手放してください。ウォレットには新しいパスフレーズが設定され、まだ受け取られていないカードはこの端末で表示・印刷・取り消しができなくなります。トークンはカードに残ります。';

  @override
  String get forgetCardsKeyAction => 'カードの鍵を手放す';

  @override
  String get inviteCodeLost => 'コードはこの端末にありません';

  @override
  String get protectionDevice => '鍵はこの端末のロックで暗号化されています';

  @override
  String get protectionPasskey => '鍵はこの端末のパスキーで暗号化されています';

  @override
  String get protectionPassphrase => '鍵はパスフレーズで暗号化されています';

  @override
  String get protectionLegacy => '鍵はまだ暗号化されていません（次回のロック解除時に暗号化）';

  @override
  String get confirmSendTitle => '署名の前に確認';

  @override
  String get confirmSendFinal => '署名するとノードに送信されます。取り消せません。マイニングされるとチェーンに残ります。';

  @override
  String signAndSendShortcut(String keys) {
    return '署名して送信（$keys）';
  }

  @override
  String get threadWithdrawnMine => '取り下げ済み：他の人には非表示、Murmur アプリから本文を削除';

  @override
  String get threadWithdrawnMineNote =>
      '自分のスレッドを通報したため、取り下げになりました。Murmur アプリは他の人に表示しなくなり、この端末も含めて本文を削除します。ノードは本文と返信を保存しなくなる場合があります。';

  @override
  String get threadWithdrawnNote =>
      '投稿者がこのスレッドを通報したため、取り下げになりました。Murmur アプリは一覧に表示せず本文を削除し、ノードは本文と返信を保存しなくなる場合があります。';

  @override
  String get flagOwnInfo =>
      'これは自分のメッセージです。通報すると取り下げになります。Murmur アプリは他の人に表示しなくなり、この端末も含めて本文を削除します。ノードは本文と返信を保存しなくなる場合があります。元に戻せません。';

  @override
  String get inviteFromTitle => 'カードに載せる名前';

  @override
  String get inviteFromBody =>
      '各カードには差出人が載ります。カードに入金したのは招待したウォレットで、今この端末にあるウォレットとは違う場合があります。';

  @override
  String get inviteFromOriginal => '招待したウォレットのアドレス';

  @override
  String get inviteFromOriginalAlias => '招待したウォレットに付けた名前';

  @override
  String get inviteFromOriginalPublic => '招待したウォレットの公開名';

  @override
  String get inviteFromCurrent => 'このウォレットのアドレス';

  @override
  String get inviteFromCurrentAlias => 'このウォレットに付けた名前';

  @override
  String get inviteFromCurrentPublic => 'このウォレットの公開名';

  @override
  String get inviteFromCustom => 'ほかのテキスト';

  @override
  String get inviteFromCustomHint => '空欄にすると名前を印刷しません';

  @override
  String get inviteFromNotSet => 'この端末では名前が付いていません';

  @override
  String get inviteFromMixed => '選んだカードごとに異なります';

  @override
  String get inviteFromChecking => 'チェーンでまだ検索中です';

  @override
  String get cancelReturnTo => 'トークンの送り先';

  @override
  String get cancelToFunder => '入金したウォレット';

  @override
  String get cancelToCurrent => 'このウォレット';

  @override
  String get publicName => '公開名';

  @override
  String get publicNameNone => '不明';

  @override
  String get publicNameSet => '公開名を設定';

  @override
  String get publicNameField => '名前';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '最大 $maxString バイト';
  }

  @override
  String get aliasBadCharacter => '不可視文字や制御文字は使えません';

  @override
  String get aliasEdgeSpace => '先頭と末尾にスペースは使えません';

  @override
  String aliasSetTo(String name) {
    return '公開名：$name';
  }

  @override
  String get aliasCleared => '公開名を消去しました';

  @override
  String profileSetTo(String name) {
    return '公開名と画像：$name';
  }

  @override
  String get profilePictureOnly => '公開画像（名前なし）';

  @override
  String get nonTextMessage => '（テキストではありません：アプリ規約のデータ）';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return '公開名を公開します。新しいスレッドと同じく、費用は手数料の $totalString 倍です。手数料はマイナーに渡り、手数料の $burnString 倍が焼却されます。';
  }

  @override
  String get inviteFromNoPublic => '既知の公開名はありません';

  @override
  String get starredTitle => 'スター付き';

  @override
  String get noStarred =>
      'まだスター付きのものはありません。スレッド、メッセージ、ユーザーのページでスターを付けると、ここに表示されます。';

  @override
  String get starredGone => 'チェーン上にありません';

  @override
  String get feeSuggestedLabel => '推奨手数料';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString バイト分';
  }

  @override
  String get feeRoom => 'ブロックに空きあり';

  @override
  String get feeFull => 'ブロックが満杯';

  @override
  String get feeNextBlock => '次のブロック';

  @override
  String get feePoolEntry => 'プール入りに必要';

  @override
  String get feeMinimum => '最低';

  @override
  String get feeWhy => 'この手数料の理由';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**手数料はバイト単位**：$baseString バイトにメッセージ分が加わります。ブロックが満杯のときは長いメッセージほど高くなります。';
  }

  @override
  String feeRecentPoint(String lowest, String median) {
    return '**最近のブロック**は最低 **$lowest** の手数料を受け入れました（中央値 $median）。';
  }

  @override
  String get feeRecentNonePoint => '**最近のブロック**には取引がありませんでした。';

  @override
  String get inviteNoExpiryPoint => '**期限なし**：カードは誰かが受け取るまで有効です。';

  @override
  String get inviteCancelPoint => '**いつでも取り消し可能**：トークンは戻ります。';

  @override
  String get invitePublicPoint =>
      '**公開されます**：各カードにあなたが入金したことと、どのウォレットが受け取ったかがチェーンに残ります。';

  @override
  String get inviteCashPoint => '**コードを持つ人**なら誰でもカードを受け取れます。渡すまでは人に見せないでください。';

  @override
  String get inviteLocalPoint =>
      '**この端末にだけ保存されます。**データを消去したりアプリを削除したりすると、コードは**永久に失われ**、まだ渡していないカードのトークンも失われます。';

  @override
  String get publicNameIntro => '公開名は Murmur アプリで**アドレスの横**に表示されます。';

  @override
  String publicNameShownAs(String name) {
    return '表示：**$name**';
  }

  @override
  String get publicNameNotUnique =>
      '**一意ではありません**：誰でも同じ名前を選べます。横に表示されるアドレスで見分けます。';

  @override
  String get publicNameCost => '**新しいスレッドと同じ費用**が、設定や変更のたびにかかります。';

  @override
  String get publicNameRemovable => '**チェーン上のメッセージです**：どのノードも削除でき、削除されると消えます。';

  @override
  String get publicNameClear => '**空欄にすると**消去します。';

  @override
  String get publicNamePicture => '画像';

  @override
  String get pictureFromPhotos => '写真から';

  @override
  String get pictureFromFiles => 'ファイルから';

  @override
  String get pictureChoose => '画像を選ぶ';

  @override
  String get pictureRemove => '画像を外す';

  @override
  String pictureTooLarge(String size) {
    return 'ファイルが大きすぎます。$size MB 未満のものを選んでください。';
  }

  @override
  String get pictureUnreadable => 'このファイルは画像として読めません。';

  @override
  String get picturePoint => '**32 × 32 ピクセル・16 色**で、アドレスのマークの代わりに表示されます。';

  @override
  String get pictureCost => '画像付きは**約 3 倍の費用**です。';

  @override
  String get passkeyNoPrfTitle => 'このパスキー管理アプリではウォレットを保護できません';

  @override
  String get passkeyNoPrfWhy =>
      '**暗号化できません。**ウォレットの鍵をロックするには、管理アプリがパスキーから鍵を導出できる必要があります（WebAuthn PRF）。選んだアプリは対応していません。';

  @override
  String get passkeyNoPrfTry =>
      '**別の管理アプリを試す**（Apple のパスワードや Google パスワード マネージャーなど）か、**パスフレーズ**でウォレットを保護してください。';

  @override
  String get passkeyNoPrfLeftover =>
      'いま保存されたパスキー（**Murmur wallet**）は何も解除できません。その管理アプリから削除して構いません。';

  @override
  String get passkeyTryAnother => '別のパスキー管理アプリを試す';

  @override
  String get passkeyUsePassphrase => 'パスフレーズを使う';

  @override
  String inviteDetailCancelledTo(String name) {
    return '取り消し済み：トークンは $name に送られました';
  }

  @override
  String get seedNewTitle => 'ウォレットのシードを保存してください';

  @override
  String get seedNewKeep =>
      '**安全な場所に保管してください。**この端末とは別に、紙に書くか、パスワードマネージャーに保存します。';

  @override
  String get seedNewOnlyWay =>
      'この端末をなくしたり、パスフレーズを忘れたりしたとき、このウォレットに戻る**唯一の方法**です。誰も代わりに復元できません。';

  @override
  String get seedNewSecret =>
      '**これを持つ人がウォレットを操作できます。**決して共有せず、入力を求めるサイトにも入力しないでください。';

  @override
  String get seedNewSaved => 'シードを保存しました';

  @override
  String get seedAsWords => '24 個の単語';

  @override
  String get seedAsHex => '64 文字';

  @override
  String get seedEitherForm => 'どちらも同じシードです。片方があれば十分です。';

  @override
  String get copyWords => '単語をコピー';

  @override
  String get copyCharacters => '文字をコピー';

  @override
  String get seedOrWords => 'シード：24 個の単語または 64 文字';

  @override
  String seedUnknownWord(String word) {
    return '「$word」はシードの単語ではありません。つづりを確認してください。';
  }

  @override
  String get seedBadChecksum => 'この 24 個の単語はシードになりません。どれかが間違っているか、順番が違います。';

  @override
  String get qrCode => 'QR コード';

  @override
  String get addressQrHint => 'スキャンすると、このアドレスを Murmur で開けます。';

  @override
  String get starredPeople => 'ユーザー';

  @override
  String get starredThreads => 'メッセージ';

  @override
  String get noStarredThreads =>
      'スター付きのスレッドやメッセージはありません。ページでスターを付けると、ここに表示されます。';

  @override
  String get noStarredPeople => 'スター付きのユーザーはいません。ユーザーのページでスターを付けると、ここに表示されます。';

  @override
  String get newActivity => '新しいアクティビティ';

  @override
  String starredNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'スター付き $count 件に新しいアクティビティ',
    );
    return '$_temp0';
  }

  @override
  String get authReasonCards => '招待カードのロックを解除するには本人確認をしてください';

  @override
  String get inviteLockedPoint =>
      '**コードは暗号化して保存されます。** カードの表示、印刷、取り消しには**ロック解除**が必要です。';

  @override
  String get notifications => '通知';

  @override
  String get notifyReplies => 'あなたへの返信と回答';

  @override
  String get notifyMentions => 'あなたへのメンション';

  @override
  String get notifyStarred => 'スター付きの新着';

  @override
  String get notifyNeedsWallet => 'この端末にウォレットが必要です';

  @override
  String get notifyDenied => 'システム設定で Murmur の通知がオフになっています。';

  @override
  String get notifyPointLocal =>
      '**このアプリ自身が確認します**。選んだノードに対してのみで、Google や Apple などを経由しません。';

  @override
  String get notifyPointBackground =>
      'アプリを閉じている間も、システムが許す範囲で**約 15 分ごと**に確認します。';

  @override
  String get notifyPointOpen => '**アプリを開いている間だけ**、前面にないときに通知します。';

  @override
  String get notifyPointLockScreen => 'ロック画面では**内容を表示しません**。';

  @override
  String get notifyChannel => 'メッセージ';

  @override
  String get notifyOpen => '開く';

  @override
  String notifyReply(String name) {
    return '$name さんがあなたのスレッドに返信しました';
  }

  @override
  String notifyAnswer(String name) {
    return '$name さんがあなたに回答しました';
  }

  @override
  String notifyMention(String name) {
    return '$name さんがあなたをメンションしました';
  }

  @override
  String notifyStarredReply(String name) {
    return '$name さんがスター付きのスレッドに返信しました';
  }

  @override
  String notifyStarredPerson(String name) {
    return '$name さんから新しいメッセージ';
  }

  @override
  String notifyMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ほかに新しいメッセージが $countString 件',
    );
    return '$_temp0';
  }

  @override
  String get faceIdReason => 'ウォレットの鍵を使う前や表示する前に、本人であることを確認してください。';

  @override
  String get refresh => '更新';

  @override
  String get markAllRead => 'すべて既読にする';

  @override
  String get newAboveLastVisit => 'ここより上：前回の訪問以降の新着';

  @override
  String get publicNameAndPicture => '公開名と画像';

  @override
  String get publicNameAndPictureSet => '公開名と画像を設定';

  @override
  String get publicNameStandOut => '**自分らしく**：アドレスの横に表示される名前と画像です。';

  @override
  String get pictureLarger => '画像を大きく表示';

  @override
  String get keepMessagesAvailable => '自分のメッセージを読めるようにしておく';

  @override
  String get keepMessagesAvailableExplain =>
      '**アプリを開いている間**、ノードが保存しなくなったあなたのメッセージを、読み手はあなたから受け取れます。**あなたのものだけ**で、他人のものは扱いません。';

  @override
  String errBadSignature(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'ブロック $heightString に署名が無効なトランザクションがあります。このノードのチェーンは全ノードが守るルールに反しています。このノードは信頼せず、別のノードに接続してください。';
  }

  @override
  String receivedOmitted(String count) {
    return '**ノードが省いていました**：他の人があなたに対して行ったことの一部（$count）。ブロックそのものから見つけたので、表示しています。';
  }

  @override
  String get keyringUnavailable =>
      'システムのキーリングがロックされていて、パスワードを尋ねることができないため、この端末にウォレットを保存できません。キーリングのロックを解除して（通常はデスクトップへのログインで解除されます）、Murmur を起動し直してください。';
}
