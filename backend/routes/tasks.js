const express = require('express');
const router = express.Router();
const { createTask, getAllTasks, getTaskById, updateTask, deleteTask } = require('../controllers/tasksController');
const { requireAuth, requireRole } = require('../middleware/auth');

router.use(requireAuth);

router.post('/', requireRole('ceo'), createTask);
router.get('/', getAllTasks);
router.get('/:id', getTaskById);
router.patch('/:id', updateTask);
router.delete('/:id', requireRole('ceo'), deleteTask);

module.exports = router;