const { verifyToken } = require('../auth/token');
const users = require('../data/userRepository');

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [type, token] = header.split(' ');

  if (type !== 'Bearer' || !token) {
    return res.status(401).json({ message: 'Giriş yapmanız gerekiyor' });
  }

  const payload = verifyToken(token);
  const user = payload ? users.findById(payload.sub) : null;
  if (!user) {
    return res.status(401).json({ message: 'Oturum geçersiz veya süresi dolmuş, tekrar giriş yapın' });
  }

  req.user = user;
  next();
}

function requireRole(role) {
  return (req, res, next) => {
    if (req.user?.role !== role) {
      return res.status(403).json({ message: 'Bu işlem için yetkiniz yok' });
    }
    next();
  };
}

module.exports = { requireAuth, requireRole };