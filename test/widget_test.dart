import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

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

    Get.put(storageService, permanent: true);
    Get.put(amplifyService, permanent: true);

    await tester.pumpWidget(const FlowDriveApp());
    await tester.pump();

    expect(find.text('FlowDrive'), findsOneWidget);
  });
}
