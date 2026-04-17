import bcrypt from "bcryptjs";
import { users, dbWrite } from "../db.js";
import { signToken } from "../middleware/auth.js";

export function setupAuthRoutes(app) {
  app.post("/auth/register", async (req, res) => {
    const { name, email, password } = req.body || {};
    if (!name || !email || !password) {
      return res
        .status(400)
        .json({ message: "name, email and password are required" });
    }
    const exists = users.find(
      (u) => u.email.toLowerCase() === String(email).toLowerCase()
    );
    if (exists)
      return res.status(409).json({ message: "Email already registered" });

    const passHash = await bcrypt.hash(password, 10);
    const id = String(Date.now());
    users.push({ id, name, email, passHash });
    await dbWrite();
    return res.status(201).json({ id, name, email });
  });

  app.post("/auth/login", async (req, res) => {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res
        .status(400)
        .json({ message: "email and password are required" });
    }
    const user = users.find(
      (u) => u.email.toLowerCase() === String(email).toLowerCase()
    );
    if (!user) return res.status(401).json({ message: "Invalid credentials" });

    const ok = await bcrypt.compare(password, user.passHash);
    if (!ok) return res.status(401).json({ message: "Invalid credentials" });

    const accessToken = signToken(user.id, user.email, user.name);
    return res.json({ accessToken });
  });
}