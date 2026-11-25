import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:anuvach_mobile/device_review.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android public API observation has an actual result and timestamp',
    (tester) async {
      final device = PlatformDeviceReview();
      expect(device.available, true);
      final observation = await device.checkSecureLock();
      expect(observation['check'], 'secure_screen_lock');
      expect(observation['value'], isA<bool>());
      expect(observation['platform'], 'android');
      expect(observation['source'], 'client_public_api');
      expect(DateTime.parse(observation['checkedAt']).isUtc, true);
    },
  );
}
