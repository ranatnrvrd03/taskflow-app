const { db } = require('./db');

const SELECT = `
  SELECT t.*, u.name AS assignee_name
  FROM tasks t
  LEFT JOIN users u ON u.id = t.assignee_id
`;

function toTask(row) {
  if (!row) {
    return null;
  }
  const task = {
    id: row.id,
    title: row.title,
    description: row.description,
    status: row.status,
    priority: row.priority,
    assigneeId: row.assignee_id ?? null,
    assignee: row.assignee_name ?? '',
    deadline: row.deadline,
    createdAt: row.created_at,
  };
  if (row.updated_at) {
    task.updatedAt = row.updated_at;
  }
  return task;
}

function findAll(assigneeId) {
  if (assigneeId) {
    return db.prepare(`${SELECT} WHERE t.assignee_id = ? ORDER BY t.created_at DESC`).all(assigneeId).map(toTask);
  }
  return db.prepare(`${SELECT} ORDER BY t.created_at DESC`).all().map(toTask);
}

function findById(id) {
  return toTask(db.prepare(`${SELECT} WHERE t.id = ?`).get(id));
}

function insert(task) {
  db.prepare(`
    INSERT INTO tasks (id, title, description, status, priority, assignee_id, deadline, created_by, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    task.id,
    task.title,
    task.description,
    task.status,
    task.priority,
    task.assigneeId,
    task.deadline,
    task.createdBy,
    task.createdAt
  );
  return findById(task.id);
}

function update(id, task) {
  db.prepare(`
    UPDATE tasks
    SET title = ?, description = ?, status = ?, priority = ?, assignee_id = ?, deadline = ?, updated_at = ?
    WHERE id = ?
  `).run(
    task.title,
    task.description,
    task.status,
    task.priority,
    task.assigneeId,
    task.deadline,
    task.updatedAt,
    id
  );
  return findById(id);
}

function remove(id) {
  db.prepare('DELETE FROM tasks WHERE id = ?').run(id);
}

module.exports = { findAll, findById, insert, update, remove };