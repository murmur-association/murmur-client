{{flutter_js}}
{{flutter_build_config}}

// Nothing is loaded from other origins (AGENTS.md, rule 2). CanvasKit is
// served locally by `flutter build web --no-web-resources-cdn`, and the fonts
// for glyphs Roboto lacks (Arabic, Chinese, Japanese, emoji...) come from
// this site's fallback-fonts/, filled by `dart run tool/fetch_fallback_fonts.dart`
// after the build, instead of fonts.gstatic.com.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: "fallback-fonts/",
  },
});
