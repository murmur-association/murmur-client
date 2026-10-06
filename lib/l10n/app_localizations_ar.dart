// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Murmur';

  @override
  String get kindThread => 'موضوع';

  @override
  String get kindReply => 'رد';

  @override
  String get kindTransfer => 'تحويل';

  @override
  String get kindFlag => 'بلاغ';

  @override
  String get contentUnavailable => '(المحتوى غير متاح: العقدة لا تملكه)';

  @override
  String get contentWithdrawn => '(سحبه كاتبه)';

  @override
  String get contentLoading => '(جارٍ تحميل الرسالة…)';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'تم النسخ';

  @override
  String replyCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString رد',
      many: '$countString ردًّا',
      few: '$countString ردود',
      two: 'ردّان',
      one: 'رد واحد',
      zero: 'لا ردود',
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
      other: '$countString بلاغ',
      many: '$countString بلاغًا',
      few: '$countString بلاغات',
      two: 'بلاغان',
      one: 'بلاغ واحد',
      zero: 'لا بلاغات',
    );
    return '$_temp0';
  }

  @override
  String transferOf(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'تحويل بقيمة $amountString';
  }

  @override
  String flagOn(String text) {
    return 'بلاغ عن «$text»';
  }

  @override
  String flagOnTx(String txid) {
    return 'بلاغ عن $txid';
  }

  @override
  String get replyNotThreaded => 'رد (خارج أي موضوع)';

  @override
  String routeFrom(String address) {
    return 'من $address';
  }

  @override
  String routeFromTo(String from, String to) {
    return '$from ← $to';
  }

  @override
  String errUnreachable(String detail) {
    return 'تعذّر الوصول إلى العقدة: $detail';
  }

  @override
  String errBridgeUnreachable(String url) {
    return 'تعذّر الوصول إلى جسر WebSocket على $url. شغّله بالأمر: dart run tool/ws_bridge.dart';
  }

  @override
  String errConnection(String detail) {
    return 'خطأ في الاتصال: $detail';
  }

  @override
  String get errClosed => 'أغلقت العقدة الاتصال.';

  @override
  String get errTimeout => 'لم تستجب العقدة في الوقت المحدد.';

  @override
  String errProtocol(String detail) {
    return 'خطأ في البروتوكول: $detail';
  }

  @override
  String errVersion(int node, int ours) {
    return 'تستخدم العقدة البروتوكول $node، ويستخدم هذا العميل البروتوكول $ours.';
  }

  @override
  String errSyncFailed(String cause) {
    return 'فشلت المزامنة: $cause';
  }

  @override
  String errIgnoredBlock(String detail) {
    return 'تم تجاهل كتلة مُعاد بثّها: $detail';
  }

  @override
  String get probFeeTooLow => 'يجب ألا تقل الرسوم عن 1.';

  @override
  String get probMalformed => 'هذه المعاملة غير سليمة البنية.';

  @override
  String get probNeedsMessage => 'اكتب رسالة.';

  @override
  String get probNeedsRecipient => 'أدخل مستلمًا.';

  @override
  String probAmountBelowFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'يجب ألا يقل المبلغ عن الرسوم ($feeString).';
  }

  @override
  String get probReplyParentNotMined =>
      'لا يمكنك الرد إلا على موضوع أو رد موجود بالفعل في كتلة.';

  @override
  String get probReplyWrongRecipient =>
      'يجب أن يدفع الرد لكاتب الرسالة التي يرد عليها.';

  @override
  String get probFlagNotMessage => 'لا يمكن الإبلاغ إلا عن المواضيع والردود.';

  @override
  String get probAlreadyFlagged => 'سبق لهذه المحفظة الإبلاغ عن تلك الرسالة.';

  @override
  String probMessageTooLong(int length, int limit) {
    final intl.NumberFormat lengthNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lengthString = lengthNumberFormat.format(length);
    final intl.NumberFormat limitNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String limitString = limitNumberFormat.format(limit);

    return 'حجم الرسالة $lengthString بايت، والحد الأقصى $limitString.';
  }

  @override
  String probInsufficientBalance(int needed, int available) {
    final intl.NumberFormat neededNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String neededString = neededNumberFormat.format(needed);
    final intl.NumberFormat availableNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String availableString = availableNumberFormat.format(available);

    return 'الرصيد غير كافٍ: المطلوب $neededString والمتاح $availableString (الرصيد المؤكد مطروحًا منه المعاملات المعلّقة).';
  }

  @override
  String get probNotLive => 'انتظر حتى يتصل العميل ويكتمل التزامن.';

  @override
  String get probConnectionLost => 'انقطع الاتصال بالعقدة.';

  @override
  String get probDuplicate => 'أُرسلت معاملة مطابقة في هذه الثانية نفسها.';

  @override
  String get tabThreads => 'المواضيع';

  @override
  String get tabMessages => 'الرسائل';

  @override
  String get tabWallet => 'المحفظة';

  @override
  String get tabChain => 'السلسلة';

  @override
  String get newThread => 'موضوع جديد';

  @override
  String get createWalletFirst => 'أنشئ محفظة أو استوردها أولًا.';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get reconnect => 'إعادة الاتصال';

  @override
  String get changeNode => 'تغيير العقدة';

  @override
  String get unknownNetwork =>
      'هذه العقدة على شبكة لا يعرفها العميل. لا يمكن التحقق من تعديلات الصعوبة فيها، وتُحسب مكافآت الكتل بقيم الورقة البيضاء، لذا قد لا تكون أرصدة المُعدِّنين دقيقة.';

  @override
  String get linkOffline => 'غير متصل';

  @override
  String get linkConnecting => 'جارٍ الاتصال…';

  @override
  String linkSyncing(int height, int peerHeight) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat peerHeightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String peerHeightString = peerHeightNumberFormat.format(peerHeight);

    return 'جارٍ التزامن $heightString/$peerHeightString';
  }

  @override
  String linkLive(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'مباشر · $heightString';
  }

  @override
  String get connectToNode => 'الاتصال بعقدة';

  @override
  String nodeAt(String address) {
    return 'العقدة $address';
  }

  @override
  String get language => 'اللغة';

  @override
  String get systemLanguage => 'لغة النظام';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get node => 'العقدة';

  @override
  String get connectHelpBridge =>
      'في المتصفح، يتصل العميل عبر WebSocket: بعنوان WebSocket لعقدة (مثل node.murmur.info، المنفذ 443، عبر TLS)، أو بجسر محلي (dart run tool/ws_bridge.dart، المنفذ 7880).';

  @override
  String get connectHelpNative =>
      'عنوان النظير إلى النظير لعقدة murmur-node (منفذها ‎--port، وهو 7878 افتراضيًا). منفذ التحكم (7879) لن يعمل.';

  @override
  String get host => 'المضيف';

  @override
  String get port => 'المنفذ';

  @override
  String get required => 'مطلوب';

  @override
  String get enterPort => 'أدخل رقم منفذ';

  @override
  String get disconnect => 'قطع الاتصال';

  @override
  String get cancel => 'إلغاء';

  @override
  String get connect => 'اتصال';

  @override
  String get syncingChain => 'جارٍ مزامنة السلسلة…';

  @override
  String get noThreads => 'لا مواضيع بعد. ابدأ واحدًا بزر «موضوع جديد».';

  @override
  String threadsAsOf(int height, String time, String elapsed) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'حتى الكتلة $heightString ($time، $elapsed)';
  }

  @override
  String newBlocksSince(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString كتلة جديدة منذ ذلك',
      many: '$countString كتلة جديدة منذ ذلك',
      few: '$countString كتل جديدة منذ ذلك',
      two: 'كتلتان جديدتان منذ ذلك',
      one: 'كتلة جديدة واحدة منذ ذلك',
      zero: 'محدّث',
    );
    return '$_temp0';
  }

  @override
  String agoSeconds(int s) {
    return 'منذ $s ث';
  }

  @override
  String agoMinutes(int m, int s) {
    return 'منذ $m د $s ث';
  }

  @override
  String agoHours(int h, int m) {
    return 'منذ $h س $m د';
  }

  @override
  String agoDays(int d, int h) {
    final intl.NumberFormat dNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String dString = dNumberFormat.format(d);

    return 'منذ $dString ي $h س';
  }

  @override
  String get refresh => 'تحديث';

  @override
  String threadStarted(String time) {
    return 'بدأ $time';
  }

  @override
  String threadLastReply(String time) {
    return 'آخر رد $time';
  }

  @override
  String get messagesNeedWallet =>
      'أنشئ محفظة أو استوردها في تبويب «المحفظة» لترى رسائلك.';

  @override
  String get noMessages => 'لا رسائل تطابق هذه المرشحات.';

  @override
  String get filterThreads => 'مواضيعي';

  @override
  String get filterRepliesSent => 'الردود المرسلة';

  @override
  String get filterRepliesReceived => 'الردود المستلمة';

  @override
  String get filterFlagsSent => 'البلاغات المقدّمة';

  @override
  String get filterFlagsReceived => 'البلاغات المستلمة';

  @override
  String get balance => 'الرصيد';

  @override
  String pendingCommitted(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString محجوزة لمعاملات معلّقة';
  }

  @override
  String blocksMined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString كتلة مُعدَّنة',
      many: '$countString كتلة مُعدَّنة',
      few: '$countString كتل مُعدَّنة',
      two: 'كتلتان مُعدَّنتان',
      one: 'كتلة واحدة مُعدَّنة',
      zero: 'لم تُعدَّن أي كتلة',
    );
    return '$_temp0';
  }

  @override
  String get address => 'العنوان';

  @override
  String get showSeed => 'عرض البذرة';

  @override
  String get removeWallet => 'إزالة المحفظة';

  @override
  String get history => 'السجل';

  @override
  String get filters => 'المرشحات';

  @override
  String get noHistory => 'لا معاملات تطابق هذه المرشحات.';

  @override
  String get walletFilterTransfersSent => 'التحويلات المرسلة';

  @override
  String get walletFilterTransfersReceived => 'التحويلات المستلمة';

  @override
  String get walletFilterRepliesPaid => 'المدفوع مقابل الردود';

  @override
  String get walletFilterRepliesEarned => 'المكتسب من الردود';

  @override
  String get walletFilterThreadCosts => 'تكاليف المواضيع';

  @override
  String get walletFilterFlagCosts => 'رسوم البلاغات';

  @override
  String get seedTitle => 'بذرة المحفظة';

  @override
  String get seedWarning =>
      'يستطيع أي شخص يملك هذه البذرة الإنفاق من هذه المحفظة. صيغتها هي صيغة ملف المفتاح الذي يُنشئه الأمر murmur-node keygen.';

  @override
  String get done => 'تم';

  @override
  String get removeWalletTitle => 'إزالة المحفظة؟';

  @override
  String get removeWalletBody =>
      'ستُحذف البذرة من هذا الجهاز. من دون نسخة منها، يضيع أي رصيد على هذا العنوان.';

  @override
  String get remove => 'إزالة';

  @override
  String get importWallet => 'استيراد محفظة';

  @override
  String get importHelp =>
      'اكتب أو الصق بذرة محفظة: كلماتها الـ24 أو أحرفها الست عشرية الـ64 (مثل محتوى ملف مفتاح أُنشئ بـ murmur-node keygen، أي murmur.key، لاستخدام المكافآت المُعدَّنة إلى عنوانه).';

  @override
  String get seed => 'البذرة';

  @override
  String get import => 'استيراد';

  @override
  String get seedInvalid => 'البذرة 24 كلمة أو 64 حرفًا ست عشريًا بالضبط.';

  @override
  String get walletIntro =>
      'توقّع المحفظة المعاملات التي ترسلها. ويبقى مفتاحها على هذا الجهاز.';

  @override
  String get createWallet => 'إنشاء محفظة جديدة';

  @override
  String get importSeed => 'استيراد بذرة';

  @override
  String noBlockAt(int height, int tip) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat tipNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tipString = tipNumberFormat.format(tip);

    return 'لا توجد كتلة على الارتفاع $heightString (القمة عند $tipString).';
  }

  @override
  String get searchInvalid =>
      'أدخل ارتفاع كتلة، أو معرّف معاملة أو تجزئة كتلة أو عنوانًا من 64 حرفًا.';

  @override
  String get searchHint =>
      'ابحث عن ارتفاع أو معرّف معاملة أو تجزئة كتلة أو عنوان';

  @override
  String get noBlocks => 'لا كتل بعد.';

  @override
  String blockTitle(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'الكتلة $heightString';
  }

  @override
  String txShortCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString معاملة',
      many: '$countString معاملة',
      few: '$countString معاملات',
      two: 'معاملتان',
      one: 'معاملة واحدة',
      zero: 'لا معاملات',
    );
    return '$_temp0';
  }

  @override
  String minerIs(String miner) {
    return 'المُعدِّن $miner';
  }

  @override
  String get statNetwork => 'الشبكة';

  @override
  String get statHeight => 'الارتفاع';

  @override
  String get statNodeHeight => 'ارتفاع العقدة';

  @override
  String get statNextReward => 'مكافأة الكتلة التالية';

  @override
  String rewardPlusFees(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString + الرسوم';
  }

  @override
  String get statBurnPool => 'مجمع الحرق';

  @override
  String get statCirculating => 'المتداول';

  @override
  String get tip => 'القمة';

  @override
  String get previousBlock => 'الكتلة السابقة';

  @override
  String get nextBlock => 'الكتلة التالية';

  @override
  String get blockGone => 'لم تعد هذه الكتلة على أفضل سلسلة.';

  @override
  String get hash => 'التجزئة';

  @override
  String get previous => 'السابقة';

  @override
  String get time => 'الوقت';

  @override
  String get confirmations => 'التأكيدات';

  @override
  String get miner => 'المُعدِّن';

  @override
  String get reward => 'المكافأة';

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

    return '$subsidyString إعانة + $payoutString من مجمع الحرق + $feesString رسوم';
  }

  @override
  String get merkleRoot => 'جذر ميركل';

  @override
  String get target => 'الهدف';

  @override
  String get nonce => 'النونس';

  @override
  String txCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString معاملة',
      many: '$countString معاملةً',
      few: '$countString معاملات',
      two: 'معاملتان',
      one: 'معاملة واحدة',
      zero: 'لا معاملات',
    );
    return '$_temp0';
  }

  @override
  String get yourAddress => 'عنوانك';

  @override
  String get noTransactions => 'لا معاملات.';

  @override
  String get sendToAddress => 'الإرسال إلى هذا العنوان';

  @override
  String get threadGone => 'لم يعد هذا الموضوع على السلسلة.';

  @override
  String paidToParent(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'دفع $amountString لكاتب الرسالة الأصلية';
  }

  @override
  String get actionReply => 'رد';

  @override
  String get actionFlag => 'إبلاغ';

  @override
  String get flagged => 'تم الإبلاغ';

  @override
  String get details => 'التفاصيل';

  @override
  String get txTitle => 'معاملة';

  @override
  String get txNotFound =>
      'لم يُعثر على المعاملة. ربما أُسقطت من المعاملات المعلّقة أو أزالتها إعادة تنظيم.';

  @override
  String refNotLocal(String txid) {
    return 'المعاملة $txid (ليست على السلسلة المحلية)';
  }

  @override
  String get flaggedMessage => 'رسالة مُبلَّغ عنها';

  @override
  String get inReplyTo => 'ردًّا على';

  @override
  String get notThreadedExplain =>
      'يشير إلى هذه الرسالة لكنه ليس جزءًا من موضوعها: يجب أن تكون الرسالة موضوعًا أو ردًّا مُعدَّنًا، وأن يدفع هذا الرد لكاتبها. يُحتسب دفعةً فقط.';

  @override
  String get message => 'الرسالة';

  @override
  String get openThread => 'فتح الموضوع';

  @override
  String get transactionId => 'معرّف المعاملة';

  @override
  String get type => 'النوع';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get burned => 'المحروق';

  @override
  String burnedValue(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString (يعود إلى المُعدِّنين عبر مجمع الحرق)';
  }

  @override
  String get amount => 'المبلغ';

  @override
  String get fee => 'الرسوم';

  @override
  String get signedAt => 'وُقّعت في';

  @override
  String get contentHash => 'تجزئة المحتوى';

  @override
  String get contentSize => 'حجم المحتوى';

  @override
  String contentSizeValue(int size, int salt, int message) {
    final intl.NumberFormat sizeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);
    final intl.NumberFormat messageNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String messageString = messageNumberFormat.format(message);

    return '$sizeString بايت (ملح من $salt بايت ورسالة من $messageString بايت)';
  }

  @override
  String get reports => 'تُبلغ عن';

  @override
  String get repliesTo => 'ترد على';

  @override
  String get weight => 'الوزن';

  @override
  String weightValue(int weight, String perByte) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return '$weightString بايت ($perByte رسوم لكل بايت)';
  }

  @override
  String get publicKey => 'المفتاح العام';

  @override
  String confirmedIn(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'مؤكدة في الكتلة $heightString';
  }

  @override
  String confirmationCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString تأكيد',
      many: '$countString تأكيدًا',
      few: '$countString تأكيدات',
      two: 'تأكيدان',
      one: 'تأكيد واحد',
      zero: 'لا تأكيدات',
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
      other: 'لم تُؤكَّد بعد $countString كتلة',
      many: 'لم تُؤكَّد بعد $countString كتلة',
      few: 'لم تُؤكَّد بعد $countString كتل',
      two: 'لم تُؤكَّد بعد كتلتين',
      one: 'لم تُؤكَّد بعد كتلة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get maybeRefused =>
      'ربما رفضتها العقدة (مثلًا إذا تغيّر الرصيد قبل تعدينها). لا تُبلغ العقدة عن المعاملات المرفوضة.';

  @override
  String get sentWaiting => 'أُرسلت، بانتظار كتلة';

  @override
  String get submittedHere => 'أُرسلت من هذا الجهاز.';

  @override
  String get pendingTitle => 'معلّقة';

  @override
  String get relayedPending => 'أعادت العقدة بثّها، وليست في كتلة بعد.';

  @override
  String get viewBlock => 'عرض الكتلة';

  @override
  String get newTransaction => 'معاملة جديدة';

  @override
  String get flagMessage => 'الإبلاغ عن رسالة';

  @override
  String flaggingInfo(String author) {
    return 'أنت تُبلغ عن هذه الرسالة من $author. يمكن لكل محفظة الإبلاغ عن الرسالة مرة واحدة. ويقرر كل عميل ما يفعله بالبلاغات.';
  }

  @override
  String replyingTo(String author) {
    return 'رد على $author';
  }

  @override
  String explainThread(int total, int burn) {
    return 'يبدأ موضوعًا جديدًا. تكلفته $total × الرسوم: تذهب الرسوم إلى المُعدِّن، ويُحرق $burn × الرسوم. تعود الرموز المحروقة إلى المُعدِّنين في الكتل التالية.';
  }

  @override
  String get explainReply =>
      'يدفع ردّك لكاتب الرسالة الرسومَ على الأقل (ويمكنك دفع إكرامية أكبر)، إضافة إلى الرسوم للمُعدِّن.';

  @override
  String get explainTransfer =>
      'تحويل رموز بسيط بلا رسالة. يجب ألا يقل المبلغ عن الرسوم.';

  @override
  String get recipientAddress => 'عنوان المستلم';

  @override
  String get enterAddress => 'أدخل عنوانًا سداسيًا عشريًا من 64 حرفًا';

  @override
  String get payToAuthor => 'الدفع للكاتب';

  @override
  String get wholeNumber => 'عدد صحيح';

  @override
  String atLeastFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'الرسوم على الأقل ($feeString)';
  }

  @override
  String get feeToMiner => 'الرسوم (للمُعدِّن)';

  @override
  String suggestedFee(int fee) {
    final intl.NumberFormat feeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String feeString = feeNumberFormat.format(fee);

    return 'المقترح: $feeString';
  }

  @override
  String get atLeastOne => '1 على الأقل';

  @override
  String bytesOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$countString / $maxString بايت';
  }

  @override
  String tooLong(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'طويلة جدًا: $countString بايت';
  }

  @override
  String get sendingNeedsLive =>
      'يصبح الإرسال متاحًا عندما يتصل العميل ويكتمل التزامن.';

  @override
  String get signAndSend => 'توقيع وإرسال';

  @override
  String get costFee => 'الرسوم، للمُعدِّن';

  @override
  String costBurn(int multiple) {
    return 'المحروق: $multiple × الرسوم';
  }

  @override
  String get costPaid => 'المدفوع للمستلم';

  @override
  String get costTotal => 'التكلفة الإجمالية';

  @override
  String get costAvailable => 'المتاح: الرصيد مطروحًا منه المعاملات المعلّقة';

  @override
  String get costRemaining => 'المتبقي بعد الإرسال';

  @override
  String get checkingFees => 'جارٍ التحقق من رسوم الشبكة…';

  @override
  String feeLocal(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'تقدير مبني على ما رآه هذا العميل ($countString معلّقة منذ اتصاله)؛ لم يكن تقرير الرسوم الخاص بالعقدة متاحًا.';
  }

  @override
  String get use => 'استخدام';

  @override
  String get checkAgain => 'التحقق مجددًا';

  @override
  String balanceBeforeAfter(int before, int after) {
    final intl.NumberFormat beforeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String beforeString = beforeNumberFormat.format(before);
    final intl.NumberFormat afterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String afterString = afterNumberFormat.format(after);

    return '$beforeString ← $afterString';
  }

  @override
  String balanceBeforeAfterTooltip(int before, int after) {
    final intl.NumberFormat beforeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String beforeString = beforeNumberFormat.format(before);
    final intl.NumberFormat afterNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String afterString = afterNumberFormat.format(after);

    return 'الرصيد: $beforeString قبل، $afterString بعد';
  }

  @override
  String chainCounted(int counted, int total) {
    final intl.NumberFormat countedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countedString = countedNumberFormat.format(counted);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'تم عدّ $countedString من $totalString كتلة';
  }

  @override
  String get loadingOlder => 'جارٍ تحميل الكتل الأقدم…';

  @override
  String get blockLoading => 'جارٍ تحميل هذه الكتلة…';

  @override
  String get txSearching =>
      'جارٍ البحث عن هذه المعاملة في الكتل التي لا تزال قيد التحميل…';

  @override
  String get storageBanner =>
      'هل تريد الاحتفاظ بنسخة من السلسلة على هذا الجهاز؟ عندها تُفتح الزيارات اللاحقة في ثوانٍ بدلًا من تنزيل كل شيء من جديد. تبقى هنا ولا تُرسل إلى أحد أبدًا: لا ملفات تعريف ارتباط ولا تتبّع. ويبقى مفتاح محفظتك وإعداداتك دائمًا على هذا الجهاز لأن التطبيق يحتاجها ليعمل.';

  @override
  String get storageAllow => 'السماح بالتخزين الضروري';

  @override
  String get storageReject => 'الرفض (أبطأ)';

  @override
  String get storageOn => 'النسخة المحلية من السلسلة: مفعّلة';

  @override
  String get storageOff =>
      'النسخة المحلية من السلسلة: متوقفة (كل زيارة تنزّلها من جديد)';

  @override
  String get storageTurnOn => 'تفعيل';

  @override
  String get storageTurnOff => 'إيقاف وحذف';

  @override
  String get checkingBalance => 'جارٍ التحقق مع العقدة…';

  @override
  String get errTampered =>
      'تم التلاعب بالاتصال أو قطعه: فشلت رسالة في فحص السلامة.';

  @override
  String errStateMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'الحالة التي تلتزم بها العقدة عند الكتلة $heightString لا تطابق عدّ هذا العميل للسلسلة. لا تثق بهذه العقدة: اتصل بعقدة أخرى.';
  }

  @override
  String feeFromNode(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من العقدة: $countString معاملة معلّقة.',
      many: 'من العقدة: $countString معاملة معلّقة.',
      few: 'من العقدة: $countString معاملات معلّقة.',
      two: 'من العقدة: معاملتان معلّقتان.',
      one: 'من العقدة: معاملة واحدة معلّقة.',
      zero: 'من العقدة: لا شيء معلّق.',
    );
    return '$_temp0';
  }

  @override
  String get statusAccepted => 'قبلتها العقدة وأعادت بثّها.';

  @override
  String get statusRefused => 'رفضتها العقدة';

  @override
  String get statusInvalid => 'رُفضت لأنها غير صالحة';

  @override
  String nodeReason(String reason) {
    return 'تقول العقدة: $reason';
  }

  @override
  String errCheckpointMismatch(int height) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);

    return 'السلسلة لا تقود إلى نقطة التحقق الخاصة بهذا الإصدار عند الكتلة $heightString: إما أن الإصدار خاطئ أو أن جميع العقد التي تم الوصول إليها خاطئة. توقف؛ لا يمكن الوثوق بأي شيء منها.';
  }

  @override
  String staleTip(String elapsed) {
    return 'أحدث كتلة من $elapsed: قد تكون هذه العقدة متأخرة أو معزولة عن الشبكة. ما تراه قد لا يكون محدّثًا.';
  }

  @override
  String checkingToGenesis(int height, int done) {
    final intl.NumberFormat heightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String heightString = heightNumberFormat.format(height);
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);

    return 'بدأ من نقطة التحقق عند الكتلة $heightString؛ جارٍ التحقق من الترويسات حتى كتلة البداية ($doneString حتى الآن).';
  }

  @override
  String get licenses => 'التراخيص';

  @override
  String get appLicense => 'Apache License 2.0';

  @override
  String get testnetLabel => 'شبكة اختبار: الرموز لا قيمة لها';

  @override
  String get linkNodeRepo => 'شيفرة العقدة والبروتوكول';

  @override
  String get linkWhitepaper => 'الورقة البيضاء';

  @override
  String checkingHeaders(int done, int total) {
    final intl.NumberFormat doneNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String doneString = doneNumberFormat.format(done);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'جارٍ التحقق من ترويسات الكتل: $doneString من $totalString';
  }

  @override
  String reconnectingIn(int seconds) {
    return 'محاولة جديدة خلال $seconds ث.';
  }

  @override
  String get languagesFilter => 'اللغات';

  @override
  String get languageUndetected => 'غير محددة';

  @override
  String get hideFlaggedThreads => 'إخفاء المواضيع التي أبلغت عنها';

  @override
  String get star => 'تمييز بنجمة';

  @override
  String get unstar => 'إزالة النجمة';

  @override
  String get starredOnly => 'المواضيع المميزة بنجمة فقط';

  @override
  String get localNodeRun => 'تشغيل عقدة Murmur على هذا الحاسوب';

  @override
  String get localNodeExplain =>
      'يتحقق حاسوبك من السلسلة بنفسه، ويساعد في نقلها، ويبقي رسائلك متاحة. ولا يحتفظ برسائل أي شخص آخر بعد فحص الساعة الواحدة.';

  @override
  String get localNodeStarting => 'جارٍ تشغيل العقدة…';

  @override
  String get localNodeRunning => 'العقدة تعمل، والتطبيق يستخدمها.';

  @override
  String localNodeFailed(String reason) {
    return 'توقفت العقدة: $reason';
  }

  @override
  String get localNodeFailedUnknown => 'توقفت العقدة على نحو غير متوقع.';

  @override
  String get localNodeMine => 'التعدين بهذا الحاسوب';

  @override
  String get localNodeMineNote =>
      'يدفع التعدين إلى عنوان محفظتك، ويستهلك الكهرباء ويُجهد حاسوبك أكثر. على شبكة الاختبار، الرموز للاختبار فقط.';

  @override
  String get localNodeMineNeedsWallet =>
      'أنشئ محفظة أولًا: التعدين يدفع إلى عنوانها.';

  @override
  String localNodeCpu(int pct) {
    return 'حتى $pct٪ من نواة معالج واحدة';
  }

  @override
  String threadsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موضوع مخفي',
      many: '$count موضوعًا مخفيًا',
      few: '$count مواضيع مخفية',
      two: 'موضوعان مخفيان',
      one: 'موضوع واحد مخفي',
    );
    return '$_temp0';
  }

  @override
  String get searchThreads => 'البحث في المواضيع المحمّلة';

  @override
  String get noMatches => 'لا يطابق أي موضوع محمّل.';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int n) {
    return 'منذ $n د';
  }

  @override
  String timeHoursAgo(int n) {
    return 'منذ $n س';
  }

  @override
  String timeDaysAgo(int n) {
    return 'منذ $n ي';
  }

  @override
  String get nameAddress => 'الاسم';

  @override
  String get aliasTitle => 'تسمية هذا العنوان';

  @override
  String get aliasHelp =>
      'يُحفظ الاسم على هذا الجهاز فقط. اتركه فارغًا لإزالته.';

  @override
  String get save => 'حفظ';

  @override
  String get mute => 'كتم';

  @override
  String get unmute => 'إلغاء الكتم';

  @override
  String get mutedNote => 'مكتوم: مواضيعه وردوده مخفية على هذا الجهاز.';

  @override
  String mutedRepliesHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رد من عناوين مكتومة مخفي',
      many: '$count ردًّا من عناوين مكتومة مخفيًا',
      few: '$count ردود من عناوين مكتومة مخفية',
      two: 'ردّان من عناوين مكتومة مخفيان',
      one: 'رد واحد من عنوان مكتوم مخفي',
    );
    return '$_temp0';
  }

  @override
  String newReplies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رد جديد',
      many: '$count ردًّا جديدًا',
      few: '$count ردود جديدة',
      two: 'ردّان جديدان',
      one: 'رد جديد واحد',
    );
    return '$_temp0';
  }

  @override
  String get invitations => 'الدعوات';

  @override
  String get createInvitations => 'إنشاء دعوات';

  @override
  String get inviteHowMany => 'عدد البطاقات';

  @override
  String get inviteFund => 'تمويل البطاقات';

  @override
  String get inviteCardTitle => 'دعوة إلى Murmur';

  @override
  String inviteCardSerial(int n, int total) {
    return '$n من $total';
  }

  @override
  String inviteCardFrom(String name) {
    return 'من $name';
  }

  @override
  String get inviteCardHow => 'امسح الرمز أو افتح الرابط للانضمام إلى Murmur.';

  @override
  String get inviteClaimed => 'مستلمة';

  @override
  String get inviteChecking => 'جارٍ التحقق…';

  @override
  String get claimTitle => 'أنت مدعو';

  @override
  String claimInvitedBy(String name) {
    return 'دعوة من $name';
  }

  @override
  String claimHolds(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return 'تحمل هذه الدعوة $amountString: ما يكفي لبدء مواضيعك الأولى.';
  }

  @override
  String get claimCreateWallet => 'إنشاء محفظتي والاستلام';

  @override
  String get claimIntoWallet => 'الاستلام إلى محفظتي';

  @override
  String get claimDone =>
      'تم الاستلام. تصل الرموز إلى محفظتك مع الكتلة التالية.';

  @override
  String get claimEmpty => 'سبق أن استُلمت هذه الدعوة أو استُرجعت.';

  @override
  String get claimWrongNetwork =>
      'هذه الدعوة لشبكة غير شبكة العقدة المتصل بها.';

  @override
  String get claimInvalid => 'هذا ليس رمز دعوة صالحًا.';

  @override
  String get haveInvitation => 'لدي دعوة';

  @override
  String get inviteCodeField => 'رمز الدعوة أو رابطها';

  @override
  String get claim => 'استلام';

  @override
  String get cancelInvitation => 'إلغاء الدعوة';

  @override
  String get inviteCancelled => 'ملغاة';

  @override
  String cancelInviteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'إلغاء $count دعوة؟',
      many: 'إلغاء $count دعوة؟',
      few: 'إلغاء $count دعوات؟',
      two: 'إلغاء دعوتين؟',
      one: 'إلغاء هذه الدعوة؟',
    );
    return '$_temp0';
  }

  @override
  String cancelInviteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعود رموزها، ولن يتمكن من يحمل البطاقات من استلامها.',
      one: 'تعود رموزها، ولن يتمكن من يحمل البطاقة من استلامها.',
    );
    return '$_temp0';
  }

  @override
  String get keepInvitation => 'الإبقاء عليها';

  @override
  String get printOne => 'طباعة';

  @override
  String inviteDoneSection(int count) {
    return 'مستلمة أو ملغاة ($count)';
  }

  @override
  String get inviteEachLabel => 'كل بطاقة';

  @override
  String get inviteEachCaption => 'خمسة مواضيع برسوم اليوم، ورسوم استلامها.';

  @override
  String get inviteTotalLabel => 'تدفع';

  @override
  String get inviteTotalCaption => 'إجمالًا، بما في ذلك الرسوم.';

  @override
  String get inviteWaitingState => 'بانتظار الاستلام';

  @override
  String get inviteCardSlogan => 'لصوتك مكان هنا.';

  @override
  String get inviteCardJoin => 'امسح للانضمام';

  @override
  String get share => 'مشاركة…';

  @override
  String get inviteDetailFunded => 'مُوّلت';

  @override
  String get inviteDetailClaimedBy => 'استلمها';

  @override
  String get inviteDetailReceived => 'المُستلم';

  @override
  String get inviteDetailCancelled => 'ملغاة: عادت الرموز إلى محفظتك';

  @override
  String get inviteDetailReturned => 'المُعاد';

  @override
  String get inviteDetailOnItsWay => 'في طريقها إلى كتلة';

  @override
  String get seedConfirmTitle => 'عرض البذرة؟';

  @override
  String get seedConfirmBody =>
      'يستطيع أي شخص يرى البذرة الإنفاق من هذه المحفظة. تأكد من ألا يرى أحد غيرك شاشتك.';

  @override
  String get showAction => 'عرض';

  @override
  String get authReasonSeed => 'أكّد هويتك لرؤية بذرة المحفظة';

  @override
  String get authReasonRemove => 'أكّد هويتك لإزالة هذه المحفظة';

  @override
  String get authFailed => 'لم يتم التأكيد: لم يُعرض أو يتغيّر شيء.';

  @override
  String get passphraseNewTitle => 'اختر عبارة مرور';

  @override
  String get passphraseNewBody =>
      'تشفّر مفتاح محفظتك على هذا الجهاز. ستكتبها للإرسال أو لعرض البذرة أو لإزالة المحفظة. إذا نسيتها فلن تستعيد المحفظة إلا نسخة البذرة الاحتياطية.';

  @override
  String get passphraseField => 'عبارة المرور';

  @override
  String get passphraseRepeat => 'أعد كتابة عبارة المرور';

  @override
  String passphraseTooShort(int min) {
    return '$min أحرف على الأقل';
  }

  @override
  String get passphraseMismatch => 'العبارتان غير متطابقتين';

  @override
  String get passphraseTitle => 'عبارة المرور';

  @override
  String get wrongPassphrase => 'عبارة مرور خاطئة: لم يُعرض أو يُرسل شيء.';

  @override
  String get unlock => 'فتح';

  @override
  String get authReasonSend => 'أكّد هويتك للتوقيع والإرسال';

  @override
  String get authReasonNewWallet => 'احمِ مفتاح محفظتك على هذا الجهاز';

  @override
  String get authReasonInvite => 'أكّد هويتك لتمويل البطاقات';

  @override
  String get removeAnywayTitle => 'إزالة دون تأكيد؟';

  @override
  String get removeAnywayBody =>
      'تعذّر فتح المحفظة. إزالتها تحذف مفتاحها من هذا الجهاز: لن تستعيدها إلا نسخة البذرة الاحتياطية.';

  @override
  String get protectionDevice => 'المفتاح مشفّر بقفل هذا الجهاز';

  @override
  String get protectionPasskey => 'المفتاح مشفّر بمفتاح مرور على هذا الجهاز';

  @override
  String get protectionPassphrase => 'المفتاح مشفّر بعبارة المرور الخاصة بك';

  @override
  String get protectionLegacy =>
      'المفتاح غير مشفّر بعد: سيُشفَّر عند الفتح التالي';

  @override
  String get confirmSendTitle => 'راجِع قبل التوقيع';

  @override
  String get confirmSendFinal =>
      'التوقيع يرسل هذا إلى العقدة. لا يمكن التراجع عنه: بعد تعدينه يبقى في السلسلة.';

  @override
  String signAndSendShortcut(String keys) {
    return 'وقّع وأرسل ($keys)';
  }

  @override
  String get threadWithdrawnMine =>
      'سحبته: مخفي عن الآخرين، ونصه محذوف من تطبيقات Murmur';

  @override
  String get threadWithdrawnMineNote =>
      'أبلغت عن موضوعك، وهذا يسحبه. لم تعد تطبيقات Murmur تعرضه للآخرين وتحذف نصه، على هذا الجهاز أيضًا؛ وقد تتوقف العقد عن حفظ نصه وردوده.';

  @override
  String get threadWithdrawnNote =>
      'أبلغ كاتب هذا الموضوع عنه، وهذا يسحبه. لم تعد تطبيقات Murmur تدرجه وتحذف نصه، وقد تتوقف العقد عن حفظ نصه وردوده.';

  @override
  String get flagOwnInfo =>
      'هذه رسالتك. الإبلاغ عنها يسحبها: تتوقف تطبيقات Murmur عن عرضها للآخرين وتحذف نصها، على هذا الجهاز أيضًا، وقد تتوقف العقد عن حفظ نصها وردودها. لا يمكن التراجع عن ذلك.';

  @override
  String get inviteFromTitle => 'الاسم على البطاقات';

  @override
  String get inviteFromBody =>
      'تذكر كل بطاقة ممن هي. موّلتها المحفظة الداعية، وقد لا تكون هي المحفظة الموجودة على هذا الجهاز الآن.';

  @override
  String get inviteFromOriginal => 'عنوان المحفظة الداعية';

  @override
  String get inviteFromOriginalAlias => 'اسمك للمحفظة الداعية';

  @override
  String get inviteFromOriginalPublic => 'الاسم العام للمحفظة الداعية';

  @override
  String get inviteFromCurrent => 'عنوان هذه المحفظة';

  @override
  String get inviteFromCurrentAlias => 'اسمك لهذه المحفظة';

  @override
  String get inviteFromCurrentPublic => 'الاسم العام لهذه المحفظة';

  @override
  String get inviteFromCustom => 'نص آخر';

  @override
  String get inviteFromCustomHint => 'اتركه فارغًا لعدم طباعة أي اسم';

  @override
  String get inviteFromNotSet => 'لا اسم معطى على هذا الجهاز';

  @override
  String get inviteFromMixed => 'يختلف بين البطاقات المختارة';

  @override
  String get inviteFromChecking => 'ما زال البحث جاريًا في السلسلة';

  @override
  String get cancelReturnTo => 'أرسل الرموز إلى';

  @override
  String get cancelToFunder => 'المحفظة التي موّلتها';

  @override
  String get cancelToCurrent => 'هذه المحفظة';

  @override
  String get publicName => 'الاسم العام';

  @override
  String get publicNameNone => 'لا شيء معروف';

  @override
  String get publicNameSet => 'تعيين الاسم العام';

  @override
  String get publicNameField => 'الاسم';

  @override
  String aliasTooLong(int max) {
    final intl.NumberFormat maxNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$maxString بايت على الأكثر';
  }

  @override
  String get aliasBadCharacter =>
      'لا يُسمح بالمحارف غير المرئية أو محارف التحكم';

  @override
  String get aliasEdgeSpace => 'بلا مسافات في البداية أو النهاية';

  @override
  String aliasSetTo(String name) {
    return 'الاسم العام: $name';
  }

  @override
  String get aliasCleared => 'أُزيل الاسم العام';

  @override
  String get nonTextMessage => '(ليس نصًا: بيانات لاصطلاح بين التطبيقات)';

  @override
  String explainAlias(int total, int burn) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat burnNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String burnString = burnNumberFormat.format(burn);

    return 'ينشر اسمك العام. مثل موضوع جديد، يكلف $totalString × الرسوم: تذهب الرسوم إلى المعدِّن ويُحرق $burnString × الرسوم.';
  }

  @override
  String get inviteFromNoPublic => 'لا اسم عام معروف';

  @override
  String get starredTitle => 'المميزة بنجمة';

  @override
  String get noStarred =>
      'لا شيء مميز بنجمة بعد. ميّز موضوعًا أو رسالة أو شخصًا بنجمة من صفحته وسيظهر هنا.';

  @override
  String get starredGone => 'لم يعد على السلسلة';

  @override
  String get feeSuggestedLabel => 'الرسوم المقترحة';

  @override
  String feeForBytes(int weight) {
    final intl.NumberFormat weightNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String weightString = weightNumberFormat.format(weight);

    return 'لـ $weightString بايت';
  }

  @override
  String get feeRoom => 'في الكتل متسع';

  @override
  String get feeFull => 'الكتل ممتلئة';

  @override
  String get feeNextBlock => 'الكتلة التالية';

  @override
  String get feePoolEntry => 'لدخول المجمّع';

  @override
  String get feeMinimum => 'الحد الأدنى';

  @override
  String get feeWhy => 'لماذا هذه الرسوم';

  @override
  String feePerBytePoint(int base) {
    final intl.NumberFormat baseNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String baseString = baseNumberFormat.format(base);

    return '**الرسوم لكل بايت**: $baseString بايت إضافة إلى رسالتك. الرسائل الطويلة تكلف أكثر حين تمتلئ الكتل.';
  }

  @override
  String feeRecentPoint(int lowest, int median) {
    final intl.NumberFormat lowestNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String lowestString = lowestNumberFormat.format(lowest);
    final intl.NumberFormat medianNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String medianString = medianNumberFormat.format(median);

    return '**الكتل الأخيرة** قبلت رسومًا لا تتجاوز **$lowestString** (الوسيط $medianString).';
  }

  @override
  String get feeRecentNonePoint => '**الكتل الأخيرة** لم تحوِ معاملات.';

  @override
  String get inviteNoExpiryPoint =>
      '**لا تنتهي صلاحيتها**: تبقى البطاقة صالحة حتى يستلمها أحد.';

  @override
  String get inviteCancelPoint => '**ألغِها متى شئت**: تعود رموزها.';

  @override
  String get invitePublicPoint =>
      '**علني**: تُظهر السلسلة أنك موّلت كل بطاقة وأي محفظة استلمتها.';

  @override
  String get inviteCashPoint =>
      '**من يملك الرمز** يمكنه استلام البطاقة. أبقِ البطاقات خاصة حتى تسلّمها.';

  @override
  String get inviteLocalPoint =>
      '**محفوظة على هذا الجهاز فقط.** إذا مُسحت بياناته أو أُزيل التطبيق، **تضيع الرموز إلى الأبد**، ومعها رموز البطاقات التي لم تُسلَّم بعد.';

  @override
  String get publicNameIntro =>
      'يظهر اسمك العام **بجانب عنوانك** في تطبيقات Murmur.';

  @override
  String publicNameShownAs(String name) {
    return 'سيظهر هكذا: **$name**';
  }

  @override
  String get publicNameNotUnique =>
      '**ليس فريدًا**: يمكن لأي شخص اختيار الاسم نفسه. العنوان بجانبه يميّز الناس.';

  @override
  String get publicNameCost =>
      '**يكلف ما يكلفه موضوع جديد**، في كل مرة تعيّنه أو تغيّره.';

  @override
  String get publicNameRemovable =>
      '**رسالة على السلسلة**: يمكن لأي عقدة حذفها، فتختفي.';

  @override
  String get publicNameClear => '**اتركه فارغًا** لإزالته.';

  @override
  String get passkeyNoPrfTitle =>
      'مدير مفاتيح المرور هذا لا يستطيع حماية المحفظة';

  @override
  String get passkeyNoPrfWhy =>
      '**لا يستطيع التشفير.** لقفل مفتاح محفظتك، يجب أن يشتق المدير مفتاحًا من مفتاح المرور (WebAuthn PRF). المدير الذي اخترته لا يفعل ذلك.';

  @override
  String get passkeyNoPrfTry =>
      '**جرّب مديرًا آخر**، مثل كلمات سر Apple أو مدير كلمات المرور من Google، أو احمِ المحفظة **بعبارة مرور**.';

  @override
  String get passkeyNoPrfLeftover =>
      'مفتاح المرور الذي حفظه للتو (**Murmur wallet**) لا يفتح شيئًا: يمكنك حذفه من ذلك المدير.';

  @override
  String get passkeyTryAnother => 'جرّب مدير مفاتيح مرور آخر';

  @override
  String get passkeyUsePassphrase => 'استخدم عبارة مرور';

  @override
  String inviteDetailCancelledTo(String name) {
    return 'أُلغيت: ذهبت الرموز إلى $name';
  }

  @override
  String get seedNewTitle => 'احفظ بذرة محفظتك';

  @override
  String get seedNewKeep =>
      '**احتفظ بها في مكان آمن**، بعيدًا عن هذا الجهاز: مكتوبة على ورق أو في مدير كلمات مرور.';

  @override
  String get seedNewOnlyWay =>
      'هي **الطريق الوحيد للعودة** إلى هذه المحفظة إذا فُقد هذا الجهاز أو نُسيت عبارة المرور. لا أحد يستطيع استعادتها لك.';

  @override
  String get seedNewSecret =>
      '**من يملكها يتحكم في المحفظة.** لا تشاركها أبدًا ولا تكتبها في موقع يطلبها.';

  @override
  String get seedNewSaved => 'لقد حفظت بذرتي';

  @override
  String get seedAsWords => 'في 24 كلمة';

  @override
  String get seedAsHex => 'في 64 حرفًا';

  @override
  String get seedEitherForm => 'كلتاهما البذرة نفسها: تكفي واحدة منهما.';

  @override
  String get copyWords => 'نسخ الكلمات';

  @override
  String get copyCharacters => 'نسخ الأحرف';

  @override
  String get seedOrWords => 'البذرة: 24 كلمة أو 64 حرفًا';

  @override
  String seedUnknownWord(String word) {
    return '«$word» ليست من كلمات البذرة. تحقق من كتابتها.';
  }

  @override
  String get seedBadChecksum =>
      'هذه الكلمات الـ24 لا تشكّل بذرة: إحداها خاطئة أو في غير موضعها.';

  @override
  String get qrCode => 'رمز QR';

  @override
  String get addressQrHint => 'امسح الرمز لفتح هذا العنوان في Murmur.';

  @override
  String get starredPeople => 'الأشخاص';

  @override
  String get starredThreads => 'المواضيع والرسائل';

  @override
  String get newActivity => 'نشاط جديد';

  @override
  String starredNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر مميز بنجمة فيه نشاط جديد',
      many: '$count عنصرًا مميزًا بنجمة فيه نشاط جديد',
      few: '$count عناصر مميزة بنجمة فيها نشاط جديد',
      two: 'عنصران مميزان بنجمة فيهما نشاط جديد',
      one: 'عنصر واحد مميز بنجمة فيه نشاط جديد',
    );
    return '$_temp0';
  }
}
