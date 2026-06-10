const express = require("express");
const router = express.Router();

const memberController = require("../controllers/member.controller");
const auth = require("../middlewares/auth.middleware");


router.post("/", auth, memberController.createMember);
router.get("/", auth, memberController.getMembers);
router.get("/:id", auth, memberController.getMemberById);
router.delete("/:id", auth, memberController.deleteMember);
router.put("/:id", auth, memberController.updateMember);
module.exports = router;