const jwt = require("jsonwebtoken");

module.exports = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: "No token provided"
      });
    }

    // format: Bearer token
    const token = authHeader.split(" ")[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Invalid token format"
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 👇 IMPORTANT: on injecte user dans req
    req.user = decoded;

    next();

  } catch (error) {
    return res.status(401).json({
      success: false,
      message: "Unauthorized - Invalid token",
      error: error.message
    });
  }
};