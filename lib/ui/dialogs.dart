// What every dialog in the app shares: Enter presses its copper button.
// (Dialogs also scroll when the on-screen keyboard takes their room: each
// AlertDialog is `scrollable`, see ui_test.dart.)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a dialog, as [showDialog] does, in which Enter confirms: it presses
/// the dialog's copper button (its [FilledButton]), as a tap would.
/// - While a text of several lines is being written, Enter is a new line
///   and Ctrl+Enter (Cmd+Enter on Apple) confirms.
/// - A red button (a destructive action) is never pressed by a key: those
///   are confirmed by hand.
/// - With the keyboard's focus on another button, Enter presses that one, as
///   everywhere.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) =>
    showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ConfirmOnEnter(child: Builder(builder: builder)),
    );

/// A text field's controller that lives as long as the dialog holding it:
/// disposed when the dialog's route is gone, not when [showAppDialog]
/// returns, since the closing animation still builds the field (a
/// controller disposed then failed the acceptance tests).
class WithTextController extends StatefulWidget {
  const WithTextController({super.key, this.text = '', required this.builder});

  /// What the field starts with.
  final String text;

  final Widget Function(BuildContext context, TextEditingController controller) builder;

  @override
  State<WithTextController> createState() => _WithTextControllerState();
}

class _WithTextControllerState extends State<WithTextController> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// Presses the [FilledButton] below it when Enter is pressed, while its
/// route is the one on top. See [showAppDialog].
class ConfirmOnEnter extends StatefulWidget {
  const ConfirmOnEnter({super.key, required this.child});

  final Widget child;

  @override
  State<ConfirmOnEnter> createState() => _ConfirmOnEnterState();
}

class _ConfirmOnEnterState extends State<ConfirmOnEnter> {
  @override
  void initState() {
    super.initState();
    // Heard whatever has the focus: a dialog without a text field has none
    // of its own.
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  /// The copper button to press, if there is one and it's enabled.
  VoidCallback? _confirm() {
    final error = Theme.of(context).colorScheme.error;
    VoidCallback? found;
    void visit(Element element) {
      final widget = element.widget;
      if (widget is FilledButton) {
        final background = widget.style?.backgroundColor?.resolve(const {});
        if (background != error) found = widget.onPressed ?? found;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.enter && event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return false;
    }
    // Only the dialog on top answers (a dialog may open another).
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return false;
    final focused = primaryFocus?.context;
    // A focused button takes its own Enter.
    if (focused != null && focused.findAncestorWidgetOfExactType<FilledButton>() == null) {
      var onButton = false;
      focused.visitAncestorElements((e) {
        onButton = e.widget is ButtonStyleButton || e.widget is IconButton;
        return !onButton && e.widget is! ConfirmOnEnter;
      });
      if (onButton) return false;
    }
    // In a text of several lines Enter is a new line.
    final field = focused?.findAncestorWidgetOfExactType<EditableText>();
    final keys = HardwareKeyboard.instance;
    if (field != null && field.keyboardType == TextInputType.multiline && !keys.isControlPressed && !keys.isMetaPressed) {
      return false;
    }
    final confirm = _confirm();
    if (confirm == null) return false;
    confirm();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
