import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuruk/presentation/theme/motion_accessibility.dart';
import 'package:yuruk/presentation/widgets/animated_stat_value.dart';

void main() {
  testWidgets('AnimatedStatValue reduced motion anında güncellenir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AnimatedStatValue(
              label: 'Mesafe',
              value: '1.2 km',
            ),
          ),
        ),
      ),
    );
    expect(find.text('1.2 km'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AnimatedStatValue(
              label: 'Mesafe',
              value: '2.0 km',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('2.0 km'), findsOneWidget);
  });
}
