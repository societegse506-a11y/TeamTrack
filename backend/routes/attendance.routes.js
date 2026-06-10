const express = require("express");
const router = express.Router();

const auth = require("../middlewares/auth.middleware");
const attendanceController = require("../controllers/attendance.controller");

// Unified check-in (supports morning / afternoon via body)
router.post("/checkin", auth, attendanceController.checkIn);

// Today's attendance (with member details)
router.get("/today", auth, attendanceController.getTodayAttendance);

// Today session-based stats (morning present/late, afternoon present/late)
router.get("/today-stats", auth, attendanceController.getTodayStats);

// Dashboard stats — single source of truth (aggregation, existing members only)
router.get("/dashboard-stats", auth, attendanceController.getDashboardStats);

// Member attendance history (calendar-filtered by year/month query params)
router.get("/member/:memberId", auth, attendanceController.getMemberAttendances);

// Member attendance list (all time, for detail list)
router.get("/member/:memberId/list", auth, attendanceController.getMemberAttendanceList);

// Liste générale
router.get("/", auth, attendanceController.getAttendances);

module.exports = router;
