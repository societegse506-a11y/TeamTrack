const express = require("express");
const cors = require("cors");

// ===============================
// ROUTES IMPORTS
// ===============================
const authRoutes = require("./routes/auth.routes");
const memberRoutes = require("./routes/member.routes");
const settingsRoutes = require("./routes/settings.routes");
const statisticsRoutes = require("./routes/statistics.routes");
const attendanceRoutes = require("./routes/attendance.routes");

const app = express();

// ===============================
// MIDDLEWARE GLOBAL
// ===============================
app.use(cors());
app.use(express.json());

// ===============================
// API ROUTES
// ===============================
app.use("/api/auth", authRoutes);
app.use("/api/members", memberRoutes);
app.use("/api/settings", settingsRoutes);
app.use("/api/statistics", statisticsRoutes);
app.use("/api/attendance", attendanceRoutes);

// ===============================
// HEALTH CHECK (BONNE PRATIQUE)
// ===============================
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "TeamTrack API is running "
  });
});

module.exports = app;