// What every dialog shares (lib/ui/dialogs.dart): Enter presses the copper
// button, and a dialog scrolls instead of overflowing when the on-screen
// keyboard takes its room.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murmur_client/services/node_client.dart';
import 'package:murmur_client/services/storage.dart';
import 'package:murmur_client/ui/brand.dart';
import 'package:murmur_client/ui/common.dart';
import 'package:murmur_client/ui/unlock.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A page with one button that opens `dialog` and keeps what it returns.
class _Opener extends StatefulWidget {
  const _Opener(this.dialog);

  final Widget Function(BuildContext context) dialog;

  @override
  State<_Opener> createState() => _OpenerState();
}

class _OpenerState extends State<_Opener> {
  Object? result = 'nothing yet';

  @override
  Widget build(BuildContext context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            final r = await showAppDialog<Object>(context: context, builder: widget.dialog);
            setState(() => result = r);
          },
          child: const Text('open'),
        ),
      );
}

Future<_OpenerState> _open(WidgetTester tester, Widget Function(BuildContext context) dialog) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(MaterialApp(home: _Opener(dialog)));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return tester.state<_OpenerState>(find.byType(_Opener));
}

Widget _dialog(BuildContext context, {Widget? content, ButtonStyle? style, VoidCallback? onConfirm = _unset}) =>
    AlertDialog(
      scrollable: true,
      content: content ?? const Text('sure?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, 'cancelled'), child: const Text('Cancel')),
        FilledButton(
          style: style,
          onPressed: identical(onConfirm, _unset) ? () => Navigator.pop(context, 'confirmed') : onConfirm,
          child: const Text('Confirm'),
        ),
      ],
    );

void _unset() {}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Enter presses the copper button, with or without a text field', (tester) async {
    var page = await _open(tester, _dialog);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(page.result, 'confirmed');

    page = await _open(tester, (c) => _dialog(c, content: const TextField(autofocus: true)));
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
    await tester.pumpAndSettle();
    expect(page.result, 'confirmed');
  });

  testWidgets('in a text of several lines Enter is a new line, and Ctrl+Enter confirms', (tester) async {
    final page = await _open(tester, (c) => _dialog(c, content: const TextField(autofocus: true, maxLines: 4)));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(page.result, 'nothing yet');
    expect(find.text('Confirm'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(page.result, 'confirmed');
  });

  testWidgets('Enter never presses a red button, nor a disabled one', (tester) async {
    late BuildContext app;
    var page = await _open(tester, (c) {
      app = c;
      return _dialog(c, style: FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error));
    });
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(page.result, 'nothing yet', reason: 'a destructive action is confirmed by hand');
    Navigator.pop(app, 'closed');
    await tester.pumpAndSettle();

    page = await _open(tester, (c) => _dialog(c, onConfirm: null));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(page.result, 'nothing yet');
  });

  testWidgets('with the focus on another button, Enter presses that one', (tester) async {
    final page = await _open(tester, _dialog);
    // Tab moves the focus to the first button, Cancel.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(page.result, 'cancelled');
  });

  testWidgets('only the dialog on top answers', (tester) async {
    final page = await _open(
      tester,
      (c) => _dialog(c, onConfirm: () async {
        // The first dialog's button opens a second one.
        final inner = await showAppDialog<Object>(context: c, builder: _dialog);
        if (c.mounted) Navigator.pop(c, 'outer after $inner');
      }),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Confirm'), findsNWidgets(2));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(page.result, 'outer after confirmed', reason: 'one Enter, one dialog');
  });

  testWidgets("the app's own dialogs: Enter confirms a question, and the passphrase form checks first",
      (tester) async {
    late BuildContext app;
    await tester.pumpWidget(AppScope(
      client: MurmurClient(),
      wallets: WalletController(),
      prefs: Preferences(),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (c) {
          app = c;
          return const Scaffold();
        }),
      ),
    ));
    final sure = confirmAction(app, title: 't', body: 'b', action: 'go');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(await sure, isTrue);

    // A destructive one waits for a tap.
    final remove = confirmAction(app, title: 't', body: 'b', action: 'remove', destructive: true);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('remove'), findsOneWidget);
    await tester.tap(find.text('remove'));
    await tester.pumpAndSettle();
    expect(await remove, isTrue);

    // Enter on an empty new passphrase shows the form's errors and stays.
    final l = app.l10n;
    final passphrase = DialogPrompts(app).newPassphrase();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(l.passphraseNewTitle), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'correct horse battery');
    await tester.enterText(find.byType(TextFormField).last, 'correct horse battery');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(await passphrase, 'correct horse battery');
  });

  testWidgets('a dialog scrolls when the on-screen keyboard takes its room, instead of overflowing',
      (tester) async {
    // A phone, with the keyboard up over more than half of it.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 340);
    addTearDown(tester.view.reset);
    late BuildContext app;
    await tester.pumpWidget(AppScope(
      client: MurmurClient(),
      wallets: WalletController(),
      prefs: Preferences(),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (c) {
          app = c;
          return const Scaffold();
        }),
      ),
    ));
    // The tallest of the text dialogs: a new passphrase, two fields and text.
    DialogPrompts(app).newPassphrase();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'no overflow');
    final l = app.l10n;
    // Its last field can be brought into view by scrolling.
    await tester.ensureVisible(find.widgetWithText(TextFormField, l.passphraseRepeat));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.widgetWithText(TextFormField, l.passphraseRepeat)).bottom, lessThanOrEqualTo(300));
  });
}
