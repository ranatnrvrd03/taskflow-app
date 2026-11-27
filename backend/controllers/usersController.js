const users = require('../data/userRepository');

function listUsers(req, res) {
  const today = new Date().toISOString().slice(0, 10);
  const list = users.findAllWithStats(today);
  res.status(200).json({ count: list.length, users: list });
}

module.exports = { listUsers };