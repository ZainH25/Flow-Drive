import 'package:flutter_test/flutter_test.dart';
import 'package:flow_drive/app.dart';
import 'package:flow_drive/core/services/amplify_service.dart';
import 'package:flow_drive/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService =
        LocalStorageService(await SharedPreferences.getInstance());
    final amplifyService = AmplifyService();

    await tester.pumpWidget(
      FlowDriveApp(
        storageService: storageService,
        amplifyService: amplifyService,
      ),
    );

    await tester.pump();
    expect(find.text('Flow Drive'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
