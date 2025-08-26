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
  const sql = 'SELECT item, paid, DATE_FORMAT(date, "%Y-%m-%d %H:%i:%s.000") as date FROM expense WHERE user_id = ?';


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
  const sql = 'SELECT item, paid, DATE_FORMAT(date, "%Y-%m-%d %H:%i:%s.000") as date FROM expense WHERE user_id = ? AND DATE(date) = CURDATE()';

  conn.query(sql, [userId], (err, results) => {
    if (err) {
      return res.status(500).send('Database error!');
    }
    res.status(200).json(results);
  });
})

// endpoint for Search expenses by item name











// endponint for add new expense













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