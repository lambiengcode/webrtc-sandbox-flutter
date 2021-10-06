module.exports = {
  apps: [
    {
      name: "webRTC",
      script: "dist/server/index.js",
      args: "server/index.js",
      wait_ready: true,
      error_file: "./logs/err.log",
      out_file: "./logs/out.log",
      log_file: "./logs/combined.log",
      log_date_format: "YYYY-MM-DD HH:mm:ss:SSSS",
      min_uptime: 10000,
      max_restarts: 3,
    },
  ],
};
