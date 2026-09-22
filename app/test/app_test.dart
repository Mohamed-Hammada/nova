import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_app/app.dart';

void main() {
  testWidgets('NovaApp renders its root scaffold', (tester) async {
    await tester.pumpWidget(const NovaApp());
    expect(find.text('Nova'), findsOneWidget);
  });
}
