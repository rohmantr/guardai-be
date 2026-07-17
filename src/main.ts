import express from "express";

const app = express();
const port = process.env.PORT ?? 3000;

app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    service: "guardai-be",
    timestamp: new Date().toISOString(),
  });
});

app.listen(port, () => {
  console.log(`guardai-be running on http://localhost:${port}`);
});
