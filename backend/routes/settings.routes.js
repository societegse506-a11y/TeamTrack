const express = require("express");
const router = express.Router();

const auth = require("../middlewares/auth.middleware");
const settingsController = require("../controllers/settings.controller");


router.post("/", auth, settingsController.upsertSettings);


router.get("/", auth, settingsController.getSettings);

module.exports = router;