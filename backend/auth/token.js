const crypto = require('crypto');

const SECRET = process.env.JWT_SECRET || 'taskflow-gelistirme-anahtari';
const EXPIRES_IN_SECONDS = 60 * 60 * 24 * 7;

if (!process.env.JWT_SECRET) {
  console.warn('Uyarı: JWT_SECRET tanımlı değil, geliştirme anahtarı kullanılıyor.');
}

function base64url(input) {
  return Buffer.from(input).toString('base64url');
}

function sign(data) {
  return crypto.createHmac('sha256', SECRET).update(data).digest('base64url');
}

function createToken(user) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const payload = base64url(JSON.stringify({ sub: user.id, role: user.role, iat: now, exp: now + EXPIRES_IN_SECONDS }));
  return `${header}.${payload}.${sign(`${header}.${payload}`)}`;
}

function verifyToken(token) {
  const parts = String(token).split('.');
  if (parts.length !== 3) {
    return null;
  }
  const [header, payload, signature] = parts;
  const expected = Buffer.from(sign(`${header}.${payload}`));
  const actual = Buffer.from(signature);
  if (expected.length !== actual.length || !crypto.timingSafeEqual(expected, actual)) {
    return null;
  }
  try {
    const data = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    if (!data.exp || data.exp < Math.floor(Date.now() / 1000)) {
      return null;
    }
    return data;
  } catch {
    return null;
  }
}

module.exports = { createToken, verifyToken };