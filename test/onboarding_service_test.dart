import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/services/onboarding_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shouldShow returns true when key is absent', () async {
    expect(await OnboardingService.shouldShow(), isTrue);
  });

  test('shouldShow returns false after markDone', () async {
    await OnboardingService.markDone();
    expect(await OnboardingService.shouldShow(), isFalse);
  });

  test('markDone is idempotent', () async {
    await OnboardingService.markDone();
    await OnboardingService.markDone();
    expect(await OnboardingService.shouldShow(), isFalse);
  });
}
