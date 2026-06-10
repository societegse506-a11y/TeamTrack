const Member = require("../models/Member");
const Attendance = require("../models/Attendance");

exports.createMember = async (req, res) => {
  try {
    const { nom, prenom, email, telephone, role, status } = req.body;

    const member = await Member.create({
      nom,
      prenom,
      email,
      telephone,
      role: role || "member",
      status: status || "active",
      createdBy: req.user.id
    });

    return res.status(201).json({
      success: true,
      message: "Member created successfully",
      data: member
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Error creating member",
      error: error.message
    });
  }
};

exports.getMembers = async (req, res) => {
  try {
    const members = await Member.find({
      createdBy: req.user.id
    });

    return res.status(200).json({
      success: true,
      count: members.length,
      data: members
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Error fetching members",
      error: error.message
    });
  }
};

exports.getMemberById = async (req, res) => {
  try {
    const member = await Member.findOne({
      _id: req.params.id,
      createdBy: req.user.id
    });

    if (!member) {
      return res.status(404).json({
        success: false,
        message: "Member not found"
      });
    }

    return res.status(200).json({
      success: true,
      data: member
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Error fetching member",
      error: error.message
    });
  }
};

exports.deleteMember = async (req, res) => {
  try {
    const member = await Member.findOneAndDelete({
      _id: req.params.id,
      createdBy: req.user.id
    });

    if (!member) {
      return res.status(404).json({
        success: false,
        message: "Member not found"
      });
    }

    // Cascade: remove all attendance records for this member
    await Attendance.deleteMany({ member: member._id });

    return res.status(200).json({
      success: true,
      message: "Member deleted successfully"
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Error deleting member",
      error: error.message
    });
  }
};

exports.updateMember = async (req, res) => {
  try {
    const { id } = req.params;
    const { nom, prenom, email, telephone, role, status } = req.body;

    const member = await Member.findOne({
      _id: id,
      createdBy: req.user.id
    });

    if (!member) {
      return res.status(404).json({
        success: false,
        message: "Member not found"
      });
    }

    member.nom = nom || member.nom;
    member.prenom = prenom || member.prenom;
    member.email = email != null ? email : member.email;
    member.telephone = telephone || member.telephone;
    if (role != null) member.role = role;
    if (status != null) member.status = status;

    await member.save();

    return res.status(200).json({
      success: true,
      message: "Member updated successfully",
      data: member
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Error updating member",
      error: error.message
    });
  }
};
