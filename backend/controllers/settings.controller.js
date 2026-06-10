const Settings = require("../models/Settings");
const User = require("../models/User");


exports.upsertSettings = async (req, res) => {
  try {
    const userId = req.user.id;

    const {
      morningStart,
      morningEnd,
      afternoonStart,
      afternoonEnd,
      lateToleranceMinutes,
      gpsRadius,
      workingDays,
      timezone
    } = req.body;

    let settings = await Settings.findOne({ createdBy: userId });

    if (!settings) {
      const user = await User.findById(userId);
      const workplaceLocation = user?.position
        ? { lat: user.position.lat, lng: user.position.lng }
        : { lat: null, lng: null };

      settings = await Settings.create({
        createdBy: userId,
        morningStart,
        morningEnd,
        afternoonStart,
        afternoonEnd,
        lateToleranceMinutes,
        gpsRadius,
        workingDays,
        timezone: timezone || "Africa/Tunis",
        workplaceLocation
      });

      return res.status(201).json({
        success: true,
        message: "Settings created successfully",
        data: settings
      });
    }

    settings.morningStart = morningStart || settings.morningStart;
    settings.morningEnd = morningEnd || settings.morningEnd;
    settings.afternoonStart = afternoonStart || settings.afternoonStart;
    settings.afternoonEnd = afternoonEnd || settings.afternoonEnd;
    settings.lateToleranceMinutes = lateToleranceMinutes ?? settings.lateToleranceMinutes;
    settings.gpsRadius = gpsRadius ?? settings.gpsRadius;
    if (workingDays) settings.workingDays = workingDays;
    if (timezone) settings.timezone = timezone;

    await settings.save();

    return res.status(200).json({
      success: true,
      message: "Settings updated successfully",
      data: settings
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message
    });
  }
};


exports.getSettings = async (req, res) => {
  try {
    const settings = await Settings.findOne({
      createdBy: req.user.id
    });

    if (!settings) {
      return res.status(200).json({
        success: true,
        data: null,
        message: "No settings configured yet"
      });
    }

    return res.status(200).json({
      success: true,
      data: settings
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
