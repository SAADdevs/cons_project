// models/ChatMessage.js
const pool = require('../config/db');

class ChatMessage {
    // Create a new chat message
    static async createMessage(patient_id, doctor_id, consultation_id, message_text, media_url = null, message_type = 'text') {
        try {
            const result = await pool.query(
                `INSERT INTO chat_messages 
                    (patient_id, doctor_id, consultation_id, message_text, media_url, message_type, created_at, is_read)
                 VALUES 
                    ($1, $2, $3, $4, $5, $6, NOW(), false)
                 RETURNING *`,
                [patient_id, doctor_id, consultation_id, message_text, media_url, message_type]
            );
            return result.rows[0];
        } catch (error) {
            console.error('Error creating chat message:', error);
            throw error;
        }
    }

    // Get all messages for a consultation
    static async getConsultationMessages(consultationId) {
        return await db.query(`
          SELECT 
            m.id,
            m.consultation_id,
            m.message_text,
            m.media_url,
            m.message_type,
            m.is_read,
            m.created_at,
            m.is_from_doctor,
            CASE
              WHEN m.is_from_doctor THEN d.email
              ELSE p.email
            END as sender_name,
            CASE
              WHEN m.is_from_doctor THEN 'Doctor'
              ELSE 'Patient'
            END as sender_role
          FROM 
            messages m
          LEFT JOIN consultations c ON m.consultation_id = c.id
          LEFT JOIN users p ON c.patient_id = p.id
          LEFT JOIN users d ON c.doctor_id = d.id
          WHERE 
            m.consultation_id = $1
          ORDER BY 
            m.created_at ASC
        `, [consultationId]);
      }

    // Get unread message count for a user
   // Replace the existing getUnreadCount method in ChatMessage.js with this updated version
static async getUnreadCount(user_id) {
    try {
        // Get user role first to determine if patient or doctor
        const userRoleResult = await pool.query(
            `SELECT role FROM users WHERE id = $1`,
            [user_id]
        );
        
        if (userRoleResult.rows.length === 0) {
            throw new Error('User not found');
        }
        
        const userRole = userRoleResult.rows[0].role;
        
        // Then get unread count based on role
        let result;
        if (userRole === 'patient') {
            // Get patient ID
            const patientResult = await pool.query(
                `SELECT id FROM patients WHERE user_id = $1`,
                [user_id]
            );
            
            if (patientResult.rows.length === 0) {
                throw new Error('Patient not found for this user');
            }
            
            const patientId = patientResult.rows[0].id;
            
            // Get unread count for patient (messages TO patient)
            result = await pool.query(
                `SELECT COUNT(*) as unread_count
                 FROM chat_messages
                 WHERE 
                    patient_id = $1 AND 
                    is_read = false`,
                [patientId]
            );
        } else if (userRole === 'doctor') {
            // Get doctor ID
            const doctorResult = await pool.query(
                `SELECT id FROM doctors WHERE user_id = $1`,
                [user_id]
            );
            
            if (doctorResult.rows.length === 0) {
                throw new Error('Doctor not found for this user');
            }
            
            const doctorId = doctorResult.rows[0].id;
            
            // Get unread count for doctor (messages TO doctor)
            result = await pool.query(
                `SELECT COUNT(*) as unread_count
                 FROM chat_messages
                 WHERE 
                    doctor_id = $1 AND 
                    is_read = false`,
                [doctorId]
            );
        } else {
            throw new Error('Invalid user role');
        }
        
        return parseInt(result.rows[0].unread_count);
    } catch (error) {
        console.error('Error getting unread count:', error);
        throw error;
    }
}

