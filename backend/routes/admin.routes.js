const express = require("express");
const router = express.Router();

const admin = require("../controllers/admin.controller");
const authMiddleware = require("../middlewares/auth.middleware");
const adminMiddleware = require("../middlewares/admin.middleware");

router.use(authMiddleware, adminMiddleware);

router.get("/users", admin.getUsers);
router.get("/users/:id", admin.getUserById);
router.put("/users/:id", admin.updateUser);
router.delete("/users/:id", admin.deleteUser);
router.put("/users/:id/toggle-active", admin.toggleActive);

module.exports = router;
