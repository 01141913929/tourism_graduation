import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:egyptian_tourism_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EgyptianTourismApp());

    // Verify the app has loaded
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
