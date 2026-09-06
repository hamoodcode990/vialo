// Minimal relay so Vialo (a client-only app, no backend by design — see
// app/lib/account/cloud_profile_sync.dart) can complete the two Sign in
// with Apple calls that App Store guideline 5.1.1(v) requires on account
// deletion: exchanging the sign-in authorization code for a refresh token,
// and later revoking that refresh token. Both calls need a client_secret
// JWT signed with Apple's Sign in with Apple private key — Apple's own
// guidance is that key must never ship inside the app bundle, hence this
// worker holds it as a server-side secret instead.
//
// Two endpoints, both POST, both JSON in/out:
//   POST /exchange { code }           -> { refresh_token }
//   POST /revoke   { refresh_token }  -> { revoked: true }
//
// See README.md in this folder for deploy steps.

const TOKEN_URL = 'https://appleid.apple.com/auth/token';
const REVOKE_URL = 'https://appleid.apple.com/auth/revoke';

function base64url(bytes) {
  let str = btoa(String.fromCharCode(...bytes));
  return str.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function importPrivateKey(pem) {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey('pkcs8', der, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
}

// Apple's client_secret is a JWT, ES256-signed with the Sign in with Apple
// private key, minted fresh per request (5 minute expiry is plenty — these
// are one-shot server-to-server calls, not something to cache).
async function clientSecret(env) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'ES256', kid: env.APPLE_KEY_ID };
  const payload = {
    iss: env.APPLE_TEAM_ID,
    iat: now,
    exp: now + 300,
    aud: 'https://appleid.apple.com',
    sub: env.APPLE_CLIENT_ID,
  };
  const enc = (obj) => base64url(new TextEncoder().encode(JSON.stringify(obj)));
  const unsigned = `${enc(header)}.${enc(payload)}`;
  const key = await importPrivateKey(env.APPLE_PRIVATE_KEY);
  const sig = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, new TextEncoder().encode(unsigned));
  return `${unsigned}.${base64url(new Uint8Array(sig))}`;
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { 'content-type': 'application/json' } });
}

async function handleExchange(request, env) {
  const { code } = await request.json();
  if (!code) return json({ error: 'missing code' }, 400);

  const secret = await clientSecret(env);
  const body = new URLSearchParams({
    client_id: env.APPLE_CLIENT_ID,
    client_secret: secret,
    code,
    grant_type: 'authorization_code',
  });
  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body,
  });
  const data = await res.json();
  if (!res.ok) return json({ error: data.error || 'exchange_failed' }, 502);
  return json({ refresh_token: data.refresh_token });
}

async function handleRevoke(request, env) {
  const { refresh_token } = await request.json();
  if (!refresh_token) return json({ error: 'missing refresh_token' }, 400);

  const secret = await clientSecret(env);
  const body = new URLSearchParams({
    client_id: env.APPLE_CLIENT_ID,
    client_secret: secret,
    token: refresh_token,
    token_type_hint: 'refresh_token',
  });
  const res = await fetch(REVOKE_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body,
  });
  if (!res.ok) return json({ error: 'revoke_failed' }, 502);
  return json({ revoked: true });
}

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') return json({ error: 'method not allowed' }, 405);
    const { pathname } = new URL(request.url);
    if (pathname === '/exchange') return handleExchange(request, env);
    if (pathname === '/revoke') return handleRevoke(request, env);
    return json({ error: 'not found' }, 404);
  },
};
