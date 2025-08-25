const express = require('express');
const app = express();
const conn = require('./db');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/expense', (req, res) => {
  const sql = 'SELECT * FROM expenses';
  conn.query(sql, (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
}); 

const PORT = 8000;
app.listen(PORT, () => {
  console.log(`Server is running at ` + PORT);
});