require("dotenv").config();
const express = require("express");
const multer = require("multer");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const app = express();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 15 * 1024 * 1024 } });
const DIR = path.join(__dirname, "uploads");
fs.mkdirSync(DIR, { recursive: true });

app.get("/api/config", (_req, res) =>
  res.json({
    contract: process.env.CONTRACT_ADDRESS || "",
    rpc: process.env.RPC_URL || "https://api.avax-test.network/ext/bc/C/rpc",
    chainId: 43113,
  })
);

// Guarda el archivo fuera de cadena y devuelve su SHA-256 (0x...) para anclarlo on-chain.
app.post("/api/upload", upload.single("file"), (req, res) => {
  if (!req.file) return res.status(400).json({ error: "Falta el archivo" });
  const hash = "0x" + crypto.createHash("sha256").update(req.file.buffer).digest("hex");
  fs.writeFileSync(path.join(DIR, hash), req.file.buffer);
  fs.writeFileSync(path.join(DIR, hash + ".name"), req.file.originalname);
  res.json({ hash, url: `/files/${hash}` });
});

app.get("/files/:hash", (req, res) => {
  const h = req.params.hash;
  if (!/^0x[0-9a-f]{64}$/.test(h)) return res.sendStatus(400);
  const file = path.join(DIR, h);
  if (!fs.existsSync(file)) return res.sendStatus(404);
  res.download(file, fs.readFileSync(file + ".name", "utf8"));
});

app.get("/verify/:id", (req, res) => res.redirect(`/?id=${encodeURIComponent(req.params.id)}`));
app.use(express.static(path.join(__dirname, "..", "public")));

app.listen(process.env.PORT || 3000, () => console.log("SampleChain en http://localhost:" + (process.env.PORT || 3000)));
