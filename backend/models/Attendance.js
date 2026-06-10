const mongoose = require("mongoose");

const attendanceSchema = new mongoose.Schema(
  {
    member: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Member",
      required: true
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
    date: {
      type: Date,
      required: true
    },
    attendanceDay: {
      type: String,
      required: true
    },
    session: {
      type: String,
      enum: ["morning", "afternoon"],
      required: true
    },
    checkInTime: {
      type: String
    },
    location: {
      lat: Number,
      lng: Number
    },
    status: {
      type: String,
      enum: ["present", "late", "absent", "outside_zone"],
      default: "present"
    }
  },
  {
    timestamps: true
  }
);

attendanceSchema.index(
  { member: 1, attendanceDay: 1, session: 1 },
  { unique: true }
);

module.exports = mongoose.model("Attendance", attendanceSchema);
