// Models/ChatMessage.js
const pool = require('../config/db');

class ChatMessage {
    // Create a new chat message
    static async createMessage(sender_id, receiver_id, consultation_id, message_text) {
        try {
            const result = await pool.query(
                `INSERT INTO chat_messages (sender_id, receiver_id, consultation_id, message_text, created_at)
                 VALUES ($1, $2, $3, $4, NOW())
                 RETURNING *`,
                [sender_id, receiver_id, consultation_id, message_text]
            );
            return result.rows[0];
        } catch (error) {
            console.error('Error creating chat message:', error);
            throw error;
        }
    }

    // Get all messages for a consultation
    static async getConsultationMessages(consultation_id) {
        try {
            const result = await pool.query(
                `SELECT 
                    cm.*,
                    u.full_name as sender_name
                 FROM 
                    chat_messages cm
                 JOIN
                    users u ON cm.sender_id = u.id
                 WHERE 
                    cm.consultation_id = $1
                 ORDER BY 
                    cm.created_at ASC`,
                [consultation_id]
            );
            return result.rows;
        } catch (error) {
            console.error('Error getting consultation messages:', error);
            throw error;
        }
    }

    // Get unread message count for a user
    static async getUnreadCount(user_id) {
        try {
            const result = await pool.query(
                `SELECT COUNT(*) as unread_count
                 FROM chat_messages
                 WHERE 
                    receiver_id = $1 AND 
                    is_read = false`,
                [user_id]
            );
            return parseInt(result.rows[0].unread_count);
        } catch (error) {
            console.error('Error getting unread count:', error);
            throw error;
        }
    }

    // Mark messages as read
    static async markAsRead(receiver_id, consultation_id) {
        try {
            const result = await pool.query(
                `UPDATE chat_messages
                 SET is_read = true
                 WHERE 
                    receiver_id = $1 AND 
                    consultation_id = $2 AND
                    is_read = false
                 RETURNING *`,
                [receiver_id, consultation_id]
            );
            return result.rows;
        } catch (error) {
            console.error('Error marking messages as read:', error);
            throw error;
        }
    }
}

module.exports = ChatMessage;