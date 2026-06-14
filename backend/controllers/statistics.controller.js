const Attendance = require("../models/Attendance");
const Member = require("../models/Member");
const Settings = require("../models/Settings");

async function loadSettings(userId) {
  try {
    const settings = await Settings.findOne({ createdBy: userId });
    if (settings) {
      return {
        morningStart: settings.morningStart || "08:00",
        afternoonStart: settings.afternoonStart || "14:00",
        lateToleranceMinutes: settings.lateToleranceMinutes ?? 15,
      };
    }
  } catch (_) {}
  return {
    morningStart: "08:00",
    afternoonStart: "14:00",
    lateToleranceMinutes: 15,
  };
}

function computeStatsForRecords(records) {
  let morningPresent = 0;
  let morningLate = 0;
  let morningAbsent = 0;
  let morningOutside = 0;
  let afternoonPresent = 0;
  let afternoonLate = 0;
  let afternoonAbsent = 0;
  let afternoonOutside = 0;

  for (const rec of records) {
    if (rec.session === "morning") {
      switch (rec.status) {
        case "present": morningPresent++; break;
        case "late": morningLate++; break;
        case "absent": morningAbsent++; break;
        case "outside_zone": morningOutside++; break;
      }
    } else if (rec.session === "afternoon") {
      switch (rec.status) {
        case "present": afternoonPresent++; break;
        case "late": afternoonLate++; break;
        case "absent": afternoonAbsent++; break;
        case "outside_zone": afternoonOutside++; break;
      }
    }
  }

  const morningCount = morningPresent + morningLate + morningAbsent + morningOutside;
  const afternoonCount = afternoonPresent + afternoonLate + afternoonAbsent + afternoonOutside;
  const totalDays = Math.max(morningCount, afternoonCount);

  return {
    morningPresent,
    morningLate,
    morningAbsent,
    morningOutside,
    afternoonPresent,
    afternoonLate,
    afternoonAbsent,
    afternoonOutside,
    totalDays
  };
}

// ===============================
// GET STATISTICS FOR ALL MEMBERS
// ===============================
exports.getAllStatistics = async (req, res) => {
  try {
    const userId = req.user.id;
    const members = await Member.find({ createdBy: userId });
    const config = await loadSettings(userId);

    const results = [];

    for (const member of members) {
      const records = await Attendance.find({
        member: member._id,
        createdBy: userId
      });

      const stats = computeStatsForRecords(records);
      const present = stats.morningPresent + stats.afternoonPresent;
      const late = stats.morningLate + stats.afternoonLate;
      const absent = stats.morningAbsent + stats.morningOutside + stats.afternoonAbsent + stats.afternoonOutside;
      const total = stats.totalDays * 2;

      results.push({
        member: {
          id: member._id,
          nom: member.nom,
          prenom: member.prenom
        },
        stats,
        present,
        late,
        absent,
        total,
        rate: total > 0 ? Math.min(100, (present / total) * 100) : 0,
      });
    }

    return res.status(200).json({
      success: true,
      data: results
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message
    });
  }
};


// ===============================
// GET STATISTICS FOR A SINGLE MEMBER
// ===============================
exports.getMemberStatistics = async (req, res) => {
  try {
    const userId = req.user.id;
    const memberId = req.params.memberId;

    const member = await Member.findOne({
      _id: memberId,
      createdBy: userId
    });

    if (!member) {
      return res.status(404).json({
        success: false,
        message: "Member not found"
      });
    }

    const records = await Attendance.find({
      member: memberId,
      createdBy: userId
    });

    const stats = computeStatsForRecords(records);
    const present = stats.morningPresent + stats.afternoonPresent;
    const late = stats.morningLate + stats.afternoonLate;
    const absent = stats.morningAbsent + stats.morningOutside + stats.afternoonAbsent + stats.afternoonOutside;
    const total = stats.totalDays * 2;

    return res.status(200).json({
      success: true,
      data: {
        member: {
          id: member._id,
          nom: member.nom,
          prenom: member.prenom
        },
        stats,
        present,
        late,
        absent,
        total,
        rate: total > 0 ? Math.min(100, (present / total) * 100) : 0,
      }
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
