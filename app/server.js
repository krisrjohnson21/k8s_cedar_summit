const express = require("express");
const os = require("os");

const app = express();
const PORT = process.env.PORT || 3000;
const START_TIME = Date.now();

// Health check — used by K8s liveness/readiness probes
app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    hostname: os.hostname(),
    uptime: Math.floor((Date.now() - START_TIME) / 1000),
  });
});

// Main route
app.get("/", (req, res) => {
  res.json({
    message: "Cedar Summit",
    hostname: os.hostname(),
    timestamp: new Date().toISOString(),
  });
});

// Status page — lightweight replacement for the old HTML status page
app.get("/status", (req, res) => {
  res.json({
    service: "cedar-summit",
    hostname: os.hostname(),
    uptime: Math.floor((Date.now() - START_TIME) / 1000),
    memory: process.memoryUsage(),
    node_version: process.version,
  });
});

app.listen(PORT, () => {
  console.log(`cedar-summit listening on port ${PORT}`);
});
