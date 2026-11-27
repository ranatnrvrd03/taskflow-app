const tasks = require('../data/taskRepository');
const users = require('../data/userRepository');
const { ulid } = require('ulid');

const STATUSES = ['pending', 'in_progress', 'done'];
const PRIORITIES = [1, 2, 3];
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const ALLOWED_FIELDS = ['title', 'description', 'status', 'priority', 'assigneeId', 'deadline'];

function isValidDate(value) {
  if (typeof value !== 'string' || !DATE_PATTERN.test(value)) {
    return false;
  }
  const date = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().startsWith(value);
}

function isCeo(req) {
  return req.user.role === 'ceo';
}

function canSee(req, task) {
  return isCeo(req) || task.assigneeId === req.user.id;
}

function validateTask(body, isUpdate) {
  const errors = [];
  const { title, description, status, priority, assigneeId, deadline } = body;

  if (!isUpdate || title !== undefined) {
    if (typeof title !== 'string' || title.trim() === '') {
      errors.push('Başlık zorunludur ve boş olamaz');
    }
  }

  if (description !== undefined && typeof description !== 'string') {
    errors.push('Açıklama metin olmalıdır');
  }

  if (status !== undefined && !STATUSES.includes(status)) {
    errors.push(`Durum şunlardan biri olmalıdır: ${STATUSES.join(', ')}`);
  }

  if (priority !== undefined && !PRIORITIES.includes(priority)) {
    errors.push('Öncelik 1 (Düşük), 2 (Orta) veya 3 (Yüksek) olmalıdır');
  }

  if (deadline !== undefined && deadline !== null && !isValidDate(deadline)) {
    errors.push('Son tarih YYYY-AA-GG biçiminde geçerli bir tarih olmalıdır (ör. 2026-11-30)');
  }

  if (assigneeId !== undefined && assigneeId !== null) {
    if (typeof assigneeId !== 'string' || !users.findById(assigneeId)) {
      errors.push('Atanan kişi bulunamadı');
    }
  }

  return errors;
}

function createTask(req, res) {
  const body = req.body || {};
  const errors = validateTask(body, false);

  if (errors.length > 0) {
    return res.status(400).json({ message: 'Geçersiz görev bilgisi', errors });
  }

  const { title, description, priority, assigneeId, deadline } = body;
  const task = tasks.insert({
    id: ulid(),
    title: title.trim(),
    description: (description ?? '').trim(),
    status: 'pending',
    priority: priority ?? 2,
    assigneeId: assigneeId ?? null,
    deadline: deadline ?? null,
    createdBy: req.user.id,
    createdAt: new Date().toISOString(),
  });

  res.status(201).json({ message: 'Görev oluşturuldu', task });
}

function getAllTasks(req, res) {
  const list = isCeo(req) ? tasks.findAll() : tasks.findAll(req.user.id);
  res.status(200).json({ count: list.length, tasks: list });
}

function getTaskById(req, res) {
  const task = tasks.findById(req.params.id);

  if (!task || !canSee(req, task)) {
    return res.status(404).json({ message: 'Görev bulunamadı' });
  }

  res.status(200).json({ task });
}

function updateTask(req, res) {
  const body = req.body || {};

  const sentFields = ALLOWED_FIELDS.filter((field) => body[field] !== undefined);
  if (sentFields.length === 0) {
    return res.status(400).json({
      message: 'Güncellenecek alan gönderilmedi',
      errors: [`Şu alanlardan en az biri gönderilmelidir: ${ALLOWED_FIELDS.join(', ')}`],
    });
  }

  if (!isCeo(req) && sentFields.some((field) => field !== 'status')) {
    return res.status(403).json({ message: 'Çalışanlar sadece görevin durumunu değiştirebilir' });
  }

  const errors = validateTask(body, true);
  if (errors.length > 0) {
    return res.status(400).json({ message: 'Geçersiz görev bilgisi', errors });
  }

  const current = tasks.findById(req.params.id);
  if (!current || !canSee(req, current)) {
    return res.status(404).json({ message: 'Görev bulunamadı' });
  }

  const { title, status, description, priority, assigneeId, deadline } = body;

  const task = tasks.update(current.id, {
    title: title !== undefined ? title.trim() : current.title,
    description: description !== undefined ? description.trim() : current.description,
    status: status ?? current.status,
    priority: priority ?? current.priority,
    assigneeId: assigneeId !== undefined ? assigneeId : current.assigneeId,
    deadline: deadline !== undefined ? deadline : current.deadline,
    updatedAt: new Date().toISOString(),
  });

  res.status(200).json({ message: 'Görev güncellendi', task });
}

function deleteTask(req, res) {
  const task = tasks.findById(req.params.id);

  if (!task) {
    return res.status(404).json({ message: 'Görev bulunamadı' });
  }

  tasks.remove(task.id);
  res.status(200).json({ message: 'Görev silindi', task });
}

module.exports = { createTask, getAllTasks, getTaskById, updateTask, deleteTask };