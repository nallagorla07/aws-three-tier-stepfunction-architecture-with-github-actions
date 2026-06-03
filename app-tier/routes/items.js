"use strict";
const express = require("express");
const pool    = require("../config/db");
const router  = express.Router();

router.get("/",    async (_, res) => {
  const [rows] = await pool.query("SELECT * FROM items ORDER BY id DESC LIMIT 100");
  res.json(rows);
});

router.post("/", async (req, res) => {
  const { name, description } = req.body;
  if (!name) return res.status(400).json({ error: "name required" });
  const [r] = await pool.query("INSERT INTO items (name, description) VALUES (?, ?)", [name, description || ""]);
  res.status(201).json({ id: r.insertId, name, description });
});

router.get("/:id", async (req, res) => {
  const [rows] = await pool.query("SELECT * FROM items WHERE id = ?", [req.params.id]);
  if (!rows.length) return res.status(404).json({ error: "not found" });
  res.json(rows[0]);
});

router.delete("/:id", async (req, res) => {
  await pool.query("DELETE FROM items WHERE id = ?", [req.params.id]);
  res.status(204).end();
});

module.exports = router;
