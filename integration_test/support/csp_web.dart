// In a browser: what the page's Content-Security-Policy refused. The runner
// serves the page with app.murmur.info's own headers (web/_headers), whose
// policy lets the page reach only its own origin and its node, so anything
// refused is something rule 2 forbids: a font, a script or a request going
// to a third party. The browser reports each in a `securitypolicyviolation`
// event. (What the page asks before the first test's app starts, as it
// loads, isn't seen here; the browser's console still shows it.)

import 'dart:js_interop';

import 'package:web/web.dart' as web;

final _refused = <String>[];
var _watching = false;

/// Starts recording what the policy refuses, once for the page.
void watchPolicyViolations() {
  if (_watching) return;
  _watching = true;
  web.document.addEventListener(
      'securitypolicyviolation',
      ((web.SecurityPolicyViolationEvent e) {
        _refused.add('${e.effectiveDirective} refused ${e.blockedURI}');
      }).toJS);
}

/// What the policy refused since [watchPolicyViolations], oldest first.
List<String> policyViolations() => List.of(_refused);
