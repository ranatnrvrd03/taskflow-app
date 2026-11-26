const express = require('express');
const os = require('os');
const app = express();
const tasksRouter = require('./routes/tasks');
const logger = require('./middleware/logger');
const { notFound, errorHandler } = require('./middleware/errorHandler');
const { dbFilePath } = require('./data/db');

const port = process.env.PORT || 7777;

app.use(logger);
app.use(express.json());

app.get('/', (req, res) => {
  res.status(200).json({ message: 'TaskFlow API çalışıyor' });
});

app.use('/tasks', tasksRouter);

app.use(notFound);
app.use(errorHandler);

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

app.listen(port, '0.0.0.0', () => {
  console.log(`Server is running on http://localhost:${port}`);
    console.log(`Veritabanı: ${dbFilePath}`);
  console.log('Telefondan bağlanmak için aşağıdaki adreslerden ağınıza ait olanı kullanın:');
  for (const ip of getLocalIPs()) {
    console.log(`  ${ip.name}: http://${ip.address}:${port}`);
  }
});