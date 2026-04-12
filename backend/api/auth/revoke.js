// POST /api/auth/revoke
// Revokes a GitHub OAuth access token on logout.

export default async function handler(req, res) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { token } = req.body ?? {};
  if (!token) {
    return res.status(400).json({ error: 'Missing token' });
  }

  const clientId = process.env.GITHUB_CLIENT_ID;
  const clientSecret = process.env.GITHUB_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    return res.status(500).json({ error: 'Server misconfigured' });
  }

  try {
    const response = await fetch(
      `https://api.github.com/applications/${clientId}/token`,
      {
        method: 'DELETE',
        headers: {
          Accept: 'application/vnd.github+json',
          Authorization:
            'Basic ' +
            Buffer.from(`${clientId}:${clientSecret}`).toString('base64'),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ access_token: token }),
      }
    );

    // 204 = success, token revoked
    if (response.status === 204 || response.status === 200) {
      return res.status(200).json({ success: true });
    }

    return res.status(response.status).json({
      error: 'Revocation failed',
      status: response.status,
    });
  } catch (err) {
    return res.status(500).json({ error: 'Revocation request failed' });
  }
}
