const fs = require('fs');
const path = require('path');

const seedFilePath = path.join(__dirname, 'tasks.json');
const dataFilePath = process.env.DATA_FILE || seedFilePath;

function ensureDataFile() {
  if (dataFilePath === seedFilePath || fs.existsSync(dataFilePath)) {
    return;
  }
  fs.mkdirSync(path.dirname(dataFilePath), { recursive: true });
  if (fs.existsSync(seedFilePath)) {
    fs.copyFileSync(seedFilePath, dataFilePath);
  } else {
    fs.writeFileSync(dataFilePath, '[]', 'utf8');
  }
  console.log(`Veri dosyası oluşturuldu: ${dataFilePath}`);
}

function readTasks() {
  ensureDataFile();
  if (!fs.existsSync(dataFilePath)) {
    return [];
  }

  const data = fs.readFileSync(dataFilePath, 'utf8');
  if (data.trim() === '') {
    return [];
  }

  return JSON.parse(data);
}

function writeTasks(tasks) {
  ensureDataFile();
  fs.writeFileSync(dataFilePath, JSON.stringify(tasks, null, 2), 'utf8');
}

module.exports = { readTasks, writeTasks, dataFilePath };