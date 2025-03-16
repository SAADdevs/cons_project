const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD || "",
  port: process.env.DB_PORT,
});

const testDBConnection = async () => {
  try {
    const res = await pool.query("SELECT NOW()");
    console.log("✅ PostgreSQL Connected! Current Time:", res.rows[0].now);
  } catch (error) {
    console.error("❌ Database connection failed:", error);
  }
};

testDBConnection(); 

module.exports = pool; 
