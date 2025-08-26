const express = require('express');
const app = express();
const brcypt = require('bcrypt');
const conn = require('./db');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));


const PORT = 8000;
app.listen(PORT, () => {
  console.log(`Server is running at ` + PORT);
});

// endpoint for login
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  const sql = 'SELECT id, password FROM users WHERE username = ?';
  conn.query(sql, [username], (err, results) => {
    if (err) {
      return res.status(500).send('Database error');
    }
    if (results.length !== 1) {
      return res.status(401).send('User not found');
    }
    // compare passwords
    brcypt.compare(password, results[0].password, (err, isMatch) => {
      if (err) {
        return res.status(500).send('Hashing error');
      }
      if (isMatch) {
        return res.status(200).json({ userId: results[0].id });
      }
      return res.status(401).send('Wrong password');
    });
  });
})


//endpoint for each userid's expenses
app.get('/expenses/:userId', (req, res) => {
  const userId = req.params.userId;
  const sql = 'SELECT id, item, paid, DATE_FORMAT(date, "%Y-%m-%d %H:%i:%s.000") as date FROM expense WHERE user_id = ?';


  conn.query(sql, [userId], (err, results) => {
    if (err) {
      return res.status(500).send('Database error!');
    }
    res.status(200).json(results);
  });
});


// endpoint for today's user expenses
app.get('/expenses/:userId/today', (req, res) => {
  const userId = req.params.userId;
  const sql = 'SELECT id, item, paid, DATE_FORMAT(date, "%Y-%m-%d %H:%i:%s.000") as date FROM expense WHERE user_id = ? AND DATE(date) = CURDATE()';

  conn.query(sql, [userId], (err, results) => {
    if (err) {
      return res.status(500).send('Database error!');
    }
    res.status(200).json(results);
  });
})

// endpoint for Search expenses by item name
app.get('/expenses/:userId/search', (req, res) => {
  const userId = req.params.userId;
  const q = (req.query.q || req.query.keyword || '').trim();
  if (!q) return res.status(400).send('Missing search keyword');

  const like = `%${q}%`;
  const sql = `
    SELECT id, item, paid,
           DATE_FORMAT(date, "%Y-%m-%d %H:%i:%s.000") AS date
    FROM expense
    WHERE user_id = ? AND item LIKE ?
    ORDER BY date DESC
  `;
  conn.query(sql, [userId, like], (err, results) => {
    if (err) return res.status(500).send('Database error!');
    if (!results.length) {
      // ให้ข้อความตามที่โจทย์ต้องการ
      return res.status(404).send('No item containing that searching keyword.');
    }
    res.status(200).json(results);
  });
});










// endponint for add new expense
app.post('/expenses', (req, res) => {
  const { item, paid, user_id } = req.body;

  // validate เบื้องต้น
  if (!item || item.trim() === '' || paid === undefined || user_id === undefined) {
    return res.status(400).send('Missing required fields (item, paid, user_id)');
  }

  const sql = 'INSERT INTO expense (item, paid, date, user_id) VALUES (?, ?, NOW(), ?)';
  conn.query(sql, [item.trim(), Number(paid), Number(user_id)], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).send('Database error!');
    }
    // ส่งข้อมูลรายการที่เพิ่งสร้างกลับไป
    res.status(201).json({
      id: result.insertId,
      item: item.trim(),
      paid: Number(paid),
      user_id: Number(user_id),
      // ให้รูปแบบเวลา ISO (ฝั่ง Dart แปลงได้)
      date: new Date().toISOString()
    });
  });
});

// DELETE EXPENSE 
app.delete('/expenses/:userId/:expenseId', (req, res) => {
  const { userId, expenseId } = req.params;
  const sql = 'DELETE FROM expense WHERE user_id = ? AND id = ?';
  conn.query(sql, [userId, expenseId], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (result.affectedRows === 0) return res.status(404).send('Not found');
    return res.status(204).send();
  });
});

