// Murmur emoji: which ":name:" codes in a message are emoji, how a message
// with some is shown and copied, and the picker that writes them. The app
// has none yet, so the tests bring emoji of their own, drawn with the app's
// icons.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/protocol/emoji.dart';
import 'package:murmur_client/ui/emoji.dart';
import 'package:murmur_client/ui/glyphs.dart';
import 'package:murmur_client/ui/l10n.dart';

const _emoji = {'alpha': Glyph.star, 'beta': Glyph.coin, 'gamma': Glyph.flag};
final _names = _emoji.keys.toSet();

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

/// The glyphs drawn on screen, in order.
List<Glyph> _drawn(WidgetTester tester) =>
    tester.widgetList<MurmurIcon>(find.byType(MurmurIcon)).map((i) => i.glyph).toList();

void main() {
  // Emoji as (name), plain text as itself.
  List<Object> cut(String text) => [for (final p in emojiPieces(text, _names)) p.emoji == null ? p.text : (p.emoji,)];

  test('the app takes no name yet, so every message reads as written', () {
    expect(murmurEmoji, isEmpty);
    expect(emojiPieces('a :coin: and :alpha:', murmurEmoji.keys.toSet()).map((p) => p.emoji), [null]);
  });

  test('a known name between colons is an emoji, and everything else stays text', () {
    expect(cut('plain text'), ['plain text']);
    expect(cut(''), isEmpty);
    expect(cut(':beta:'), [('beta',)]);
    expect(cut('One :alpha: and a :beta:!'), ['One ', ('alpha',), ' and a ', ('beta',), '!']);
    expect(cut(':gamma::gamma:'), [('gamma',), ('gamma',)]);
    // An unknown name, a time, a wrong case, a gap: all read as written.
    expect(cut(':rocket: at 12:30:45, :Beta: and : beta :'), [':rocket: at 12:30:45, :Beta: and : beta :']);
    // An unknown name's closing colon may open a known one.
    expect(cut(':rocket:beta:'), [':rocket', ('beta',)]);
    expect(cut('::alpha:'), [':', ('alpha',)]);
  });

  test('the pieces give the message back', () {
    for (final text in ['a :beta: b', ':x:beta::gamma', ':alpha:\n:beta: :nope:', 'مرحبا :alpha: 你好']) {
      expect(emojiPieces(text, _names).map((p) => p.text).join(), text);
    }
  });

  test('the app\'s names are ones a message can hold', () {
    for (final name in murmurEmoji.keys) {
      expect(emojiPieces(emojiCode(name), {name}).single.emoji, name);
    }
  });

  testWidgets('a message shows its emoji as glyphs, between its words', (tester) async {
    await tester.pumpWidget(_app(const MessageText('First :alpha: then :beta:', emoji: _emoji)));
    expect(_drawn(tester), [Glyph.star, Glyph.coin]);
    expect(find.textContaining(':beta:', findRichText: true), findsNothing);
    expect(find.textContaining('First ', findRichText: true), findsOneWidget);
  });

  testWidgets('a message without any is plain text, as before', (tester) async {
    await tester.pumpWidget(_app(const Column(children: [
      MessageText('at 12:30:45 :rocket:', emoji: _emoji),
      MessageText('selectable', selectable: true, emoji: _emoji),
      // With the app's own emoji: none, so codes stay text.
      MessageText('still :alpha:'),
    ])));
    expect(find.byType(MurmurIcon), findsNothing);
    expect(find.text('at 12:30:45 :rocket:'), findsOneWidget);
    expect(find.text('still :alpha:'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('a long first line with emoji still fits its one row', (tester) async {
    await tester.pumpWidget(_app(SizedBox(
      width: 200,
      child: MessageText(':alpha: ${'word ' * 80}:gamma:', maxLines: 1, emoji: _emoji),
    )));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MessageText)).height, lessThan(40));
  });

  testWidgets('copying a message gives its emoji back as their codes', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(
        _app(const MessageText('One :alpha: and a :beta: today', selectable: true, emoji: _emoji)));
    expect(_drawn(tester), [Glyph.star, Glyph.coin]);
    final region = tester.state<SelectableRegionState>(find.byType(SelectableRegion));
    region.selectAll(SelectionChangedCause.keyboard);
    await tester.pump();
    Actions.invoke(tester.element(find.byType(RichText).first), CopySelectionTextIntent.copy);
    await tester.pump();
    expect(copied, 'One :alpha: and a :beta: today');
  });

  testWidgets('the picker writes an emoji\'s code where the cursor is', (tester) async {
    final message = TextEditingController(text: 'well done');
    addTearDown(message.dispose);
    await tester.pumpWidget(
        _app(Column(children: [TextField(controller: message), EmojiPicker(message, emoji: _emoji)])));

    // Closed until asked for.
    expect(find.byTooltip(':alpha:'), findsNothing);
    await tester.tap(find.text('Murmur emoji'));
    await tester.pump();
    for (final name in _names) {
      expect(find.byTooltip(emojiCode(name)), findsOneWidget);
    }

    // A field never focused has no cursor: at the end.
    await tester.tap(find.byTooltip(':alpha:'));
    expect(message.text, 'well done:alpha:');

    // At the cursor, which then stands after it.
    message.selection = const TextSelection.collapsed(offset: 4);
    await tester.tap(find.byTooltip(':beta:'));
    expect(message.text, 'well:beta: done:alpha:');
    expect(message.selection, const TextSelection.collapsed(offset: 10));

    // Over a selection.
    message.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.tap(find.byTooltip(':gamma:'));
    expect(message.text, ':gamma::beta: done:alpha:');
  });

  testWidgets('with no emoji there is no picker', (tester) async {
    final message = TextEditingController();
    addTearDown(message.dispose);
    await tester.pumpWidget(_app(EmojiPicker(message)));
    expect(find.text('Murmur emoji'), findsNothing);
    expect(tester.getSize(find.byType(EmojiPicker)), Size.zero);
  });
}
