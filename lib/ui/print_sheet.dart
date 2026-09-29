// Printing invitation cards: in a browser, a plain HTML page (made here,
// opened from a local blob URL, nothing fetched) with the browser's print
// dialog; natively there's no printing, and the cards page offers copying
// the links instead.

import 'print_sheet_io.dart' if (dart.library.js_interop) 'print_sheet_web.dart' as impl;

/// Whether this build can print (the web).
const canPrint = impl.canPrint;

/// Opens `html` (a whole document) in a new tab and asks the browser to
/// print it.
void printHtml(String html) => impl.printHtml(html);
