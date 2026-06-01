import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_app/screens/login_screen.dart';

void main() {
  Widget buildLogin() {
    return const MaterialApp(
      home: LoginScreen(),
    );
  }

  testWidgets('login screen shows sign in form', (tester) async {
    await tester.pumpWidget(buildLogin());

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });

  testWidgets('login form validates required fields', (tester) async {
    await tester.pumpWidget(buildLogin());

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('login screen can switch to registration mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildLogin());

    await tester.tap(find.byType(TextButton).last);
    await tester.pump();

    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Forgot Password?'), findsNothing);
  });
}
