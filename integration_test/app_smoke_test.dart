import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yuruk/core/di/service_locator.dart';
import 'package:yuruk/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'battery_opt_asked': true});
    await GetIt.instance.reset();
    setupServiceLocator();
  });

  testWidgets('E2E: uygulama açılır ve sekmeler gezinir', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainScreen())),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byKey(const Key('yuruk_main_nav')), findsOneWidget);

    await tester.tap(find.text('Etkinlikler'));
    await tester.pumpAndSettle();
    expect(find.text('Etkinlik Planları'), findsOneWidget);
  });
}
