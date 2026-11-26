
const { db } = require('./db');

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
    assignee: row.assignee,
    deadline: row.deadline,
    createdAt: row.created_at,
  };
  if (row.updated_at) {
    task.updatedAt = row.updated_at;
  }
  return task;
}

function findAll() {
  return db.prepare('SELECT * FROM tasks ORDER BY created_at DESC').all().map(toTask);
}

function findById(id) {
  return toTask(db.prepare('SELECT * FROM tasks WHERE id = ?').get(id));
}

function insert(task) {
  db.prepare(`
    INSERT INTO tasks (id, title, description, status, priority, assignee, deadline, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    task.id,
    task.title,
    task.description,
    task.status,
    task.priority,
    task.assignee,
    task.deadline,
    task.createdAt
  );
  return findById(task.id);
}

function update(id, task) {
  db.prepare(`
    UPDATE tasks
    SET title = ?, description = ?, status = ?, priority = ?, assignee = ?, deadline = ?, updated_at = ?
    WHERE id = ?
  `).run(
    task.title,
    task.description,
    task.status,
    task.priority,
    task.assignee,
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