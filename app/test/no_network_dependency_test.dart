import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

// Packages that would let the app reach a network. None may appear as a
// direct dependency -- this is the design doc's server-independence
// constraint (section 22), checked automatically rather than only by
// review, and CloudSyncPort (Task 10) stays unimplemented and unwired to
// keep this list empty.
const _forbiddenNetworkPackages = {
  'http', 'dio', 'cronet_http', 'cupertino_http', 'web_socket_channel',
  'graphql', 'graphql_flutter', 'firebase_core', 'cloud_firestore', 'supabase_flutter',
};

void main() {
  test('no direct dependency in pubspec.yaml can reach the network', () {
    final doc = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final dependencies = (doc['dependencies'] as YamlMap).keys.map((k) => k.toString()).toSet();
    final offenders = dependencies.intersection(_forbiddenNetworkPackages);
    expect(offenders, isEmpty, reason: 'This plan ships zero networking dependencies; found: $offenders');
  });
}
