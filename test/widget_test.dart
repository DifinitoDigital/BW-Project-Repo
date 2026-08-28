import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smart_retail_pay/main.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('SmartRetailPayApp smoke test and UI launch', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartRetailPayApp());
    await tester.pumpAndSettle();

    // Verify app rendered successfully with key widgets
    expect(find.textContaining('Hello'), findsOneWidget);
    expect(find.text('Smart Cart'), findsWidgets);
  });
}
