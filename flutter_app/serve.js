const express = require('express');
const path = require('path');

const app = express();
const PORT = 8080;

// Serve static files from build/web
app.use(express.static(path.join(__dirname, 'build', 'web')));

// Handle all routes by serving index.html (for Flutter routing)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'web', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Flutter web app running at http://localhost:${PORT}`);
  console.log(`Also accessible at:`);
  console.log(`  http://127.0.0.1:${PORT}`);
  console.log(`  http://192.168.0.214:${PORT}`);
});
