{{flutter_js}}
{{flutter_build_config}}

// Nova runs without any third-party request. Every font it uses is bundled
// (pubspec.yaml), and CanvasKit is served locally (--no-web-resources-cdn).
// The engine's glyph-fallback font source defaults to Google's font CDN; it
// is pointed at this app's own origin instead, so even an unexpected missing
// glyph can never reach Google's servers.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: 'assets/font-fallback/',
  },
});
