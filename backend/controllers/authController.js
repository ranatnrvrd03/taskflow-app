const users = require('../data/userRepository');
const { verifyPassword } = require('../auth/password');
const { createToken } = require('../auth/token');

function login(req, res) {
  const { username, password } = req.body || {};

  if (typeof username !== 'string' || typeof password !== 'string' || !username.trim() || !password) {
    return res.status(400).json({ message: 'Kullanıcı adı ve şifre zorunludur' });
  }

  const row = users.findByUsernameWithPassword(username.trim().toLowerCase());
  if (!row || !verifyPassword(password, row.password_hash)) {
    return res.status(401).json({ message: 'Kullanıcı adı veya şifre hatalı' });
  }

  const user = users.findById(row.id);
  res.status(200).json({ message: 'Giriş başarılı', token: createToken(user), user });
}

function me(req, res) {
  res.status(200).json({ user: req.user });
}

module.exports = { login, me };