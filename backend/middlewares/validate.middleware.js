module.exports = (...requiredFields) => {
  return (req, res, next) => {
    const missing = requiredFields.filter(field => {
      const value = field.split('.').reduce((obj, key) => obj?.[key], req.body);
      return value === undefined || value === null || value === '';
    });

    if (missing.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Missing required fields: ${missing.join(', ')}`
      });
    }

    next();
  };
};
