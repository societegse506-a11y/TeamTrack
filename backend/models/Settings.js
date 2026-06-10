const mongoose = require("mongoose");

const settingsSchema = new mongoose.Schema(
  {
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },

    morningStart: {
      type: String,
      default: "08:00"
    },

    morningEnd: {
      type: String,
      default: "12:00"
    },

    afternoonStart: {
      type: String,
      default: "14:00"
    },

    afternoonEnd: {
      type: String,
      default: "18:00"
    },

    lateToleranceMinutes: {
      type: Number,
      default: 15
    },

    gpsRadius: {
      type: Number,
      default: 100
    },

    workplaceLocation: {
      lat: { type: Number, default: null },
      lng: { type: Number, default: null }
    },

    timezone: {
      type: String,
      default: "Africa/Tunis"
    },

    workingDays: {
      type: [String],
      default: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model("Settings", settingsSchema);
