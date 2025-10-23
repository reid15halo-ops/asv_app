import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asv_app/features/auth/sign_in_screen.dart';

void main() {
  testWidgets('SignInScreen shows fields and validators', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SignInScreen()));

    // find widgets
    final emailField = find.byType(TextFormField).first;
    final pwField = find.byType(TextFormField).at(1);
    final signInBtn = find.widgetWithText(ElevatedButton, 'Anmelden');
    final signUpBtn = find.widgetWithText(OutlinedButton, 'Registrieren');

    expect(emailField, findsOneWidget);
    expect(pwField, findsOneWidget);
    expect(signInBtn, findsOneWidget);
    expect(signUpBtn, findsOneWidget);

    // Submit empty form -> validation errors
    await tester.tap(signInBtn);
    await tester.pumpAndSettle();

    expect(find.text('E-Mail darf nicht leer sein.'), findsOneWidget);
    expect(find.text('Passwort darf nicht leer sein.'), findsOneWidget);

    // Enter invalid email and short password
    await tester.enterText(emailField, 'invalid-email');
    await tester.enterText(pwField, '123');
    await tester.tap(signInBtn);
    await tester.pumpAndSettle();

    expect(find.text('Bitte gültige E-Mail eingeben.'), findsOneWidget);
    expect(find.text('Passwort muss mindestens 6 Zeichen lang sein.'), findsOneWidget);
  });

  testWidgets('SignInScreen respects initial busy and disables buttons', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SignInScreen(initialBusy: true)));
    await tester.pumpAndSettle();

    final signInBtn = find.widgetWithText(ElevatedButton, 'Anmelden');
    final signUpBtn = find.widgetWithText(OutlinedButton, 'Registrieren');

    final ElevatedButton elevated = tester.widget(signInBtn);
    final OutlinedButton outlined = tester.widget(signUpBtn);

    expect(elevated.onPressed, isNull);
    expect(outlined.onPressed, isNull);
  });
}
