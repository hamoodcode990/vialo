/// Base URL of the Apple Sign-In token relay deployed from
/// tools/apple-revoke-worker/ (see that folder's README to deploy it).
///
/// Apple's own guidance is that exchanging an authorization code and
/// revoking a token must be done server-side, signed with the Sign in with
/// Apple private key — that key must never ship inside the app bundle. This
/// app otherwise has no backend by design (see cloud_profile_sync.dart), so
/// this worker is the one deliberately-added exception, scoped to exactly
/// the two calls account deletion needs.
///
/// Until this is replaced with the deployed worker's real URL,
/// [AppleTokenRelayService] treats itself as unavailable and skips the
/// network calls — account deletion still wipes local + iCloud data, it
/// just can't revoke the Apple token, which is the specific gap App Review
/// flags under guideline 5.1.1(v). Replace this before shipping.
const String appleTokenRelayBaseUrl =
    'https://vialo-apple-revoke.sablastudio.workers.dev';
