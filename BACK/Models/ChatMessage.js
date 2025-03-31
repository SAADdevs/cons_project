// models/ChatMessage.js
const pool = require('../config/db');

class ChatMessage {
    // Create a new chat message
    static async createMessage(sender_id, receiver_id, consultation_id, message_text, media_url = null, message_type = 'text') {
        try {
            const result = await pool.query(
                `INSERT INTO chat_messages 
                    (sender_id, receiver_id, consultation_id, message_text, media_url, message_type, created_at)
                 VALUES 
                    ($1, $2, $3, $4, $5, $6, NOW())
                 RETURNING *`,
                [sender_id, receiver_id, consultation_id, message_text, media_url, message_type]
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
                    u.full_name as sender_name,
                    ur.full_name as receiver_name
                 FROM 
                    chat_messages cm
                 JOIN
                    users u ON cm.sender_id = u.id
                 JOIN
                    users ur ON cm.receiver_id = ur.id
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

    // Get messages between two users for a specific consultation
    static async getMessagesBetweenUsers(user1_id, user2_id, consultation_id) {
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
                    cm.consultation_id = $1 AND
                    ((cm.sender_id = $2 AND cm.receiver_id = $3) OR
                     (cm.sender_id = $3 AND cm.receiver_id = $2))
                 ORDER BY 
                    cm.created_at ASC`,
                [consultation_id, user1_id, user2_id]
            );
            return result.rows;
        } catch (error) {
            console.error('Error getting messages between users:', error);
            throw error;
        }
    }

    // Delete a message (for privacy or compliance purposes)
    static async deleteMessage(message_id, user_id) {
        try {
            // Only allow the sender to delete their message
            const result = await pool.query(
                `DELETE FROM chat_messages
                 WHERE 
                    id = $1 AND 
                    sender_id = $2
                 RETURNING *`,
                [message_id, user_id]
            );
            return result.rows[0];
        } catch (error) {
            console.error('Error deleting message:', error);
            throw error;
        }
    }

    // Search messages (for patient or doctor to find information)
    static async searchMessages(user_id, search_query) {
        try {
            const result = await pool.query(
                `SELECT 
                    cm.*,
                    u.full_name as sender_name,
                    c.status as consultation_status
                 FROM 
                    chat_messages cm
                 JOIN
                    users u ON cm.sender_id = u.id
                 JOIN
                    consultations c ON cm.consultation_id = c.id
                 WHERE 
                    (cm.sender_id = $1 OR cm.receiver_id = $1) AND
                    cm.message_text ILIKE $2
                 ORDER BY 
                    cm.created_at DESC`,
                [user_id, `%${search_query}%`]
            );
            return result.rows;
        } catch (error) {
            console.error('Error searching messages:', error);
            throw error;
        }
    }
}

module.exports = ChatMessage;