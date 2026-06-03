"use strict";

// eslint-disable-next-line no-unused-vars
module.exports = (err, _req, res, _next) => {
  console.error(err.stack);
  const status = err.status || 500;
  res.status(status).json({ error: err.message || "Internal Server Error" });
};
