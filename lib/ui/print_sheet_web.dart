import 'dart:js_interop';

import 'package:web/web.dart' as web;

const canPrint = true;

void printHtml(String html) {
  final blob = web.Blob([html.toJS].toJS, web.BlobPropertyBag(type: 'text/html'));
  web.window.open(web.URL.createObjectURL(blob), '_blank');
}
