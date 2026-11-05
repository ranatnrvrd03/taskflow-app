const { readTasks, writeTasks } = require('../data/taskStore');
const { ulid } = require('ulid');

// Görevin alabileceği geçerli değerler
const STATUSES = ['pending', 'in_progress', 'done']; // Bekliyor, Devam ediyor, Tamamlandı
const PRIORITIES = [1, 2, 3]; // 1 = Düşük, 2 = Orta, 3 = Yüksek

// Gelen alanları kontrol eder. Hata varsa hata mesajlarının listesini döner, yoksa boş liste.
// isUpdate = true ise (PATCH) alanların hepsi isteğe bağlıdır, sadece gönderilenler kontrol edilir.
function validateTask(body, isUpdate) {
  const errors = [];
  const { title, description, status, priority, assignee } = body;

  // Başlık: oluştururken zorunlu, güncellerken gönderildiyse boş olamaz
  if (!isUpdate || title !== undefined) {
    if (typeof title !== 'string' || title.trim() === '') {
      errors.push('Başlık zorunludur ve boş olamaz');
    }
  }

  // Açıklama ve sorumlu kişi: gönderildiyse metin olmalı
  if (description !== undefined && typeof description !== 'string') {
    errors.push('Açıklama metin olmalıdır');
  }
  if (assignee !== undefined && typeof assignee !== 'string') {
    errors.push('Sorumlu kişi metin olmalıdır');
  }

  // Durum: gönderildiyse sadece tanımlı değerlerden biri olabilir
  if (status !== undefined && !STATUSES.includes(status)) {
    errors.push(`Durum şunlardan biri olmalıdır: ${STATUSES.join(', ')}`);
  }

  // Öncelik: gönderildiyse sadece 1, 2 veya 3 olabilir
  if (priority !== undefined && !PRIORITIES.includes(priority)) {
    errors.push('Öncelik 1 (Düşük), 2 (Orta) veya 3 (Yüksek) olmalıdır');
  }

  return errors;
}

// POST /tasks — yeni bir görev oluşturur
function createTask(req, res) {
  const body = req.body || {};
  const errors = validateTask(body, false);

  if (errors.length > 0) {
    return res.status(400).json({ message: 'Geçersiz görev bilgisi', errors });
  }

  const { title, description, priority, assignee } = body;
  const tasks = readTasks();
  const newTask = {
    id: ulid(),
    title: title.trim(),
    description: (description ?? '').trim(), // gönderilmediyse boş metin, alan yine de var olur
    status: 'pending', // yeni görev her zaman "Bekliyor" olarak başlar
    priority: priority ?? 2, // gönderilmediyse varsayılan "Orta"
    assignee: (assignee ?? '').trim(),
    createdAt: new Date().toISOString(),
  };

  tasks.push(newTask);
  writeTasks(tasks);
  res.status(201).json({ message: 'Görev oluşturuldu', task: newTask });
}

// GET /tasks — tüm görevleri listeler (liste boş olsa bile sayı bilgisiyle döner)
function getAllTasks(req, res) {
  const tasks = readTasks();
  res.status(200).json({ count: tasks.length, tasks });
}

// GET /tasks/:id — id'si eşleşen tek bir görevi getirir
function getTaskById(req, res) {
  const tasks = readTasks();
  const task = tasks.find((t) => t.id === req.params.id);

  if (!task) {
    return res.status(404).json({ message: 'Görev bulunamadı' });
  }

  res.status(200).json({ task });
}

// PATCH /tasks/:id — id'si eşleşen görevi günceller
function updateTask(req, res) {
  const body = req.body || {};
  const allowedFields = ['title', 'description', 'status', 'priority', 'assignee'];

  // Güncellenecek hiçbir geçerli alan gönderilmediyse işlem yapılmaz
  const hasField = allowedFields.some((field) => body[field] !== undefined);
  if (!hasField) {
    return res.status(400).json({
      message: 'Güncellenecek alan gönderilmedi',
      errors: [`Şu alanlardan en az biri gönderilmelidir: ${allowedFields.join(', ')}`],
    });
  }

  const errors = validateTask(body, true);
  if (errors.length > 0) {
    return res.status(400).json({ message: 'Geçersiz görev bilgisi', errors });
  }

  const tasks = readTasks();
  const taskIndex = tasks.findIndex((t) => t.id === req.params.id);

  if (taskIndex === -1) {
    return res.status(404).json({ message: 'Görev bulunamadı' });
  }

  const current = tasks[taskIndex];
  const { title, status, description, priority, assignee } = body;

  // ?? kullanıyoruz: sadece alan hiç gönderilmediyse eski değer kalır.
  // (|| kullanılsaydı boş metin gönderildiğinde de eski değer geri gelirdi.)
  tasks[taskIndex] = {
    ...current,
    title: title !== undefined ? title.trim() : current.title,
    description: description !== undefined ? description.trim() : current.description,
    status: status ?? current.status,
    priority: priority ?? current.priority,
    assignee: assignee !== undefined ? assignee.trim() : current.assignee,
    updatedAt: new Date().toISOString(),
  };

  writeTasks(tasks);
  res.status(200).json({ message: 'Görev güncellendi', task: tasks[taskIndex] });
}

// DELETE /tasks/:id — id'si eşleşen görevi siler ve silinen görevi döner
function deleteTask(req, res) {
  const tasks = readTasks();
  const taskIndex = tasks.findIndex((t) => t.id === req.params.id);

  if (taskIndex === -1) {
    return res.status(404).json({ message: 'Görev bulunamadı' });
  }

  const [deletedTask] = tasks.splice(taskIndex, 1);
  writeTasks(tasks);
  // 204 yerine 200: yanıt gövdesi boş kalmasın, silinen görev de bilgi olarak dönsün
  res.status(200).json({ message: 'Görev silindi', task: deletedTask });
}

module.exports = { createTask, getAllTasks, getTaskById, updateTask, deleteTask };
