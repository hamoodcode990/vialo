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
import 'package:vialo/account/apple_refresh_token_store.dart';
import 'package:vialo/account/apple_sign_in_service.dart';
import 'package:vialo/account/apple_token_relay_service.dart';
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

  @override
  Future<bool> deleteProfile(String key) async {
    store.remove(key);
    return true;
  }
}

class _FakeTokenRelay extends AppleTokenRelayService {
  String? nextRefreshToken;
  bool revokeSucceeds = true;
  String? lastExchangedCode;
  String? lastRevokedToken;

  @override
  bool get isConfigured => true;

  @override
  Future<String?> exchangeCodeForRefreshToken(String authorizationCode) async {
    lastExchangedCode = authorizationCode;
    return nextRefreshToken;
  }

  @override
  Future<bool> revokeRefreshToken(String refreshToken) async {
    lastRevokedToken = refreshToken;
    return revokeSucceeds;
  }
}

class _FakeTokenStore extends AppleRefreshTokenStore {
  String? value;
  @override
  Future<void> save(String refreshToken) async => value = refreshToken;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> clear() async => value = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late _FakeAppleSignIn fakeSignIn;
  late _FakeCloudSync fakeCloud;
  late _FakeTokenRelay fakeRelay;
  late _FakeTokenStore fakeTokenStore;
  late AccountController ctrl;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSignIn = _FakeAppleSignIn();
    fakeCloud = _FakeCloudSync();
    fakeRelay = _FakeTokenRelay();
    fakeTokenStore = _FakeTokenStore();
    container = ProviderContainer(overrides: [
      appleSignInServiceProvider.overrideWithValue(fakeSignIn),
      cloudProfileSyncProvider.overrideWithValue(fakeCloud),
      appleTokenRelayServiceProvider.overrideWithValue(fakeRelay),
      appleRefreshTokenStoreProvider.overrideWithValue(fakeTokenStore),
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

  test('signing in with an authorization code exchanges it and stores the refresh token', () async {
    fakeRelay.nextRefreshToken = 'refresh_abc';
    fakeSignIn.toReturn = SignInResult.success('user_111', 'auth_code_xyz');
    await ctrl.signIn();
    expect(fakeRelay.lastExchangedCode, 'auth_code_xyz');
    expect(fakeTokenStore.value, 'refresh_abc');
  });

  test('deleteAccount revokes the stored refresh token, deletes the iCloud copy, and resets progress', () async {
    fakeRelay.nextRefreshToken = 'refresh_abc';
    fakeSignIn.toReturn = SignInResult.success('user_222', 'auth_code_xyz');
    await ctrl.signIn();
    final ctrl2 = container.read(profileControllerProvider.notifier);
    ctrl2.addCoins(50);
    expect(fakeCloud.store.containsKey('vialo_profile_user_222'), isTrue);

    final result = await ctrl.deleteAccount();

    expect(result.tokenRevoked, isTrue);
    expect(fakeRelay.lastRevokedToken, 'refresh_abc');
    expect(fakeTokenStore.value, isNull);
    expect(fakeCloud.store.containsKey('vialo_profile_user_222'), isFalse);
    final p = container.read(profileControllerProvider).value!;
    expect(p.appleUserId, isNull);
    expect(p.coins, 100);
  });

  test('deleteAccount with no linked account still resets local progress without error', () async {
    container.read(profileControllerProvider.notifier).addCoins(50);
    final result = await ctrl.deleteAccount();
    expect(result.tokenRevoked, isFalse);
    final p = container.read(profileControllerProvider).value!;
    expect(p.coins, 100);
  });
}
