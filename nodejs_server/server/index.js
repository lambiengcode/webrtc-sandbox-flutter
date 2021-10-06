require("dotenv").config();
const express = require("express");
const cors = require("cors");
const app = express();
const fs = require("fs");
const server = require("http").Server(app);
const io = require("socket.io")(server, {
  cors: {
    origin: "*",
  },
});
const port = process.env.PORT || 8000;

app.use(cors());

app.get("/", (req, res) => {
  fs.readFile(__dirname + "/client/index.html", function (err, html) {
    if (err) throw err;

    res.writeHeader(200, { "Content-Type": "text/html" });
    res.write(html);
    res.end();
  });
});

io.on("connection", function (socket) {
  socket.on("join", function (msg) {});

  socket.on("call", function (data) {
    io.emit("call", data);
  });
});

server.listen(port, "0.0.0.0", function () {
  console.log("Server is running on port: " + port);
});
