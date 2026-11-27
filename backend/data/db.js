const fs = require('fs');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');
const { ulid } = require('ulid');
const { hashPassword } = require('../auth/password');

const dbFilePath = process.env.DB_FILE || path.join(__dirname, 'taskflow.db');
const seedFilePath = path.join(__dirname, 'tasks.json');

const DEMO_USERS = [
  { username: 'rana', name: 'Rana Tanrıverdi', role: 'ceo', password: 'Ceo.2026' },
  { username: 'ayse', name: 'Ayşe Yılmaz', role: 'employee', password: 'Calisan.2026' },
  { username: 'mehmet', name: 'Mehmet Demir', role: 'employee', password: 'Calisan.2026' },
  { username: 'zeynep', name: 'Zeynep Kaya', role: 'employee', password: 'Calisan.2026' },
];

fs.mkdirSync(path.dirname(dbFilePath), { recursive: true });
const db = new DatabaseSync(dbFilePath);
db.exec('PRAGMA foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('ceo', 'employee')),
    password_hash TEXT NOT NULL,
    created_at TEXT NOT NULL
  )
`);

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

function addColumnIfMissing(table, column, definition) {
  const columns = db.prepare(`PRAGMA table_info(${table})`).all().map((c) => c.name);
  if (!columns.includes(column)) {
    db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
  }
}

addColumnIfMissing('tasks', 'assignee_id', 'TEXT REFERENCES users(id) ON DELETE SET NULL');
addColumnIfMissing('tasks', 'created_by', 'TEXT REFERENCES users(id) ON DELETE SET NULL');

function seedUsers() {
  const { count } = db.prepare('SELECT COUNT(*) AS count FROM users').get();
  if (count > 0) {
    return;
  }
  const insert = db.prepare(`
    INSERT INTO users (id, username, name, role, password_hash, created_at)
    VALUES (?, ?, ?, ?, ?, ?)
  `);
  for (const u of DEMO_USERS) {
    insert.run(ulid(), u.username, u.name, u.role, hashPassword(u.password), new Date().toISOString());
  }
  console.log(`${DEMO_USERS.length} kullanıcı oluşturuldu (1 CEO, ${DEMO_USERS.length - 1} çalışan)`);
}

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

function linkAssigneesByName() {
  db.exec(`
    UPDATE tasks
    SET assignee_id = (SELECT id FROM users WHERE users.name = tasks.assignee)
    WHERE assignee_id IS NULL AND assignee <> ''
  `);
}

seedUsers();
seedTasks();
linkAssigneesByName();

module.exports = { db, dbFilePath };