// Guesses a message's language on the device, for the Threads language
// filter. Messages carry no language tag (PROTOCOL.md Section 2.4: content
// is a salt and the text), so the client reads it from the text itself:
//
// - the script settles Arabic, Japanese (kana) and Chinese (Han without kana);
// - Latin-script text is scored by the common words of each language the
//   app speaks, plus a few letters only some of them use (ñ, ã, ß...).
//
// Short or mixed text often can't be told apart; then the answer is null
// ("undetected") rather than a guess. Nothing leaves the device.

/// The languages the detector can name: the app's own.
const detectableLanguages = ['en', 'es', 'it', 'pt', 'de', 'nl', 'ar', 'zh', 'ja'];

/// The filter's name for text whose language couldn't be told.
const undetectedLanguage = 'und';

/// Frequent short words of each language. A word listed in several counts
/// for each, so shared ones cancel out.
const Map<String, Set<String>> _commonWords = {
  'en': {
    'the', 'and', 'is', 'are', 'was', 'were', 'you', 'that', 'this', 'with', 'for', 'not', 'have', 'has', //
    'what', 'but', 'they', 'from', 'will', 'would', 'can', 'there', 'their', 'about', 'just', 'which', 'when',
    'your', 'how', 'all', 'been', 'if', 'my', 'of', 'to', 'it', 'on', 'be', 'we', 'he', 'she', 'do', 'so', 'at',
    'or', 'an', 'by', 'me', 'our', 'i', 'am', 'yes', 'hello', 'thanks', 'good', 'why', 'who', 'where', 'here',
    'does', 'did', 'no', 'in', 'a', 'it\'s', 'i\'m', 'don\'t', 'can\'t', 'should', 'could', 'them', 'these',
  },
  'es': {
    'el', 'la', 'los', 'las', 'de', 'que', 'y', 'en', 'un', 'una', 'es', 'por', 'con', 'para', 'no', 'se', //
    'lo', 'del', 'al', 'como', 'más', 'pero', 'sus', 'le', 'ya', 'o', 'este', 'esta', 'sí', 'porque', 'muy',
    'sin', 'sobre', 'también', 'me', 'hay', 'donde', 'quien', 'desde', 'todo', 'nos', 'cuando', 'hola',
    'gracias', 'bueno', 'está', 'están', 'ser', 'son', 'fue', 'tiene', 'hacer', 'eso', 'qué', 'cómo', 'yo',
    'tú', 'mi', 'tu', 'pues', 'aquí', 'estoy', 'soy', 'mucho', 'algo', 'nada', 'entonces',
  },
  'it': {
    'il', 'lo', 'la', 'i', 'gli', 'le', 'di', 'che', 'e', 'è', 'un', 'una', 'per', 'non', 'in', 'con', //
    'sono', 'del', 'della', 'dei', 'al', 'alla', 'come', 'ma', 'se', 'anche', 'questo', 'questa', 'perché',
    'molto', 'più', 'ciao', 'grazie', 'sì', 'io', 'tu', 'mi', 'ti', 'ci', 'ho', 'hai', 'ha', 'abbiamo',
    'essere', 'fatto', 'cosa', 'tutto', 'quando', 'dove', 'chi', 'bene', 'era', 'nel', 'nella', 'degli',
    'sei', 'siamo', 'qui', 'allora', 'niente', 'qualcosa',
  },
  'pt': {
    'o', 'os', 'a', 'as', 'de', 'que', 'e', 'é', 'um', 'uma', 'em', 'no', 'na', 'nos', 'nas', 'do', 'da', //
    'dos', 'das', 'para', 'com', 'não', 'por', 'mais', 'mas', 'se', 'como', 'ao', 'você', 'eu', 'ele', 'ela',
    'isso', 'isto', 'está', 'estão', 'são', 'foi', 'tem', 'muito', 'também', 'obrigado', 'obrigada', 'olá',
    'sim', 'porque', 'quando', 'onde', 'quem', 'já', 'ainda', 'só', 'meu', 'minha', 'estou', 'sou', 'aqui',
    'então', 'nada', 'algo', 'vocês',
  },
  'de': {
    'der', 'die', 'das', 'und', 'ist', 'nicht', 'ein', 'eine', 'zu', 'den', 'dem', 'des', 'mit', 'sich', //
    'auf', 'für', 'ich', 'du', 'er', 'sie', 'es', 'wir', 'ihr', 'auch', 'als', 'wie', 'aber', 'noch', 'nach',
    'bei', 'aus', 'wenn', 'dass', 'oder', 'sind', 'war', 'hat', 'haben', 'kann', 'nur', 'schon', 'sehr',
    'hier', 'danke', 'hallo', 'ja', 'nein', 'mein', 'dein', 'über', 'im', 'vom', 'zum', 'bin', 'bist', 'was',
    'warum', 'wo', 'wer', 'nichts', 'etwas', 'dann',
  },
  'nl': {
    'de', 'het', 'een', 'en', 'van', 'is', 'dat', 'die', 'niet', 'op', 'te', 'zijn', 'voor', 'met', 'ook', //
    'maar', 'als', 'er', 'aan', 'om', 'hij', 'zij', 'ze', 'wij', 'we', 'jij', 'je', 'ik', 'bij', 'uit', 'nog',
    'naar', 'wat', 'dan', 'kan', 'heb', 'hebben', 'was', 'wordt', 'worden', 'geen', 'meer', 'hallo', 'dank',
    'bedankt', 'ja', 'nee', 'mijn', 'jouw', 'hoe', 'waar', 'wie', 'omdat', 'deze', 'dit', 'goed', 'ben',
    'bent', 'hier', 'niets', 'iets', 'waarom',
  },
};

