import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import http from "http";
import { initSocket } from "./socket.js";
import internalRoute from "./routes/internal.js";

dotenv.config();

const app = express();

app.use(
  cors({
    origin: [
      "https://swiggy-surya.duckdns.org",
      "http://localhost:5173",
      "http://localhost:3000",
    ],
    credentials: true,
  }),
);
app.use(express.json());

app.use("/api/v1/internal", internalRoute);

const server = http.createServer(app);

initSocket(server);

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

server.listen(process.env.PORT, () => {
  console.log(`Realtime service is running port ${process.env.PORT}`);
});
