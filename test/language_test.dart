// The on-device language guess behind the Threads language filter.

import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/services/language.dart';

void main() {
  test('names the language of ordinary messages', () {
    const samples = {
      'en': [
        'I think the new release is ready, but we should test it on the testnet first.',
        'What do you think about this idea?',
        'Thanks, that was really helpful!',
      ],
      'es': [
        'Creo que la nueva versión está lista, pero hay que probarla primero.',
        '¿Qué opinas de esta idea?',
        'Gracias, me ha ayudado mucho.',
      ],
      'it': [
        'Penso che la nuova versione sia pronta, ma dobbiamo provarla prima.',
        'Cosa ne pensi di questa idea?',
        'Grazie, mi hai aiutato molto!',
      ],
      'pt': [
        'Acho que a nova versão está pronta, mas temos de a testar primeiro.',
        'O que você acha dessa ideia?',
        'Obrigado, isso ajudou muito.',
      ],
      'de': [
        'Ich glaube, die neue Version ist fertig, aber wir sollten sie zuerst testen.',
        'Was hältst du von dieser Idee?',
        'Danke, das war sehr hilfreich!',
      ],
      'nl': [
        'Ik denk dat de nieuwe versie klaar is, maar we moeten hem eerst testen.',
        'Wat vind jij van dit idee?',
        'Bedankt, dat heeft mij echt geholpen!',
      ],
      'ar': ['أعتقد أن الإصدار الجديد جاهز، لكن يجب أن نختبره أولاً.'],
      'zh': ['我认为新版本已经准备好了，但我们应该先测试一下。'],
      'ja': ['新しいバージョンは準備できていると思いますが、まずテストするべきです。'],
    };
    for (final MapEntry(key: lang, value: texts) in samples.entries) {
      for (final text in texts) {
        expect(detectLanguage(text), lang, reason: text);
      }
    }
  });

  test('says undetected rather than guess', () {
    for (final text in ['ok', '👍', '12345', 'https://gitlab.com/elc4no/murmur', 'lol', '']) {
      expect(detectLanguage(text), isNull, reason: text);
    }
  });

  test('a quoted word in another script does not decide', () {
    expect(detectLanguage('In Japanese, thank you is ありがとう and that is all I know.'), 'en');
  });
}
