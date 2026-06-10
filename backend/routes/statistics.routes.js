const express = require("express");
const router = express.Router();

const auth = require("../middlewares/auth.middleware");
const statisticsController = require("../controllers/statistics.controller");



router.get("/", auth, statisticsController.getAllStatistics);

router.get("/:memberId", auth, statisticsController.getMemberStatistics);

module.exports = router;