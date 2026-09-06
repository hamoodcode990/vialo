# Apple Sign-In token relay

Vialo has no backend by design (see `app/lib/account/cloud_profile_sync.dart`).
This is the one deliberate exception: App Store guideline 5.1.1(v) requires
account deletion to actually revoke the Sign in with Apple credential, and
that call has to be signed with Apple's private key server-side — the key
must never ship inside the app bundle. This Cloudflare Worker is the
smallest thing that can hold that key and make the two required calls.

## What it does

- `POST /exchange { code }` — exchanges the one-time authorization code from
  sign-in for a refresh token. Called once, right after a successful sign-in
  (`AccountController.signIn`), while the code is still valid (minutes).
- `POST /revoke { refresh_token }` — revokes that refresh token. Called once,
  on account deletion (`AccountController.deleteAccount`).

Both calls mint a fresh `client_secret` JWT (ES256, signed with the Sign in
with Apple private key) per request using the Web Crypto API — no JWT
library dependency.

## Deploy

1. In the Apple Developer portal, under **Certificates, Identifiers &
   Profiles → Keys**, create (or reuse) a **Sign in with Apple** key. Note
   its **Key ID**, and download the `.p8` file (Apple only lets you download
   it once).
2. Note your **Team ID** (top right of the developer portal) and the
   **Client ID** — for a native iOS app, this is the app's bundle id
   (`com.sablastudio.vialo`).
3. Install [wrangler](https://developers.cloudflare.com/workers/wrangler/)
   and log in: `npx wrangler login`.
4. From this folder, set the secrets:
   ```
   npx wrangler secret put APPLE_TEAM_ID
   npx wrangler secret put APPLE_KEY_ID
   npx wrangler secret put APPLE_CLIENT_ID
   npx wrangler secret put APPLE_PRIVATE_KEY   # paste the full .p8 file contents
   ```
5. Deploy: `npx wrangler deploy`
6. Copy the resulting `https://vialo-apple-revoke.<subdomain>.workers.dev`
   URL into `app/lib/account/apple_token_relay_config.dart`
   (`appleTokenRelayBaseUrl`), replacing the `REPLACE-ME` placeholder.

Until step 6 is done, `AppleTokenRelayService` treats itself as
unconfigured and skips these calls — sign-in and account deletion both
still work, but the Apple token itself won't be revoked, which is the
specific gap App Review flagged.

## Rotating or revoking access

If the `.p8` key is ever compromised, revoke it in the Apple Developer
portal and repeat step 1 with a new key — this worker has no other secret
that grants access to anything beyond generating that one JWT.
