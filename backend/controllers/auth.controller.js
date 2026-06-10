const User = require("../models/User");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const nodemailer = require("nodemailer");


// ===============================
// GET CURRENT USER
// ===============================
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password -resetToken -resetTokenExpire');
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }
    return res.status(200).json({ success: true, data: user });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server error", error: error.message });
  }
};

// ===============================
// REGISTER
// ===============================
exports.register = async (req, res) => {
  try {
    const { nom, prenom, email, telephone, password, position } = req.body;

    if (!position || position.lat == null || position.lng == null) {
      return res.status(400).json({
        success: false,
        message: "GPS position (latitude and longitude) is required"
      });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: "User already exists"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      nom,
      prenom,
      email,
      telephone,
      password: hashedPassword,
      position
    });

    return res.status(201).json({
      success: true,
      message: "User created successfully",
      data: {
        id: newUser._id,
        nom: newUser.nom,
        prenom: newUser.prenom,
        email: newUser.email,
        telephone: newUser.telephone,
        position: newUser.position
      }
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
// LOGIN
// ===============================
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({
        success: false,
        message: "Invalid credentials"
      });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(400).json({
        success: false,
        message: "Invalid credentials"
      });
    }

    const token = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.status(200).json({
      success: true,
      message: "Login successful",
      token,
      data: {
        id: user._id,
        nom: user.nom,
        prenom: user.prenom,
        email: user.email,
        telephone: user.telephone,
        position: user.position
      }
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
// UPDATE PROFILE
// ===============================
exports.updateProfile = async (req, res) => {
  try {
    const { nom, prenom, telephone, currentPassword, newPassword } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    if (nom !== undefined) user.nom = nom;
    if (prenom !== undefined) user.prenom = prenom;
    if (telephone !== undefined) user.telephone = telephone;

    if (newPassword) {
      if (!currentPassword) {
        return res.status(400).json({
          success: false,
          message: "Current password is required to set a new password"
        });
      }
      const isValid = await bcrypt.compare(currentPassword, user.password);
      if (!isValid) {
        return res.status(400).json({
          success: false,
          message: "Current password is incorrect"
        });
      }
      user.password = await bcrypt.hash(newPassword, 10);
    }

    await user.save();

    return res.status(200).json({
      success: true,
      message: "Profile updated successfully",
      data: {
        id: user._id,
        nom: user.nom,
        prenom: user.prenom,
        email: user.email,
        telephone: user.telephone,
        position: user.position
      }
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
// FORGOT PASSWORD — send 6-digit code
// ===============================
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();

    user.resetToken = code;
    user.resetTokenExpire = Date.now() + 10 * 60 * 1000; // 10 min
    await user.save({ validateBeforeSave: false });

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });

    await transporter.sendMail({
      to: user.email,
      subject: "Password Reset Code - TeamTrack",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 400px; margin: 0 auto;">
          <h2 style="color: #4F46E5;">Password Reset</h2>
          <p>You requested to reset your password.</p>
          <p style="font-size: 14px; color: #666;">Use the code below to reset your password. It expires in 10 minutes.</p>
          <div style="text-align: center; margin: 24px 0;">
            <span style="font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #4F46E5; background: #F3F4F6; padding: 12px 24px; border-radius: 12px;">${code}</span>
          </div>
          <p style="font-size: 12px; color: #999;">If you didn't request this, please ignore this email.</p>
        </div>
      `
    });

    return res.status(200).json({
      success: true,
      message: "Verification code sent to your email"
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
// RESET PASSWORD — verify code + set new password
// ===============================
exports.resetPassword = async (req, res) => {
  try {
    const { email, code, password } = req.body;

    if (!email || !code || !password) {
      return res.status(400).json({
        success: false,
        message: "Email, code, and new password are required"
      });
    }

    const user = await User.findOne({
      email,
      resetToken: code,
      resetTokenExpire: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({
        success: false,
        message: "Invalid or expired verification code"
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    user.password = hashedPassword;
    user.resetToken = undefined;
    user.resetTokenExpire = undefined;

    await user.save();

    return res.status(200).json({
      success: true,
      message: "Password reset successful"
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message
    });
  }
};