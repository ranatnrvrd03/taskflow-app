// Tanımlı olmayan bir adrese istek gelirse çalışır (tüm route'lardan sonra eklenir)
function notFound(req, res) {
  res.status(404).json({ message: 'Endpoint bulunamadı', path: req.originalUrl });
}

// Uygulamada oluşan tüm hataları yakalar ve her zaman JSON döner
// Express'in 4 parametreli fonksiyonu hata yakalayıcı olarak tanıması için "next" de yazılmalı
// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  // İstek gövdesi geçerli bir JSON değilse (ör. eksik tırnak, fazla virgül)
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ message: 'İstek gövdesi geçerli bir JSON değil' });
  }

  console.error('Sunucu hatası:', err);
  res.status(500).json({ message: 'Sunucu hatası' });
}

module.exports = { notFound, errorHandler };
