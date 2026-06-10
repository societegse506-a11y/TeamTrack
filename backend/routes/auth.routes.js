const express = require("express");
const router = express.Router();

const auth = require("../controllers/auth.controller");
const validate = require("../middlewares/validate.middleware");
const authMiddleware = require("../middlewares/auth.middleware");

router.get("/me", authMiddleware, auth.getMe);
router.put("/me", authMiddleware, auth.updateProfile);

router.post("/register",
  validate('nom', 'prenom', 'email', 'telephone', 'password', 'position.lat', 'position.lng'),
  auth.register
);
router.post("/login", auth.login);

// FORGOT PASSWORD
router.post("/forgot-password", auth.forgotPassword);

// RESET PASSWORD
router.post("/reset-password", auth.resetPassword);

module.exports = router;