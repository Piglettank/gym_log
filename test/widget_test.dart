import 'package:flutter_test/flutter_test.dart';

import 'package:gym_log/main.dart';

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const GymLogApp());
  });
}
