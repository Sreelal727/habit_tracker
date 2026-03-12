import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/app.dart';

void main() {
  testWidgets('App renders with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: HabitTrackerApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Tracker'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
  });
}
