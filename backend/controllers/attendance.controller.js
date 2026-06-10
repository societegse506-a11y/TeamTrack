const mongoose = require("mongoose");
const Attendance = require("../models/Attendance");
const Member = require("../models/Member");
const Settings = require("../models/Settings");


function getAttendanceDay(date, timezone) {
  timezone = timezone || 'Africa/Tunis';
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).format(date);
}

function formatCheckInTime(date, timezone) {
  timezone = timezone || 'Africa/Tunis';
  return new Intl.DateTimeFormat('en', {
    timeZone: timezone,
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  }).format(date);
}




function todayRange() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  return { today, tomorrow };
}

function monthRange(year, month) {
  const start = new Date(year, month, 1);
  const end = new Date(year, month + 1, 1);
  return { start, end };
}

function calculateDistance(lat1, lng1, lat2, lng2) {
  const R = 6371000;
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

async function loadSettings(userId) {
  try {
    const settings = await Settings.findOne({ createdBy: userId });
    if (settings) {
      return {
        morningStart: settings.morningStart || "08:00",
        morningEnd: settings.morningEnd || "12:00",
        afternoonStart: settings.afternoonStart || "14:00",
        afternoonEnd: settings.afternoonEnd || "18:00",
        lateToleranceMinutes: settings.lateToleranceMinutes ?? 15,
        gpsRadius: settings.gpsRadius ?? 100,
        workplaceLocation: settings.workplaceLocation || { lat: null, lng: null },
        timezone: settings.timezone || "Africa/Tunis",
        workingDays: settings.workingDays || ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      };
    }
  } catch (_) {}
  return {
    morningStart: "08:00",
    morningEnd: "12:00",
    afternoonStart: "14:00",
    afternoonEnd: "18:00",
    lateToleranceMinutes: 15,
    gpsRadius: 100,
    workplaceLocation: { lat: null, lng: null },
    timezone: "Africa/Tunis",
    workingDays: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
  };
}

function computeStatus(checkInTime, session, config) {
  const startStr = session === "morning" ? config.morningStart : config.afternoonStart;
  const parts = startStr.split(":");
  const startHour = parseInt(parts[0]) || (session === "morning" ? 8 : 14);
  const startMin = parseInt(parts[1]) || 0;

  const limit = new Date(checkInTime);
  limit.setHours(0, 0, 0, 0);
  limit.setHours(startHour, startMin + config.lateToleranceMinutes, 0, 0);

  return checkInTime > limit ? "late" : "present";
}

const DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

function isWorkingDay(date, workingDays) {
  const dayName = DAY_NAMES[date.getDay()];
  return workingDays.map(d => d.toLowerCase()).includes(dayName.toLowerCase());
}

function parseTime(str, fallbackHour, fallbackMin) {
  const p = String(str ?? "").split(":");
  return {
    hour: parseInt(p[0]) || fallbackHour,
    min: parseInt(p[1]) || fallbackMin,
  };
}

function isTimeInWindow(checkTime, startStr, endStr, session) {
  const start = parseTime(startStr, session === "morning" ? 8 : 14, 0);
  const end = parseTime(endStr, session === "morning" ? 12 : 18, 0);
  const checkH = checkTime.getHours();
  const checkM = checkTime.getMinutes();
  const checkVal = checkH * 60 + checkM;
  const startVal = start.hour * 60 + start.min;
  const endVal = end.hour * 60 + end.min;
  return checkVal >= startVal && checkVal < endVal;
}

// ===============================
// UNIFIED CHECK-IN (morning / afternoon)
// ===============================
exports.checkIn = async (req, res) => {
  try {
    const { memberId, session, latitude, longitude, timestamp } = req.body;

    if (!memberId || !session) {
      return res.status(400).json({
        success: false,
        message: "memberId and session are required"
      });
    }

    if (!["morning", "afternoon"].includes(session)) {
      return res.status(400).json({
        success: false,
        message: "session must be 'morning' or 'afternoon'"
      });
    }

    const member = await Member.findOne({
      _id: memberId,
      createdBy: req.user.id
    });

    if (!member) {
      return res.status(404).json({
        success: false,
        message: "Member not found"
      });
    }

    const { today, tomorrow } = todayRange();
    const checkInTime = timestamp ? new Date(timestamp) : new Date();
const config = await loadSettings(req.user.id);
    const attendanceDay = getAttendanceDay(checkInTime, config.timezone);

    // 1. Validate working day
    if (!isWorkingDay(checkInTime, config.workingDays)) {
      return res.status(400).json({
        success: false,
        message: "Today is not a working day. Check-in not allowed."
      });
    }

    // 2. Validate session time window
    const startField = session === "morning" ? config.morningStart : config.afternoonStart;
    const endField = session === "morning" ? config.morningEnd : config.afternoonEnd;
    if (!isTimeInWindow(checkInTime, startField, endField, session)) {
      return res.status(400).json({
        success: false,
        message: `${session.charAt(0).toUpperCase() + session.slice(1)} session is not open. Allowed: ${startField} - ${endField}`
      });
    }

    // 3. Validate GPS zone (backend is source of truth — mandatory)
    let gpsDistance = null;

    if (latitude == null || longitude == null) {
      return res.status(400).json({
        success: false,
        message: "GPS coordinates are required for check-in. Please enable location."
      });
    }

    if (config.workplaceLocation?.lat == null || config.workplaceLocation?.lng == null) {
      return res.status(400).json({
        success: false,
        message: "Workplace location is not configured. It is automatically set from your registration GPS coordinates."
      });
    }

    gpsDistance = calculateDistance(latitude, longitude, config.workplaceLocation.lat, config.workplaceLocation.lng);
    if (gpsDistance > config.gpsRadius) {
      return res.status(400).json({
        success: false,
        message: "Check-in denied: you are outside the allowed area",
        distance: Math.round(gpsDistance),
        allowedRadius: config.gpsRadius
      });
    }

    // 4. Compute status (present / late)
    const status = computeStatus(checkInTime, session, config);
    const sessionLabel = session.charAt(0).toUpperCase() + session.slice(1);

    // 5. Atomic upsert — prevents duplicates & race conditions
    const checkInTimeFormatted = formatCheckInTime(checkInTime, config.timezone);
  const result = await Attendance.findOneAndUpdate(
  { member: memberId, attendanceDay, session },
  {
    $setOnInsert: {
      member: memberId,
      createdBy: req.user.id,
      date: checkInTime,
      attendanceDay,
      session,
      checkInTime: checkInTimeFormatted,
      location: { lat: latitude ?? 0, lng: longitude ?? 0 },
      status,
    }
  },
  { upsert: true, new: true, rawResult: true }
);
    if (result.lastErrorObject?.updatedExisting) {
      return res.status(400).json({
        success: false,
        message: `${sessionLabel} check-in already done for today`
      });
    }

    const attendance = result.value;

    return res.status(201).json({
      success: true,
      message: `${sessionLabel} check-in successful`,
      data: {
        attendance,
        status,
        checkedInAt: checkInTime.toISOString(),
        distance: gpsDistance != null ? Math.round(gpsDistance) : null,
        allowedRadius: config.gpsRadius,
      }
    });

  } catch (error) {
    console.error("=== CHECK-IN ERROR ===");
    console.error("Request body:", req.body);
    console.error("Error name:", error.name);
    console.error("Error code:", error.code);
    console.error("Error message:", error.message);
    console.error("Stack:", error.stack);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "This check-in already exists (duplicate)"
      });
    }

    return res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message
    });
  }
};

