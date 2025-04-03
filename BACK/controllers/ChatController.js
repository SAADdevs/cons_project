// controllers/ChatController.js
const ChatMessage = require('../Models/ChatMessage');
const Consultation = require('../Models/Consultation');
const User = require('../Models/User');
const pool = require('../config/db'); // Add this line to import the database pool directly

class ChatController {
    // Send a new message
    // Replace the sendMessage method in ChatController.js
static async sendMessage(req, res) {
    try {
        const { 
            consultation_id, 
            sender_id, 
            receiver_id,
            message_text, 
            message_type = 'text', 
            media_url = null
        } = req.body;
        
        // Debug log
        console.log('Send message request:', req.body);
        
        if (!consultation_id || !message_text) {
            return res.status(400).json({ message: "Consultation ID and message text are required" });
        }
        
        // Get consultation details to get patient_id and doctor_id
        const consultation = await Consultation.getById(consultation_id);
        if (!consultation) {
            return res.status(404).json({ message: "Consultation not found" });
        }
        
        // Get sender's role to determine if the message is from doctor or patient
        const sender = await User.getUserById(sender_id);
        if (!sender) {
            return res.status(404).json({ message: "Sender not found" });
        }
        
        const isFromDoctor = sender.role === 'doctor';
        
        // Use the consultation's patient_id and doctor_id
        const patient_id = consultation.patient_id;
        const doctor_id = consultation.doctor_id;
        
        // Create the message
        const newMessage = await ChatMessage.createMessage(
            patient_id,
            doctor_id,
            consultation_id,
            message_text,
            media_url,
            message_type,
            isFromDoctor
        );
        
        // Add sender and receiver information for frontend
        const responseMessage = {
            ...newMessage,
            sender_id: isFromDoctor ? doctor_id : patient_id,
            receiver_id: isFromDoctor ? patient_id : doctor_id,
            is_from_doctor: isFromDoctor
        };

        // Emit through socket if available
        if (req.io) {
            req.io.to(`consultation_${consultation_id}`).emit('new_message', responseMessage);
        }

        res.status(201).json({
            message: "Message sent successfully",
            chat_message: responseMessage
        });
    } catch (error) {
        console.error('Error sending message:', error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
}

    // Get consultation chat history
    static async getConsultationChat(req, res) {
        try {
            const { consultation_id } = req.params;
            const { user_id } = req.query; // User requesting the messages
            
            // Debug log
            console.log(`Get consultation chat for consultation ID: ${consultation_id}, User ID: ${user_id}`);

            if (!consultation_id) {
                return res.status(400).json({ message: "Consultation ID is required" });
            }

            // Validate the consultation exists
            const consultation = await Consultation.getById(consultation_id);
            if (!consultation) {
                return res.status(404).json({ message: "Consultation not found" });
            }

            // Get all messages for the consultation
            const messages = await ChatMessage.getConsultationMessages(consultation_id);
            
            // If user_id is provided, mark messages as read
            if (user_id) {
                try {
                    await ChatMessage.markAsRead(user_id, consultation_id);
                } catch (markError) {
                    console.error('Error marking messages as read:', markError);
                    // Continue even if marking fails
                }
            }

            res.status(200).json(messages);
        } catch (error) {
            console.error('Error getting consultation chat:', error);
            res.status(500).json({ message: "Server error", error: error.message });
        }
    }

    // Get unread message count for a user and specific consultation
    static async getUnreadCountForConsultation(req, res) {
        try {
            const { user_id, consultation_id } = req.params;

            if (!user_id || !consultation_id) {
                return res.status(400).json({ message: "User ID and Consultation ID are required" });
            }

            const unreadCount = await ChatMessage.getUnreadCountForConsultation(user_id, consultation_id);

            res.status(200).json({ unread_count: unreadCount });
        } catch (error) {
            console.error('Error getting unread count for consultation:', error);
            res.status(500).json({ message: "Server error", error: error.message });
        }
    }

    // Get unread message count for a user (all consultations)
    static async getUnreadCount(req, res) {
        try {
            const { user_id } = req.params;

            if (!user_id) {
                return res.status(400).json({ message: "User ID is required" });
            }

            const unreadCount = await ChatMessage.getUnreadCount(user_id);

            res.status(200).json({ unread_count: unreadCount });
        } catch (error) {
            console.error('Error getting unread count:', error);
            res.status(500).json({ message: "Server error", error: error.message });
        }
    }

    // Mark messages as read
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
                    try {
                        // Get the requesting user's role directly from the database
                        const userResult = await pool.query(
                            `SELECT role FROM users WHERE id = $1`,
                            [user_id]
                        );
                        
                        if (userResult.rows.length > 0) {
                            const userRole = userResult.rows[0].role;
                            let otherUserId = null;
                            
                            if (userRole === 'patient') {
                                // For patient, get doctor's user ID
                                const doctorResult = await pool.query(
                                    `SELECT u.id 
                                     FROM users u
                                     JOIN doctors d ON u.id = d.user_id
                                     WHERE d.id = $1`,
                                    [consultation.doctor_id]
                                );
                                
                                if (doctorResult.rows.length > 0) {
                                    otherUserId = doctorResult.rows[0].id;
                                }
                            } else if (userRole === 'doctor') {
                                // For doctor, get patient's user ID
                                const patientResult = await pool.query(
                                    `SELECT u.id 
                                     FROM users u
                                     JOIN patients p ON u.id = p.user_id
                                     WHERE p.id = $1`,
                                    [consultation.patient_id]
                                );
                                
                                if (patientResult.rows.length > 0) {
                                    otherUserId = patientResult.rows[0].id;
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
                    } catch (socketError) {
                        console.error('Error preparing socket notification:', socketError);
                        // Continue even if socket notification fails
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

    // Delete a message
    static async deleteMessage(req, res) {
        try {
            const { message_id } = req.params;
            const user_id = req.user.id; // From auth middleware

            if (!message_id) {
                return res.status(400).json({ message: "Message ID is required" });
            }

            const deletedMessage = await ChatMessage.deleteMessage(message_id, user_id);
            
            if (!deletedMessage) {
                return res.status(404).json({ message: "Message not found or you are not authorized to delete it" });
            }

            // Notify other user via Socket.IO
            if (req.io) {
                req.io.to(`consultation_${deletedMessage.consultation_id}`).emit('message_deleted', {
                    message_id,
                    consultation_id: deletedMessage.consultation_id
                });
            }

            res.status(200).json({
                message: "Message deleted successfully",
                deleted_message: deletedMessage
            });
        } catch (error) {
            console.error('Error deleting message:', error);
            res.status(500).json({ message: "Server error", error: error.message });
        }
    }

    // Search messages
    static async searchMessages(req, res) {
        try {
            const { query } = req.query;
            const user_id = req.user.id; // From auth middleware

            if (!query) {
                return res.status(400).json({ message: "Search query is required" });
            }

            const messages = await ChatMessage.searchMessages(user_id, query);

            res.status(200).json(messages);
        } catch (error) {
            console.error('Error searching messages:', error);
            res.status(500).json({ message: "Server error", error: error.message });
        }
    }

    // Additional methods in ChatController.js
// These methods can be added to the existing ChatController class

// Paginated chat history
static async getPaginatedConsultationChat(req, res) {
    try {
        const { consultation_id } = req.params;
        const { 
            page = 1, 
            limit = 50, 
            user_id 
        } = req.query;

        // Validate inputs
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const offset = (pageNum - 1) * limitNum;

        // Validate the consultation exists
        const consultation = await Consultation.getById(consultation_id);
        if (!consultation) {
            return res.status(404).json({ message: "Consultation not found" });
        }

        // Get paginated messages
        const result = await ChatMessage.getPaginatedConsultationMessages(
            consultation_id, 
            limitNum, 
            offset
        );

        // If user_id is provided, mark messages as read
        if (user_id) {
            try {
                await ChatMessage.markAsRead(user_id, consultation_id);
            } catch (markError) {
                console.error('Error marking messages as read:', markError);
            }
        }

        res.status(200).json({
            messages: result.messages,
            total_messages: result.total,
            current_page: pageNum,
            total_pages: Math.ceil(result.total / limitNum)
        });
    } catch (error) {
        console.error('Error getting paginated consultation chat:', error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
}

// Export chat history
static async exportChatHistory(req, res) {
    try {
        const { consultation_id } = req.params;
        const user_id = req.user.id; // From auth middleware

        // Validate consultation and user permissions
        const consultation = await Consultation.getById(consultation_id);
        if (!consultation) {
            return res.status(404).json({ message: "Consultation not found" });
        }

        // Export chat history
        const exportedData = await ChatMessage.exportConsultationChat(consultation_id, user_id);

        // Generate filename
        const filename = `consultation_${consultation_id}_chat_export_${new Date().toISOString().replace(/:/g, '-')}.json`;

        // Send as downloadable JSON file
        res.setHeader('Content-disposition', `attachment; filename=${filename}`);
        res.setHeader('Content-type', 'application/json');
        res.send(JSON.stringify(exportedData, null, 2));
    } catch (error) {
        console.error('Error exporting chat history:', error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
}

// Import chat history
static async importChatHistory(req, res) {
    try {
        const { consultation_id, chat_history } = req.body;
        const user_id = req.user.id; // From auth middleware

        // Validate consultation and user permissions
        const consultation = await Consultation.getById(consultation_id);
        if (!consultation) {
            return res.status(404).json({ message: "Consultation not found" });
        }

        // Import chat history
        const importResult = await ChatMessage.importConsultationChat(
            consultation_id, 
            user_id, 
            chat_history
        );

        res.status(200).json({
            message: "Chat history imported successfully",
            imported_messages: importResult
        });
    } catch (error) {
        console.error('Error importing chat history:', error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
}

// Clear chat history
static async clearChatHistory(req, res) {
    try {
        const { consultation_id } = req.params;
        const user_id = req.user.id; // From auth middleware

        // Validate consultation and user permissions
        const consultation = await Consultation.getById(consultation_id);
        if (!consultation) {
            return res.status(404).json({ message: "Consultation not found" });
        }

        // Determine if user has permission to clear chat history
        const userRole = await User.getUserRole(user_id);
        const isAuthorized = userRole === 'admin' || 
            userRole === 'doctor' && consultation.doctor_id === user_id ||
            userRole === 'patient' && consultation.patient_id === user_id;

        if (!isAuthorized) {
            return res.status(403).json({ message: "Not authorized to clear chat history" });
        }

        // Clear chat history
        const clearedMessages = await ChatMessage.clearConsultationChat(consultation_id);

        // Notify via socket if available
        if (req.io) {
            req.io.to(`consultation_${consultation_id}`).emit('chat_history_cleared', {
                consultation_id,
                cleared_by: user_id
            });
        }

        res.status(200).json({
            message: "Chat history cleared successfully",
            cleared_messages_count: clearedMessages.length
        });
    } catch (error) {
        console.error('Error clearing chat history:', error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
}

// Additional methods in ChatController.js
// These methods can be added to the existing ChatController class

// Archive chat history
static async archiveChatHistory(req, res) {
    try {
        const { consultation_id } = req.params;
        const { reason = 'manual' } = req.body;
        const user_id = req.user.id; // From auth middleware

        // Validate consultation and user permissions
        const consultation = await Consultation.getById(consultation_id);
        if (!consultation) {
            return res.status(404).json({ message: "Consultation not found" });
        }

        // Determine if user has permission to archive chat history
        const userRole = await User.getUserRole(user_id);
        const isAuthorized = userRole === 'admin' || 
            userRole === 'doctor' && consultation.doctor_id === user_id ||
            userRole === 'patient' && consultation.patient_id === user_id;

        if (!isAuthorized) {
            return res.status(403).json({ message: "Not authorized to archive chat history" });
        }

        // Archive chat history
        const archiveResult = await ChatMessage.archiveConsultationChat(
            consultation_id, 
            reason
        );

        // Notify via socket if available
        if (req.io) {
            req.io.to(`consultation_${consultation_id}`).emit('chat_history_archived', {
                consultation_id,
                archived_by: user_id,
                archived_messages_count: archiveResult.archived_messages_count
            });
        }

        res.status(200).json({
            message: "Chat history archived successfully",
            ...archiveResult
        });
    } catch (error) {
        console.error('Error archiving chat history:', error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
}

// Retrieve archived chat history
static async getArchivedChatHistory(req, res) {
    try {
        const { consultation_id } = req.params;
        const { 
            page = 1, 
            limit = 50 
        } = req.query;
        const user_id = req.user.id; // From auth middleware

        // Validate consultation and user permissions
        const consultation = await Consultation.getById(consultation_id);
        if (!consultation) {
            return res.status(404).json({ message: "Consultation not found" });
        }

        // Determine if user has permission to retrieve archived chat history
        const userRole = await User.getUserRole(user_id);
        const isAuthorized = userRole === 'admin' || 
            userRole === 'doctor' && consultation.doctor_id === user_id ||
            userRole === 'patient' && consultation.patient_id === user_id;

        if (!isAuthorized) {
            return res.status(403).json({ message: "Not authorized to retrieve archived chat history" });
        }

        // Calculate pagination
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const offset = (pageNum - 1) * limitNum;

        // Retrieve archived chat history
        const result = await pool.query(
            `SELECT 
                cma.*,
                p.full_name as patient_name,
                d.full_name as doctor_name
             FROM 
                chat_messages_archive cma
             JOIN
                (SELECT u.id, u.full_name FROM users u JOIN patients p ON u.id = p.user_id) p ON cma.patient_id = p.id
             JOIN
                (SELECT u.id, u.full_name FROM users u JOIN doctors d ON u.id = d.user_id) d ON cma.doctor_id = d.id
             WHERE 
                cma.consultation_id = $1
             ORDER BY 
                cma.created_at ASC
             LIMIT $2 OFFSET $3`,
            [consultation_id, limitNum, offset]
        );

        // Get total count of archived messages
        const countResult = await pool.query(
            `SELECT COUNT(*) as total 
             FROM chat_messages_archive 
             WHERE consultation_id = $1`,
            [consultation_id]
        );
        const total = parseInt(countResult.rows[0].total);

        // Transform messages to include sender/receiver details
        const messages = result.rows.map(msg => ({
            ...msg,
            sender_id: msg.is_from_doctor ? msg.doctor_id : msg.patient_id,
            receiver_id: msg.is_from_doctor ? msg.patient_id : msg.doctor_id,
            sender_name: msg.is_from_doctor ? msg.doctor_name : msg.patient_name,
            receiver_name: msg.is_from_doctor ? msg.patient_name : msg.doctor_name
        }));

        res.status(200).json({
            messages,
            total_messages: total,
            current_page: pageNum,
            total_pages: Math.ceil(total / limitNum)
        });
    } catch (error) {
        console.error('Error retrieving archived chat history:', error);
        res.status(500).json({ message: "Server error", error: error.message });
    }
}
}

module.exports = ChatController;