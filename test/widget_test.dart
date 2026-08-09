import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:momflex/main.dart';
import 'package:momflex/supabase/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: '.env');
    await SupabaseService.initialize();
  });

  testWidgets('App boots into the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('MomFlex'), findsOneWidget);

    // Let the splash screen's navigation timer fire so it doesn't leak
    // into the next test.
    await tester.pump(const Duration(seconds: 3));
  });
}