    // Get unread message count for a user in a specific consultation
        static async getUnreadCountForConsultation(user_id, consultation_id) {
            try {
                // Get user role first to determine if patient or doctor
                const userRoleResult = await pool.query(
                    `SELECT role FROM users WHERE id = $1`,
                    [user_id]
                );
                
                if (userRoleResult.rows.length === 0) {
                    throw new Error('User not found');
                }
                
                const userRole = userRoleResult.rows[0].role;
                
                // Then get unread count based on role
                let result;
                if (userRole === 'patient') {
                    // Get patient ID
                    const patientResult = await pool.query(
                        `SELECT id FROM patients WHERE user_id = $1`,
                        [user_id]
                    );
                    
                    if (patientResult.rows.length === 0) {
                        throw new Error('Patient not found for this user');
                    }
                    
                    const patientId = patientResult.rows[0].id;
                    
                    // Get unread count for patient in this consultation
                    result = await pool.query(
                        `SELECT COUNT(*) as unread_count
                        FROM chat_messages
                        WHERE 
                            patient_id = $1 AND 
                            consultation_id = $2 AND
                            is_from_doctor = true AND
                            is_read = false`,
                        [patientId, consultation_id]
                    );
                } else if (userRole === 'doctor') {
                    // Get doctor ID
                    const doctorResult = await pool.query(
                        `SELECT id FROM doctors WHERE user_id = $1`,
                        [user_id]
                    );
                    
                    if (doctorResult.rows.length === 0) {
                        throw new Error('Doctor not found for this user');
                    }
                    
                    const doctorId = doctorResult.rows[0].id;
                    
                    // Get unread count for doctor in this consultation
                    result = await pool.query(
                        `SELECT COUNT(*) as unread_count
                        FROM chat_messages
                        WHERE 
                            doctor_id = $1 AND 
                            consultation_id = $2 AND
                            is_from_doctor = false AND
                            is_read = false`,
                        [doctorId, consultation_id]
                    );
                } else {
                    throw new Error('Invalid user role');
                }
                
                return parseInt(result.rows[0].unread_count);
            } catch (error) {
                console.error('Error getting unread count for consultation:', error);
                throw error;
            }
        }

