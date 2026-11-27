const express = require('express');
const router = express.Router();
const { listUsers } = require('../controllers/usersController');
const { requireAuth, requireRole } = require('../middleware/auth');

router.get('/', requireAuth, requireRole('ceo'), listUsers);

module.exports = router;