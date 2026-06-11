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
      let workplaceLocation;
      if (req.body.workplaceLocation) {
        workplaceLocation = req.body.workplaceLocation;
      } else {
        workplaceLocation = user?.position
          ? { lat: user.position.lat, lng: user.position.lng }
          : { lat: null, lng: null };
      }

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
    if (req.body.workplaceLocation) {
      settings.workplaceLocation = req.body.workplaceLocation;
    }

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
    let settings = await Settings.findOne({
      createdBy: req.user.id
    });

    if (!settings) {
      const user = await User.findById(req.user.id);
      const workplaceLocation = user?.position
        ? { lat: user.position.lat, lng: user.position.lng }
        : { lat: null, lng: null };

      settings = await Settings.create({
        createdBy: req.user.id,
        workplaceLocation
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