/// Letters (or pairs) only some of the Latin-script languages use, with the
/// weight they add.
const Map<String, Map<String, int>> _markers = {
  'es': {'ñ': 3, '¿': 3, '¡': 3, 'ó': 1, 'á': 1, 'í': 1},
  'pt': {'ã': 3, 'õ': 3, 'ç': 2, 'ê': 1, 'ô': 1, 'á': 1},
  'de': {'ß': 3, 'ä': 2, 'ö': 2, 'ü': 2, 'sch': 1},
  'nl': {'ij': 2, 'oe': 1, 'aa': 1, 'ee': 1},
  'it': {'è': 2, 'ò': 2, 'ì': 2, 'ù': 2, 'zz': 1, 'gli': 1},
};

bool _isArabic(int c) =>
    (c >= 0x0600 && c <= 0x06FF) || (c >= 0x0750 && c <= 0x077F) || (c >= 0xFB50 && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF);
bool _isKana(int c) => (c >= 0x3040 && c <= 0x30FF) || (c >= 0x31F0 && c <= 0x31FF) || (c >= 0xFF66 && c <= 0xFF9D);
bool _isHan(int c) => (c >= 0x4E00 && c <= 0x9FFF) || (c >= 0x3400 && c <= 0x4DBF) || (c >= 0xF900 && c <= 0xFAFF);
bool _isLatinLetter(int c) =>
    (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || (c >= 0xC0 && c <= 0x24F && c != 0xD7 && c != 0xF7);

final _word = RegExp(r"[\p{L}']+", unicode: true);
final _noise = RegExp(r'\S*(://|www\.|@|\d)\S*');

/// The language `text` is most likely in (one of [detectableLanguages]), or
/// null when it can't be told: too short, mixed, or another language.
String? detectLanguage(String text) {
  var arabic = 0, kana = 0, han = 0, latin = 0;
  for (final c in text.runes) {
    if (_isArabic(c)) {
      arabic++;
    } else if (_isKana(c)) {
      kana++;
    } else if (_isHan(c)) {
      han++;
    } else if (_isLatinLetter(c)) {
      latin++;
    }
  }
  final letters = arabic + kana + han + latin;
  if (letters == 0) return null;
  // Scripts: most of the letters, so a quoted word doesn't decide.
  if (arabic * 2 > letters) return 'ar';
  if (kana > 0 && (kana + han) * 2 > letters) return 'ja';
  if (han * 2 > letters) return 'zh';
  if (latin * 2 <= letters) return null;

  // Links, addresses, hashes and anything with digits say nothing about the
  // language, and their pieces ("elc4no" -> "no") would.
  final lower = text.toLowerCase().replaceAll(_noise, ' ');
  final scores = {for (final lang in _commonWords.keys) lang: 0};
  for (final m in _word.allMatches(lower)) {
    final w = m.group(0)!;
    for (final MapEntry(key: lang, value: words) in _commonWords.entries) {
      if (words.contains(w)) scores[lang] = scores[lang]! + 2;
    }
  }
  for (final MapEntry(key: lang, value: marks) in _markers.entries) {
    for (final MapEntry(key: mark, value: weight) in marks.entries) {
      if (lower.contains(mark)) scores[lang] = scores[lang]! + weight;
    }
  }
  final ranked = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final best = ranked[0], second = ranked[1];
  // Enough evidence, and clearly ahead of the next language.
  if (best.value < 3 || best.value - second.value < 2) return null;
  return best.key;
}