// ===============================
// GET TODAY'S ATTENDANCE (with member details)
// ===============================
exports.getTodayAttendance = async (req, res) => {
  try {
    const { today, tomorrow } = todayRange();
    const config = await loadSettings(req.user.id);

    const data = await Attendance.find({
      createdBy: req.user.id,
      attendanceDay: getAttendanceDay(new Date(), config.timezone)
    }).populate("member");

    return res.status(200).json({
      success: true,
      count: data.length,
      data
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// ===============================
// GET TODAY SESSION-BASED STATS
// ===============================
exports.getTodayStats = async (req, res) => {
  try {
    const config = await loadSettings(req.user.id);
    const todayStr = getAttendanceDay(new Date(), config.timezone);

    const records = await Attendance.find({
      createdBy: req.user.id,
      attendanceDay: todayStr
    });

    const members = await Member.countDocuments({ createdBy: req.user.id });

    let morningPresent = 0;
    let morningLate = 0;
    let afternoonPresent = 0;
    let afternoonLate = 0;

    for (const rec of records) {
      if (rec.session === "morning") {
        if (rec.status === "late") morningLate++;
        else if (rec.status === "present") morningPresent++;
      } else if (rec.session === "afternoon") {
        if (rec.status === "late") afternoonLate++;
        else if (rec.status === "present") afternoonPresent++;
      }
    }

    return res.status(200).json({
      success: true,
      data: {
        totalMembers: members,
        morningPresent,
        morningLate,
        afternoonPresent,
        afternoonLate
      }
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// ===============================
// DASHBOARD STATS — single source of truth
// ===============================
exports.getDashboardStats = async (req, res) => {
  try {
    const userId = req.user.id;
    const config = await loadSettings(userId);

    // 1. Get active member IDs (only existing members)
    const activeMembers = await Member.find({ createdBy: userId }).select("_id");
    const activeMemberIds = activeMembers.map(m => m._id);
    const totalMembers = activeMemberIds.length;

    // 2. Aggregate attendance by member, filtering only active members
    const aggregation = await Attendance.aggregate([
      {
        $match: {
          createdBy: mongoose.Types.ObjectId.createFromHexString(userId),
          member: { $in: activeMemberIds },
        }
      },
      {
        $group: {
          _id: null,
          present: { $sum: { $cond: [{ $eq: ["$status", "present"] }, 1, 0] } },
          late: { $sum: { $cond: [{ $eq: ["$status", "late"] }, 1, 0] } },
          outside: { $sum: { $cond: [{ $eq: ["$status", "outside_zone"] }, 1, 0] } },
        }
      }
    ]);

    const stats = aggregation[0] || { present: 0, late: 0, outside: 0 };
    const totalPresent = stats.present;
    const totalLate = stats.late;
    const totalOutside = stats.outside;
    const totalRecords = totalPresent + totalLate + totalOutside;

    // 3. Monthly breakdown via aggregation
    const monthlyAgg = await Attendance.aggregate([
      {
        $match: {
          createdBy: mongoose.Types.ObjectId.createFromHexString(userId),
          member: { $in: activeMemberIds },
        }
      },
      {
        $group: {
          _id: { $substrCP: ["$attendanceDay", 0, 7] },
          present: { $sum: { $cond: [{ $eq: ["$status", "present"] }, 1, 0] } },
          late: { $sum: { $cond: [{ $eq: ["$status", "late"] }, 1, 0] } },
          absent: { $sum: { $cond: [{ $eq: ["$status", "outside_zone"] }, 1, 0] } },
          total: { $sum: 1 },
        }
      },
      { $sort: { _id: 1 } },
      {
        $project: {
          _id: 0,
          yearMonth: "$_id",
          present: 1,
          late: 1,
          absent: 1,
          total: 1,
        }
      }
    ]);

    // 4. Per-member stats via aggregation
    const memberAgg = await Attendance.aggregate([
      {
        $match: {
          createdBy: mongoose.Types.ObjectId.createFromHexString(userId),
          member: { $in: activeMemberIds },
        }
      },
      {
        $group: {
          _id: "$member",
          present: { $sum: { $cond: [{ $eq: ["$status", "present"] }, 1, 0] } },
          late: { $sum: { $cond: [{ $eq: ["$status", "late"] }, 1, 0] } },
          absent: { $sum: { $cond: [{ $eq: ["$status", "outside_zone"] }, 1, 0] } },
          total: { $sum: 1 },
        }
      },
      {
        $lookup: {
          from: "members",
          localField: "_id",
          foreignField: "_id",
          as: "memberInfo",
        }
      },
      { $unwind: { path: "$memberInfo", preserveNullAndEmptyArrays: true } },
      {
        $project: {
          _id: 0,
          memberId: "$_id",
          nom: { $ifNull: ["$memberInfo.nom", "Deleted"] },
          prenom: { $ifNull: ["$memberInfo.prenom", ""] },
          present: 1,
          late: 1,
          absent: 1,
          total: 1,
        }
      },
      { $sort: { total: -1 } }
    ]);

    // 5. Today's session breakdown
    const todayStr = getAttendanceDay(new Date(), config.timezone);
    const todayRecords = await Attendance.find({
      createdBy: userId,
      attendanceDay: todayStr,
      member: { $in: activeMemberIds },
    });

    let todayMorningPresent = 0, todayMorningLate = 0;
    let todayAfternoonPresent = 0, todayAfternoonLate = 0;

    for (const rec of todayRecords) {
      if (rec.session === "morning") {
        if (rec.status === "late") todayMorningLate++;
        else if (rec.status === "present") todayMorningPresent++;
      } else if (rec.session === "afternoon") {
        if (rec.status === "late") todayAfternoonLate++;
        else if (rec.status === "present") todayAfternoonPresent++;
      }
    }

    // 6. Attendance rate (safe: clamped 0–100)
    const expectedToday = totalMembers * 2;
    const attendanceRate = expectedToday > 0
      ? Math.min(100, ((todayMorningPresent + todayAfternoonPresent) / expectedToday) * 100)
      : 0;

    const overallRate = totalRecords > 0
      ? Math.min(100, (totalPresent / totalRecords) * 100)
      : 0;

    const lateRate = totalRecords > 0
      ? Math.min(100, (totalLate / totalRecords) * 100)
      : 0;

    const outsideRate = totalRecords > 0
      ? Math.min(100, (totalOutside / totalRecords) * 100)
      : 0;

    return res.status(200).json({
      success: true,
      data: {
        totalMembers,
        attendanceRate: Math.round(attendanceRate * 10) / 10,
        overallRate: Math.round(overallRate * 10) / 10,
        lateRate: Math.round(lateRate * 10) / 10,
        outsideRate: Math.round(outsideRate * 10) / 10,

        today: {
          morningPresent: todayMorningPresent,
          morningLate: todayMorningLate,
          afternoonPresent: todayAfternoonPresent,
          afternoonLate: todayAfternoonLate,
        },

        totals: {
          present: totalPresent,
          late: totalLate,
          absent: totalOutside,
          records: totalRecords,
        },

        memberStats: memberAgg.map(m => ({
          id: m.memberId,
          nom: m.nom,
          prenom: m.prenom,
          present: m.present,
          late: m.late,
          absent: m.absent,
          total: m.total,
          rate: m.total > 0 ? Math.min(100, (m.present / m.total) * 100) : 0,
        })),

        monthlyStats: monthlyAgg.map(m => ({
          yearMonth: m.yearMonth,
          present: m.present,
          late: m.late,
          absent: m.absent,
          total: m.total,
        })),
      }
    });

  } catch (error) {
    console.error("=== DASHBOARD-STATS ERROR ===", error);
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// ===============================
// GET ALL ATTENDANCES
// ===============================
exports.getAttendances = async (req, res) => {
  try {
    const data = await Attendance.find({
      createdBy: req.user.id
    }).populate("member");

    return res.status(200).json({
      success: true,
      count: data.length,
      data
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// ===============================
// GET MEMBER ATTENDANCE HISTORY (calendar-friendly)
// ===============================
exports.getMemberAttendances = async (req, res) => {
  try {
    const { memberId } = req.params;
    let { year, month } = req.query;

    const now = new Date();
    year = year != null ? parseInt(year) : now.getFullYear();
    month = month != null ? parseInt(month) - 1 : now.getMonth();

    const { start, end } = monthRange(year, month);

    const records = await Attendance.find({
      member: memberId,
      createdBy: req.user.id,
      date: { $gte: start, $lt: end }
    }).sort({ date: -1, session: 1 });

    return res.status(200).json({
      success: true,
      count: records.length,
      data: records
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// ===============================
// GET MEMBER ATTENDANCE LIST (all time, for detail list below calendar)
// ===============================
exports.getMemberAttendanceList = async (req, res) => {
  try {
    const { memberId } = req.params;

    const records = await Attendance.find({
      member: memberId,
      createdBy: req.user.id
    }).sort({ date: -1, session: 1 });

    return res.status(200).json({
      success: true,
      count: records.length,
      data: records
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
