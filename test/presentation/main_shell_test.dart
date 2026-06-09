import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yuruk/core/di/service_locator.dart';
import 'package:yuruk/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'battery_opt_asked': true});
    await GetIt.instance.reset();
    setupServiceLocator();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('NavigationBar dört sekme gösterir', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainScreen())),
    );
    await tester.pump();

    expect(find.byKey(const Key('yuruk_main_nav')), findsOneWidget);
    expect(find.text('Koş'), findsWidgets);
    expect(find.text('Etkinlikler'), findsWidgets);
    expect(find.text('Geçmiş'), findsWidgets);
    expect(find.text('Lab'), findsWidgets);
  });
}
