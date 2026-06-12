const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  nom: String,
  prenom: String,
  email: { type: String, unique: true ,required: true},
  telephone: String,
password: { type: String, required: true },

  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  isActive: {
    type: Boolean,
    default: true
  },

  position: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true }
  },

  resetToken: String,
  resetTokenExpire: Date
});

module.exports = mongoose.model("User", userSchema);