import 'package:flutter_test/flutter_test.dart';
import 'package:nexstream_tv/main.dart';

void main() {
  testWidgets('Nexstream TV smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NexstreamTVApp());
    expect(find.byType(NexstreamTVApp), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
  });
}
