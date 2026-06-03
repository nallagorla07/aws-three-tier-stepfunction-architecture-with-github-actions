"use strict";

const express = require("express");
const mysql   = require("mysql2/promise");
const morgan  = require("morgan");

const app  = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());
app.use(morgan("combined"));

// ── DB connection pool ────────────────────────────────────────────────────────
const pool = mysql.createPool({
  host:     process.env.DB_HOST,
  user:     process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit:    10,
});

// ── Health check ──────────────────────────────────────────────────────────────
app.get("/health", async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ status: "ok", db: "connected" });
  } catch (err) {
    res.status(500).json({ status: "error", message: err.message });
  }
});

// ── Items CRUD ────────────────────────────────────────────────────────────────
app.get("/api/items", async (_req, res) => {
  const [rows] = await pool.query("SELECT * FROM items ORDER BY id DESC LIMIT 100");
  res.json(rows);
});

app.post("/api/items", async (req, res) => {
  const { name, description } = req.body;
  if (!name) return res.status(400).json({ error: "name is required" });
  const [result] = await pool.query(
    "INSERT INTO items (name, description) VALUES (?, ?)",
    [name, description || ""]
  );
  res.status(201).json({ id: result.insertId, name, description });
});

app.get("/api/items/:id", async (req, res) => {
  const [rows] = await pool.query("SELECT * FROM items WHERE id = ?", [req.params.id]);
  if (!rows.length) return res.status(404).json({ error: "not found" });
  res.json(rows[0]);
});

app.delete("/api/items/:id", async (req, res) => {
  await pool.query("DELETE FROM items WHERE id = ?", [req.params.id]);
  res.status(204).end();
});

app.listen(PORT, () => console.log(`App server listening on port ${PORT}`));