    // Mark messages as read
    // Replace the markMessagesAsRead method in ChatController.js with this updated version
static async markMessagesAsRead(req, res) {
    try {
        const { user_id, consultation_id } = req.body;
        
        // Debug log
        console.log(`Mark messages as read for User ID: ${user_id}, Consultation ID: ${consultation_id}`);

        if (!user_id || !consultation_id) {
            return res.status(400).json({ message: "User ID and Consultation ID are required" });
        }

        const updatedMessages = await ChatMessage.markAsRead(user_id, consultation_id);

        // Emit through socket if available
        if (req.io) {
            const consultation = await Consultation.getById(consultation_id);
            if (consultation) {
                // Determine the other user ID based on the requesting user
                const user = await User.getUserById(user_id);
                if (user) {
                    let otherUserId = null;
                    
                    if (user.role === 'patient') {
                        // For a patient, get the doctor's user ID directly
                        // This assumes you have a direct way to get the doctor's userId
                        const doctorQuery = await pool.query(
                            `SELECT u.id 
                             FROM users u
                             JOIN doctors d ON u.id = d.user_id
                             WHERE d.id = $1`,
                            [consultation.doctor_id]
                        );
                        
                        if (doctorQuery.rows.length > 0) {
                            otherUserId = doctorQuery.rows[0].id;
                        }
                    } else {
                        // For a doctor, get the patient's user ID directly
                        const patientQuery = await pool.query(
                            `SELECT u.id 
                             FROM users u
                             JOIN patients p ON u.id = p.user_id
                             WHERE p.id = $1`,
                            [consultation.patient_id]
                        );
                        
                        if (patientQuery.rows.length > 0) {
                            otherUserId = patientQuery.rows[0].id;
                        }
                    }

                    if (otherUserId) {
                        req.io.to(`user_${otherUserId}`).emit('messages_read', {
                            consultation_id,
                            user_id,
                            count: updatedMessages.length
                        });
                    }
                }
            }
        }

        res.status(200).json({
            message: `${updatedMessages.length} messages marked as read`,
            updated_messages: updatedMessages
        });
    } catch (error) {
        console.error('Error marking messages as read:', error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
}
    // Replace the existing markAsRead method in ChatMessage.js with this updated version
static async markAsRead(user_id, consultation_id) {
    try {
        // Get user role first to determine if patient or doctor
        const userRoleResult = await pool.query(
            `SELECT role FROM users WHERE id = $1`,
            [user_id]
        );
        
        if (userRoleResult.rows.length === 0) {
            throw new Error('User not found');
        }
        
        const userRole = userRoleResult.rows[0].role;
        
        // Mark messages as read based on role
        let result;
        if (userRole === 'patient') {
            // Get patient ID
            const patientResult = await pool.query(
                `SELECT id FROM patients WHERE user_id = $1`,
                [user_id]
            );
            
            if (patientResult.rows.length === 0) {
                throw new Error('Patient not found for this user');
            }
            
            const patientId = patientResult.rows[0].id;
            
            // Mark messages as read for patient (messages FROM doctor TO patient)
            result = await pool.query(
                `UPDATE chat_messages
                 SET is_read = true
                 WHERE 
                    patient_id = $1 AND 
                    consultation_id = $2 AND
                    is_read = false
                 RETURNING *`,
                [patientId, consultation_id]
            );
        } else if (userRole === 'doctor') {
            // Get doctor ID
            const doctorResult = await pool.query(
                `SELECT id FROM doctors WHERE user_id = $1`,
                [user_id]
            );
            
            if (doctorResult.rows.length === 0) {
                throw new Error('Doctor not found for this user');
            }
            
            const doctorId = doctorResult.rows[0].id;
            
            // Mark messages as read for doctor (messages FROM patient TO doctor)
            result = await pool.query(
                `UPDATE chat_messages
                 SET is_read = true
                 WHERE 
                    doctor_id = $1 AND 
                    consultation_id = $2 AND
                    is_read = false
                 RETURNING *`,
                [doctorId, consultation_id]
            );
        } else {
            throw new Error('Invalid user role');
        }
        
        return result.rows;
    } catch (error) {
        console.error('Error marking messages as read:', error);
        throw error;
    }
}
    // Delete a message
    static async deleteMessage(message_id, user_id) {
        try {
            // Get user role and ID first
            const userRoleResult = await pool.query(
                `SELECT role FROM users WHERE id = $1`,
                [user_id]
            );
            
            if (userRoleResult.rows.length === 0) {
                throw new Error('User not found');
            }
            
            const userRole = userRoleResult.rows[0].role;
            
            // Check if the user has permission to delete this message
            let result;
            if (userRole === 'patient') {
                // Get patient ID
                const patientResult = await pool.query(
                    `SELECT id FROM patients WHERE user_id = $1`,
                    [user_id]
                );
                
                if (patientResult.rows.length === 0) {
                    throw new Error('Patient not found for this user');
                }
                
                const patientId = patientResult.rows[0].id;
                
                // Delete message if it belongs to this patient and was sent by them
                result = await pool.query(
                    `DELETE FROM chat_messages
                     WHERE 
                        id = $1 AND 
                        patient_id = $2 AND
                        is_from_doctor = false
                     RETURNING *`,
                    [message_id, patientId]
                );
            } else if (userRole === 'doctor') {
                // Get doctor ID
                const doctorResult = await pool.query(
                    `SELECT id FROM doctors WHERE user_id = $1`,
                    [user_id]
                );
                
                if (doctorResult.rows.length === 0) {
                    throw new Error('Doctor not found for this user');
                }
                
                const doctorId = doctorResult.rows[0].id;
                
                // Delete message if it belongs to this doctor and was sent by them
                result = await pool.query(
                    `DELETE FROM chat_messages
                     WHERE 
                        id = $1 AND 
                        doctor_id = $2 AND
                        is_from_doctor = true
                     RETURNING *`,
                    [message_id, doctorId]
                );
            } else {
                throw new Error('Invalid user role');
            }
            
            return result.rows[0];
        } catch (error) {
            console.error('Error deleting message:', error);
            throw error;
        }
    }

    // Get message by ID
    static async getById(id) {
        try {
            const result = await pool.query(
                `SELECT * FROM chat_messages WHERE id = $1`,
                [id]
            );
            return result.rows[0];
        } catch (error) {
            console.error('Error getting chat message by ID:', error);
            throw error;
        }
    }

    static async searchMessages(user_id, query) {
        try {
            // Get user role first to determine if patient or doctor
            const userRoleResult = await pool.query(
                `SELECT role FROM users WHERE id = $1`,
                [user_id]
            );
            
            if (userRoleResult.rows.length === 0) {
                throw new Error('User not found');
            }
            
            const userRole = userRoleResult.rows[0].role;
            
            // Then search messages based on role
            let result;
            if (userRole === 'patient') {
                // Get patient ID
                const patientResult = await pool.query(
                    `SELECT id FROM patients WHERE user_id = $1`,
                    [user_id]
                );
                
                if (patientResult.rows.length === 0) {
                    throw new Error('Patient not found for this user');
                }
                
                const patientId = patientResult.rows[0].id;
                
                // Search messages for patient
                result = await pool.query(
                    `SELECT 
                        cm.*,
                        c.status as consultation_status,
                        p.full_name as patient_name,
                        d.full_name as doctor_name
                    FROM 
                        chat_messages cm
                    JOIN
                        consultations c ON cm.consultation_id = c.id
                    JOIN
                        (SELECT u.id, u.full_name FROM users u JOIN patients p ON u.id = p.user_id) p ON cm.patient_id = p.id
                    JOIN
                        (SELECT u.id, u.full_name FROM users u JOIN doctors d ON u.id = d.user_id) d ON cm.doctor_id = d.id
                    WHERE 
                        cm.patient_id = $1 AND
                        cm.message_text ILIKE $2
                    ORDER BY 
                        cm.created_at DESC`,
                    [patientId, `%${query}%`]
                );
            } else if (userRole === 'doctor') {
                // Get doctor ID
                const doctorResult = await pool.query(
                    `SELECT id FROM doctors WHERE user_id = $1`,
                    [user_id]
                );
                
                if (doctorResult.rows.length === 0) {
                    throw new Error('Doctor not found for this user');
                }
                
                const doctorId = doctorResult.rows[0].id;
                
                // Search messages for doctor
                result = await pool.query(
                    `SELECT 
                        cm.*,
                        c.status as consultation_status,
                        p.full_name as patient_name,
                        d.full_name as doctor_name
                    FROM 
                        chat_messages cm
                    JOIN
                        consultations c ON cm.consultation_id = c.id
                    JOIN
                        (SELECT u.id, u.full_name FROM users u JOIN patients p ON u.id = p.user_id) p ON cm.patient_id = p.id
                    JOIN
                        (SELECT u.id, u.full_name FROM users u JOIN doctors d ON u.id = d.user_id) d ON cm.doctor_id = d.id
                    WHERE 
                        cm.doctor_id = $1 AND
                        cm.message_text ILIKE $2
                    ORDER BY 
                        cm.created_at DESC`,
                    [doctorId, `%${query}%`]
                );
            } else {
                throw new Error('Invalid user role');
            }
            
            // Transform to the format frontend expects
            const messages = result.rows.map(msg => ({
                ...msg,
                sender_id: msg.is_from_doctor ? msg.doctor_id : msg.patient_id,
                receiver_id: msg.is_from_doctor ? msg.patient_id : msg.doctor_id,
                sender_name: msg.is_from_doctor ? msg.doctor_name : msg.patient_name,
                receiver_name: msg.is_from_doctor ? msg.patient_name : msg.doctor_name
            }));
            
            return messages;
        } catch (error) {
            console.error('Error searching messages:', error);
            throw error;
        }
    }

    // Replace the existing createMessage method with this updated version
static async createMessage(patient_id, doctor_id, consultation_id, message_text, media_url = null, message_type = 'text', is_from_doctor = false) {
    try {
        const result = await pool.query(
            `INSERT INTO chat_messages 
                (patient_id, doctor_id, consultation_id, message_text, media_url, message_type, created_at, is_read, is_from_doctor)
             VALUES 
                ($1, $2, $3, $4, $5, $6, NOW(), false, $7)
             RETURNING *`,
            [patient_id, doctor_id, consultation_id, message_text, media_url, message_type, is_from_doctor]
        );
        return result.rows[0];
    } catch (error) {
        console.error('Error creating chat message:', error);
        throw error;
    }
}

// Additional static methods for ChatMessage model

// Get paginated consultation messages
static async getPaginatedConsultationMessages(consultation_id, limit, offset) {
    try {
        // First, get total count of messages
        const countResult = await pool.query(
            `SELECT COUNT(*) as total 
             FROM chat_messages 
             WHERE consultation_id = $1`,
            [consultation_id]
        );
        const total = parseInt(countResult.rows[0].total);

        // Then, get paginated messages with sender/receiver details
        const result = await pool.query(
            `SELECT 
                cm.*,
                p.full_name as patient_name,
                d.full_name as doctor_name
             FROM 
                chat_messages cm
             JOIN
                (SELECT u.id, u.full_name FROM users u JOIN patients p ON u.id = p.user_id) p ON cm.patient_id = p.id
             JOIN
                (SELECT u.id, u.full_name FROM users u JOIN doctors d ON u.id = d.user_id) d ON cm.doctor_id = d.id
             WHERE 
                cm.consultation_id = $1
             ORDER BY 
                cm.created_at ASC
             LIMIT $2 OFFSET $3`,
            [consultation_id, limit, offset]
        );
        
        // Transform to the format frontend expects
        const messages = result.rows.map(msg => ({
            ...msg,
            sender_id: msg.is_from_doctor ? msg.doctor_id : msg.patient_id,
            receiver_id: msg.is_from_doctor ? msg.patient_id : msg.doctor_id,
            sender_name: msg.is_from_doctor ? msg.doctor_name : msg.patient_name,
            receiver_name: msg.is_from_doctor ? msg.patient_name : msg.doctor_name
        }));
        
        return { messages, total };
    } catch (error) {
        console.error('Error getting paginated consultation messages:', error);
        throw error;
    }
}

// Export consultation chat history
static async exportConsultationChat(consultation_id, user_id) {
    try {
        // Get all messages for the consultation
        const result = await pool.query(
            `SELECT 
                cm.*,
                p.full_name as patient_name,
                d.full_name as doctor_name
             FROM 
                chat_messages cm
             JOIN
                consultations c ON cm.consultation_id = c.id
             JOIN
                (SELECT u.id, u.full_name FROM users u JOIN patients p ON u.id = p.user_id) p ON cm.patient_id = p.id
             JOIN
                (SELECT u.id, u.full_name FROM users u JOIN doctors d ON u.id = d.user_id) d ON cm.doctor_id = d.id
             WHERE 
                cm.consultation_id = $1
             ORDER BY 
                cm.created_at ASC`,
            [consultation_id]
        );
        
        // Transform to exportable format
        const exportData = {
            consultation_id,
            exported_at: new Date().toISOString(),
            exported_by: user_id,
            messages: result.rows.map(msg => ({
                id: msg.id,
                sender_id: msg.is_from_doctor ? msg.doctor_id : msg.patient_id,
                sender_name: msg.is_from_doctor ? msg.doctor_name : msg.patient_name,
                message_text: msg.message_text,
                message_type: msg.message_type,
                media_url: msg.media_url,
                created_at: msg.created_at,
                is_from_doctor: msg.is_from_doctor
            }))
        };
        
        return exportData;
    } catch (error) {
        console.error('Error exporting consultation chat:', error);
        throw error;
    }
}

// Import consultation chat history
static async importConsultationChat(consultation_id, user_id, chat_history) {
    try {
        // Begin transaction
        const client = await pool.connect();
        
        try {
            await client.query('BEGIN');
            
            const importedMessages = [];
            
            // Insert each message from the imported history
            for (const msg of chat_history.messages) {
                const result = await client.query(
                    `INSERT INTO chat_messages 
                        (consultation_id, patient_id, doctor_id, message_text, 
                         message_type, media_url, created_at, is_read, is_from_doctor)
                     VALUES 
                        ($1, $2, $3, $4, $5, $6, $7, true, $8)
                     RETURNING *`,
                    [
                        consultation_id,
                        msg.is_from_doctor ? msg.sender_id : msg.sender_id,
                        msg.is_from_doctor ? msg.sender_id : msg.sender_id,
                        msg.message_text,
                        msg.message_type || 'text',
                        msg.media_url || null,
                        msg.created_at || new Date().toISOString(),
                        msg.is_from_doctor
                    ]
                );
                
                importedMessages.push(result.rows[0]);
            }
            
            // Commit transaction
            await client.query('COMMIT');
            
            return importedMessages;
        } catch (insertError) {
            // Rollback transaction in case of error
            await client.query('ROLLBACK');
            throw insertError;
        } finally {
            // Release the client back to the pool
            client.release();
        }
    } catch (error) {
        console.error('Error importing consultation chat:', error);
        throw error;
    }
}

// Clear consultation chat history
// Clear consultation chat history
static async clearConsultationChat(consultation_id) {
    try {
        // Begin transaction for safe deletion
        const client = await pool.connect();
        
        try {
            await client.query('BEGIN');
            
            // First, select the messages to be deleted (for return)
            const selectResult = await client.query(
                `SELECT * FROM chat_messages 
                 WHERE consultation_id = $1 
                 ORDER BY created_at ASC`,
                [consultation_id]
            );
            
            // Then delete all messages for this consultation
            const deleteResult = await client.query(
                `DELETE FROM chat_messages 
                 WHERE consultation_id = $1 
                 RETURNING *`,
                [consultation_id]
            );
            
            // Commit transaction
            await client.query('COMMIT');
            
            return selectResult.rows;
        } catch (deleteError) {
            // Rollback transaction in case of error
            await client.query('ROLLBACK');
            throw deleteError;
        } finally {
            // Release the client back to the pool
            client.release();
        }
    } catch (error) {
        console.error('Error clearing consultation chat history:', error);
        throw error;
    }
}

// Archive consultation chat history
static async archiveConsultationChat(consultation_id, archive_reason = 'manual') {
    try {
        // Begin transaction
        const client = await pool.connect();
        
        try {
            await client.query('BEGIN');
            
            // Create an archive table if not exists
            await client.query(`
                CREATE TABLE IF NOT EXISTS chat_messages_archive (
                    id SERIAL PRIMARY KEY,
                    original_message_id INTEGER,
                    consultation_id INTEGER,
                    patient_id INTEGER,
                    doctor_id INTEGER,
                    message_text TEXT,
                    media_url TEXT,
                    message_type VARCHAR(20),
                    created_at TIMESTAMP,
                    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    archive_reason VARCHAR(50),
                    is_from_doctor BOOLEAN
                )
            `);
            
            // Copy messages to archive table
            const archiveResult = await client.query(`
                INSERT INTO chat_messages_archive 
                (original_message_id, consultation_id, patient_id, doctor_id, 
                 message_text, media_url, message_type, created_at, 
                 archive_reason, is_from_doctor)
                SELECT 
                 id, consultation_id, patient_id, doctor_id, 
                 message_text, media_url, message_type, created_at, 
                 $2, is_from_doctor
                FROM chat_messages
                WHERE consultation_id = $1
                RETURNING *
            `, [consultation_id, archive_reason]);
            
            // Delete original messages
            await client.query(
                `DELETE FROM chat_messages 
                 WHERE consultation_id = $1`,
                [consultation_id]
            );
            
            // Commit transaction
            await client.query('COMMIT');
            
            return {
                archived_messages_count: archiveResult.rowCount,
                archived_messages: archiveResult.rows
            };
        } catch (archiveError) {
            // Rollback transaction in case of error
            await client.query('ROLLBACK');
            throw archiveError;
        } finally {
            // Release the client back to the pool
            client.release();
        }
    } catch (error) {
        console.error('Error archiving consultation chat history:', error);
        throw error;
    }
}

static async getConsultationMessages(consultationId) {
    return await pool.query(`
      SELECT 
        cm.*,
        pu.full_name as patient_name,
        du.full_name as doctor_name,
        pu.email as patient_email,
        du.email as doctor_email,
        CASE 
          WHEN cm.is_from_doctor THEN du.id 
          ELSE pu.id 
        END as sender_id,
        CASE 
          WHEN cm.is_from_doctor THEN 'Doctor'
          ELSE 'Patient'
        END as sender_role
      FROM 
        chat_messages cm
      JOIN consultations c ON cm.consultation_id = c.id
      JOIN users pu ON c.patient_id = pu.id
      JOIN users du ON c.doctor_id = du.id
      WHERE 
        cm.consultation_id = $1
      ORDER BY 
        cm.created_at ASC
    `, [consultationId]);
  }
}

module.exports = ChatMessage;