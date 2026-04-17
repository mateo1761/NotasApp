import jwt from "jsonwebtoken";
import { config } from "../config.js";

export function signToken(userId, email, name) {
  return jwt.sign({ sub: userId, email, name }, config.jwtSecret, {
    expiresIn: config.jwtExpiresIn,
  });
}

export function authGuard(req, res, next) {
  const auth = req.headers.authorization || "";
  const [type, token] = auth.split(" ");
  if (type !== "Bearer" || !token) {
    return res
      .status(401)
      .json({ message: "Missing or invalid Authorization header" });
  }
  try {
    const payload = jwt.verify(token, config.jwtSecret);
    req.user = { id: payload.sub, email: payload.email };
    next();
  } catch {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
}