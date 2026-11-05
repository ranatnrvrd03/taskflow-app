const fs = require('fs');
const path = require('path');
const dataFilePath = path.join(__dirname, 'tasks.json');

// tasks.json dosyasını okuyup içeriğini bir diziye çevirir
function readTasks() {
  // Dosya hiç yoksa (ilk çalıştırma) boş liste ile başla
  if (!fs.existsSync(dataFilePath)) {
    return [];
  }

  const data = fs.readFileSync(dataFilePath, 'utf8');

  // Dosya var ama içi tamamen boşsa yine boş liste kabul et
  if (data.trim() === '') {
    return [];
  }

  // JSON bozuksa hata fırlatılır; bu hata errorHandler'a gider ve 500 döner.
  // Böylece bozuk dosya sessizce boş liste gibi davranıp verilerin üstüne yazılmaz.
  return JSON.parse(data);
}

// Verilen görev dizisini tasks.json dosyasına yazar
// Hata olursa fırlatılır; istemciye "başarılı" denip veri kaybolmaz.
function writeTasks(tasks) {
  fs.writeFileSync(dataFilePath, JSON.stringify(tasks, null, 2), 'utf8');
}

module.exports = { readTasks, writeTasks };
