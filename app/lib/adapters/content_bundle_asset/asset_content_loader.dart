import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:nova_app/core/content/content_runtime.dart';
import 'package:nova_app/core/content/models.dart';

/// Loads the pre-compiled, pre-validated content bundle from the app's own
/// asset bundle -- never from the network, never by parsing YAML (design
/// doc section 13).
Future<ContentRuntime> loadContentRuntimeFromAssets() async {
  final raw = await rootBundle.loadString('assets/content/content_bundle.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return ContentRuntime(ContentBundle.fromJson(json));
}
