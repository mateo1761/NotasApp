import express from 'express';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

// lowdb (persistencia en archivo)
import { Low } from 'lowdb';
import { JSONFile } from 'lowdb/node';

const app = express();
const PORT = process.env.PORT || 3000;

// === DB (lowdb) ===
const adapter = new JSONFile('db.json');
const db = new Low(adapter, { users: [], notes: [] });
await db.read();
db.data ||= { users: [], notes: [] };
const { users, notes } = db.data; // arrays persistentes

// === Config básica ===
app.use(cors());
app.use(express.json());

// === JWT ===
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';
const JWT_EXPIRES_IN = '7d';

function signToken(userId, email) {
  return jwt.sign({ sub: userId, email }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

function authGuard(req, res, next) {
  const auth = req.headers.authorization || '';
  const [type, token] = auth.split(' ');
  if (type !== 'Bearer' || !token) {
    return res.status(401).json({ message: 'Missing or invalid Authorization header' });
  }
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = { id: payload.sub, email: payload.email };
    next();
  } catch {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

// === Health ===
app.get('/health', (req, res) => res.json({ status: 'ok', time: Date.now() }));

// === Auth ===
app.post('/auth/register', async (req, res) => {
  const { name, email, password } = req.body || {};
  if (!name || !email || !password) {
    return res.status(400).json({ message: 'name, email and password are required' });
  }
  const exists = users.find(u => u.email.toLowerCase() === String(email).toLowerCase());
  if (exists) return res.status(409).json({ message: 'Email already registered' });

  const passHash = await bcrypt.hash(password, 10);
  const id = String(Date.now());
  users.push({ id, name, email, passHash });
  await db.write(); 
  return res.status(201).json({ id, name, email });
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ message: 'email and password are required' });
  }
  const user = users.find(u => u.email.toLowerCase() === String(email).toLowerCase());
  if (!user) return res.status(401).json({ message: 'Invalid credentials' });

  const ok = await bcrypt.compare(password, user.passHash);
  if (!ok) return res.status(401).json({ message: 'Invalid credentials' });

  const accessToken = signToken(user.id, user.email);
  return res.json({ accessToken });
});

// === Notas (protegidas) ===
app.get('/notes', authGuard, async (req, res) => {
  const userNotes = notes
    .filter(n => n.userId === req.user.id)
    .sort((a, b) => b.updatedAt - a.updatedAt);
  return res.json(userNotes);
});

app.post('/notes', authGuard, async (req, res) => {
  const { title, content } = req.body || {};
  if (!title) return res.status(400).json({ message: 'title is required' });

  const n = {
    id: String(Date.now()),
    userId: req.user.id,
    title,
    content: content || '',
    updatedAt: Date.now()
  };
  notes.push(n);
  await db.write(); 
  return res.status(201).json(n);
});

app.put('/notes/:id', authGuard, async (req, res) => {
  const { id } = req.params;
  const idx = notes.findIndex(n => n.id === id && n.userId === req.user.id);
  if (idx < 0) return res.status(404).json({ message: 'Note not found' });

  const { title, content } = req.body || {};
  if (!title) return res.status(400).json({ message: 'title is required' });

  notes[idx] = {
    ...notes[idx],
    title,
    content: content ?? notes[idx].content,
    updatedAt: Date.now()
  };
  await db.write(); 
  return res.json(notes[idx]);
});

app.delete('/notes/:id', authGuard, async (req, res) => {
  const { id } = req.params;
  const idx = notes.findIndex(n => n.id === id && n.userId === req.user.id);
  if (idx < 0) return res.status(404).json({ message: 'Note not found' });

  notes.splice(idx, 1);
  await db.write();
  return res.sendStatus(204);
});

// === Arrancar server ===
app.listen(PORT, () => {
  console.log(`API listening on http://localhost:${PORT}`);
});
