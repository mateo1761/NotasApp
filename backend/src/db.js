import { Low } from "lowdb";
import { JSONFile } from "lowdb/node";

const adapter = new JSONFile("db.json");
const db = new Low(adapter, { users: [], notes: [] });

await db.read();
db.data ||= { users: [], notes: [] };

export const { users, notes } = db.data;
export const dbWrite = () => db.write();