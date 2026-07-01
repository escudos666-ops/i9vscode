const fs = require("fs");
const path = require("path");
const { Pool } = require("pg");

const DATABASE_URL = process.env.DATABASE_URL || "";
const pool = DATABASE_URL
  ? new Pool({
      connectionString: DATABASE_URL,
      ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: false } : false,
    })
  : null;

async function initSchema() {
  if (!pool) {
    return { configured: false, ready: false, message: "DATABASE_URL is not configured" };
  }

  const schemaPath = path.join(__dirname, "schema.sql");
  const schema = fs.readFileSync(schemaPath, "utf8");
  await pool.query(schema);
  return { configured: true, ready: true, message: "database schema ready" };
}

async function query(text, params = []) {
  if (!pool) {
    throw new Error("DATABASE_URL is not configured");
  }
  return pool.query(text, params);
}

async function getDbStatus() {
  if (!pool) {
    return { configured: false, ready: false, message: "DATABASE_URL is not configured" };
  }

  try {
    await pool.query("select 1");
    return { configured: true, ready: true, message: "reachable" };
  } catch (error) {
    return { configured: true, ready: false, message: error.message };
  }
}

module.exports = {
  pool,
  query,
  initSchema,
  getDbStatus,
};
