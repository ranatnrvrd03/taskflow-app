const express = require('express');
const os = require('os');
const app = express();
const tasksRouter = require('./routes/tasks');
const logger = require('./middleware/logger');
const { notFound, errorHandler } = require('./middleware/errorHandler');
const port = 7777;

// Logger middleware'i uygulamaya ekle
app.use(logger);

// Gelen isteklerdeki JSON gövdesini okunabilir hale getiren middleware
app.use(express.json());

// Sunucunun ayakta olduğunu test etmek için basit bir ana sayfa route'u
// Mobil uygulama bağlantı testinde de bu adresi kullanır
app.get('/', (req, res) => {
  res.status(200).json({ message: 'TaskFlow API çalışıyor' });
});

// /tasks ile başlayan tüm istekleri tasksRouter'a yönlendir
app.use('/tasks', tasksRouter);

// Hiçbir route'a uymayan istekler için 404 (route'lardan SONRA gelmeli)
app.use(notFound);

// Tüm hataları JSON olarak döndüren hata yakalayıcı (en sonda olmalı)
app.use(errorHandler);

// Bilgisayarın yerel ağdaki IPv4 adreslerini bulur (telefonun bağlanacağı adres)
function getLocalIPs() {
  const addresses = [];
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const info of interfaces[name]) {
      if (info.family === 'IPv4' && !info.internal) {
        addresses.push({ name, address: info.address });
      }
    }
  }
  return addresses;
}

// '0.0.0.0': sadece bu bilgisayardan değil, aynı ağdaki telefondan gelen istekleri de kabul et
app.listen(port, '0.0.0.0', () => {
  console.log(`Server is running on http://localhost:${port}`);
  console.log('Telefondan bağlanmak için aşağıdaki adreslerden ağınıza ait olanı kullanın:');
  for (const ip of getLocalIPs()) {
    console.log(`  ${ip.name}: http://${ip.address}:${port}`);
  }
});
