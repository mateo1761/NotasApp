import express from "express";
import cors from "cors";
import { config } from "./config.js";
import { setupAuthRoutes } from "./routes/auth.js";
import { setupNotesRoutes } from "./routes/notes.js";

const app = express();

app.use(cors());
app.use(express.json());

app.get("/health", (req, res) => res.json({ status: "ok", time: Date.now() }));

setupAuthRoutes(app);
setupNotesRoutes(app);

app.listen(config.port, () => {
  console.log(`API listening on http://localhost:${config.port}`);
});