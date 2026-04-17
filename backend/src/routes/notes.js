import { notes, dbWrite } from "../db.js";
import { authGuard } from "../middleware/auth.js";

export function setupNotesRoutes(app) {
  app.get("/notes", authGuard, async (req, res) => {
    const userNotes = notes
      .filter((n) => n.userId === req.user.id)
      .sort((a, b) => b.updatedAt - a.updatedAt);
    return res.json(userNotes);
  });

  app.post("/notes", authGuard, async (req, res) => {
    const { title, content, location } = req.body || {};
    if (!title) return res.status(400).json({ message: "title is required" });

    const n = {
      id: String(Date.now()),
      userId: req.user.id,
      title,
      content: content || "",
      location: location || null,
      updatedAt: Date.now(),
    };
    notes.push(n);
    await dbWrite();
    return res.status(201).json(n);
  });

  app.put("/notes/:id", authGuard, async (req, res) => {
    const { id } = req.params;
    const idx = notes.findIndex((n) => n.id === id && n.userId === req.user.id);
    if (idx < 0) return res.status(404).json({ message: "Note not found" });

    const { title, content, location } = req.body || {};
    if (!title) return res.status(400).json({ message: "title is required" });

    notes[idx] = {
      ...notes[idx],
      title,
      content: content ?? notes[idx].content,
      location: location ?? notes[idx].location,
      updatedAt: Date.now(),
    };
    await dbWrite();
    return res.json(notes[idx]);
  });

  app.delete("/notes/:id", authGuard, async (req, res) => {
    const { id } = req.params;
    const idx = notes.findIndex((n) => n.id === id && n.userId === req.user.id);
    if (idx < 0) return res.status(404).json({ message: "Note not found" });

    notes.splice(idx, 1);
    await dbWrite();
    return res.sendStatus(204);
  });
}