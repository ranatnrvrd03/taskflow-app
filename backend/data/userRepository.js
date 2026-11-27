const { db } = require('./db');

function toUser(row) {
  if (!row) {
    return null;
  }
  return { id: row.id, username: row.username, name: row.name, role: row.role };
}

function findById(id) {
  return toUser(db.prepare('SELECT * FROM users WHERE id = ?').get(id));
}

function findByUsernameWithPassword(username) {
  return db.prepare('SELECT * FROM users WHERE username = ?').get(username) ?? null;
}

function findAllWithStats(today) {
  return db.prepare(`
    SELECT
      u.id, u.username, u.name, u.role,
      COUNT(t.id) AS total,
      SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) AS done,
      SUM(CASE WHEN t.status <> 'done' THEN 1 ELSE 0 END) AS open,
      SUM(CASE WHEN t.status <> 'done' AND t.deadline IS NOT NULL AND t.deadline < ? THEN 1 ELSE 0 END) AS overdue
    FROM users u
    LEFT JOIN tasks t ON t.assignee_id = u.id
    GROUP BY u.id
    ORDER BY u.role DESC, u.name
  `).all(today).map((row) => ({
    ...toUser(row),
    stats: {
      total: row.total ?? 0,
      open: row.open ?? 0,
      done: row.done ?? 0,
      overdue: row.overdue ?? 0,
    },
  }));
}

module.exports = { findById, findByUsernameWithPassword, findAllWithStats };