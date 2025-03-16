// models/User.js
const db = require('../config/db');

class User {
    static async getUserByEmail(email) {
        try {
            const query = 'SELECT * FROM users WHERE email = $1';
            const { rows } = await db.query(query, [email]);
            return rows[0];
        } catch (error) {
            throw error;
        }
    }
    
    static async getUserById(id) {
        try {
            const query = 'SELECT * FROM users WHERE id = $1';
            const { rows } = await db.query(query, [id]);
            return rows[0];
        } catch (error) {
            throw error;
        }
    }
    
    static async createUser({ full_name, email, password, role }) {
        try {
            const query = `
                INSERT INTO users (full_name, email, password, role, created_at) 
                VALUES ($1, $2, $3, $4, NOW()) 
                RETURNING id, full_name, email, role
            `;
            const values = [full_name, email, password, role];
            const { rows } = await db.query(query, values);
            return rows[0];
        } catch (error) {
            throw error;
        }
    }
    
    static async updateUser(id, { full_name, email }) {
        try {
            let updateQuery = 'UPDATE users SET ';
            const updateValues = [];
            const updateFields = [];
            
            if (full_name) {
                updateFields.push(`full_name = $${updateValues.length + 1}`);
                updateValues.push(full_name);
            }
            
            if (email) {
                updateFields.push(`email = $${updateValues.length + 1}`);
                updateValues.push(email);
            }
            
            updateFields.push(`updated_at = NOW()`);
            
            updateQuery += updateFields.join(', ') + ` WHERE id = $${updateValues.length + 1} RETURNING id, full_name, email, role`;
            updateValues.push(id);
            
            const { rows } = await db.query(updateQuery, updateValues);
            return rows[0];
        } catch (error) {
            throw error;
        }
    }
    
    static async updatePassword(id, hashedPassword) {
        try {
            const query = 'UPDATE users SET password = $1, updated_at = NOW() WHERE id = $2';
            await db.query(query, [hashedPassword, id]);
            return true;
        } catch (error) {
            throw error;
        }
    }
    
    static async deleteUser(id) {
        try {
            const query = 'DELETE FROM users WHERE id = $1';
            await db.query(query, [id]);
            return true;
        } catch (error) {
            throw error;
        }
    }
}

module.exports = User;