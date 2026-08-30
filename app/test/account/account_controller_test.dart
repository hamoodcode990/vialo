// AccountController owns the CLAUDE.md Step 7 sign-in/restore-choice logic
// — the one part of the Sign in with Apple feature that's pure enough to
// unit test without a real device/iCloud (the native bridge and the
// sign_in_with_apple plugin itself can't be exercised here). Fakes stand in
// for both, driven directly, so this locks down: sign-in links the account,
// no-remote-data pushes local straight to iCloud, and differing remote
// progress surfaces a restore choice rather than silently overwriting
// anything.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vialo/account/account_controller.dart';
import 'package:vialo/account/apple_sign_in_service.dart';
import 'package:vialo/account/cloud_profile_sync.dart';
import 'package:vialo/state/profile_provider.dart';

class _FakeAppleSignIn extends AppleSignInService {
  SignInResult toReturn = SignInResult.unavailable();
  @override
  Future<bool> get isAvailable async => true;
  @override
  Future<SignInResult> signIn() async => toReturn;
}

class _FakeCloudSync extends CloudProfileSync {
  final Map<String, String> store = {};
  @override
  Future<String?> getProfile(String key) async => store[key];
  @override
  Future<bool> setProfile(String key, String json) async {
    store[key] = json;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late _FakeAppleSignIn fakeSignIn;
  late _FakeCloudSync fakeCloud;
  late AccountController ctrl;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSignIn = _FakeAppleSignIn();
    fakeCloud = _FakeCloudSync();
    container = ProviderContainer(overrides: [
      appleSignInServiceProvider.overrideWithValue(fakeSignIn),
      cloudProfileSyncProvider.overrideWithValue(fakeCloud),
    ]);
    await container.read(profileControllerProvider.future); // wait for the initial load
    ctrl = container.read(accountControllerProvider);
  });

  tearDown(() => container.dispose());

  test('a cancelled Apple sign-in leaves the profile unlinked', () async {
    fakeSignIn.toReturn = SignInResult.cancelled();
    final outcome = await ctrl.signIn();
    expect(outcome, isA<LinkFailed>());
    expect(container.read(profileControllerProvider).value!.appleUserId, isNull);
  });

  test('sign-in with no existing remote data links and pushes local progress up', () async {
    fakeSignIn.toReturn = SignInResult.success('user_123');
    final outcome = await ctrl.signIn();
    expect(outcome, isA<LinkSynced>());
    expect(container.read(profileControllerProvider).value!.appleUserId, 'user_123');
    expect(fakeCloud.store.containsKey('vialo_profile_user_123'), isTrue);
  });

  test('sign-in with differing remote progress asks for a restore choice instead of overwriting', () async {
    // Seed the cloud with a profile that has different progress before signing in.
    fakeCloud.store['vialo_profile_user_456'] = '{"coins": 999, "name": "OtherDevice"}';
    fakeSignIn.toReturn = SignInResult.success('user_456');

    final outcome = await ctrl.signIn();

    expect(outcome, isA<LinkNeedsRestoreChoice>());
    // Still linked (so the UI can act on it), but local progress untouched.
    expect(container.read(profileControllerProvider).value!.appleUserId, 'user_456');
    expect(container.read(profileControllerProvider).value!.coins, 100); // fresh-install default, not 999
  });

  test('restoreFromCloud replaces local progress only when explicitly called', () {
    ctrl.restoreFromCloud(
      container.read(profileControllerProvider).value!.clone()..coins = 42,
    );
    expect(container.read(profileControllerProvider).value!.coins, 42);
  });

  test('signOut clears the linked account without touching progress', () async {
    fakeSignIn.toReturn = SignInResult.success('user_789');
    await ctrl.signIn();
    ctrl.signOut();
    final p = container.read(profileControllerProvider).value!;
    expect(p.appleUserId, isNull);
    expect(p.coins, 100);
  });
}
