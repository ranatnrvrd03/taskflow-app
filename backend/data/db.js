const fs = require('fs');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');

const dbFilePath = process.env.DB_FILE || path.join(__dirname, 'taskflow.db');
const seedFilePath = path.join(__dirname, 'tasks.json');

fs.mkdirSync(path.dirname(dbFilePath), { recursive: true });
const db = new DatabaseSync(dbFilePath);

db.exec(`
  CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'done')),
    priority INTEGER NOT NULL DEFAULT 2 CHECK (priority IN (1, 2, 3)),
    assignee TEXT NOT NULL DEFAULT '',
    deadline TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT
  )
`);

function seedTasks() {
  const { count } = db.prepare('SELECT COUNT(*) AS count FROM tasks').get();
  if (count > 0) {
    return;
  }

  const sources = [process.env.DATA_FILE, seedFilePath].filter(Boolean);
  const source = sources.find((file) => fs.existsSync(file));
  if (!source) {
    return;
  }

  const tasks = JSON.parse(fs.readFileSync(source, 'utf8') || '[]');
  const insert = db.prepare(`
    INSERT INTO tasks (id, title, description, status, priority, assignee, deadline, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  db.exec('BEGIN');
  for (const t of tasks) {
    insert.run(
      t.id,
      t.title,
      t.description ?? '',
      t.status ?? 'pending',
      t.priority ?? 2,
      t.assignee ?? '',
      t.deadline ?? null,
      t.createdAt ?? new Date().toISOString(),
      t.updatedAt ?? null
    );
  }
  db.exec('COMMIT');
  console.log(`${tasks.length} görev veritabanına aktarıldı (${source})`);
}

seedTasks();

module.exports = { db, dbFilePath };