import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_notes_manager/main.dart';

void main() {
  testWidgets('App launches and shows welcome message', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TaskNotesManagerApp());

    // Wait for the app to fully load
    await tester.pumpAndSettle();

    // Verify that the welcome message is displayed
    expect(find.text('Welcome to My Tasks & Notes 👋'), findsOneWidget);

    // Verify that the floating action button is present
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verify that the theme toggle is present
    expect(find.text('Light Theme Enabled'), findsOneWidget);
  });

  testWidgets('Theme toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskNotesManagerApp());
    await tester.pumpAndSettle();

    // Initially should show light theme
    expect(find.text('Light Theme Enabled'), findsOneWidget);

    // Tap the theme switch
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Should now show dark theme
    expect(find.text('Dark Theme Enabled'), findsOneWidget);
  });
}