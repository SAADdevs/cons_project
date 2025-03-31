// controllers/ChatController.js
const ChatMessage = require('../models/ChatMessage');
const Consultation = require('../Models/Consultation');
const User = require('../Models/User');

class ChatController {
    // Send a new message
    static async sendMessage(req, res) {
        try {
            const { sender_id, receiver_id, consultation_id, message_text, media_url, message_type } = req.body;

            // Validate required fields
            if (!sender_id || !receiver_id || !consultation_id || !message_text) {
                return res.status(400).json({ message: "Missing required fields" });
            }

            // Validate that the consultation exists and is active
            const consultation = await Consultation.getById(consultation_id);
            if (!consultation) {
                return res.status(404).json({ message: "Consultation not found" });
            }

            // Verify that the sender and receiver are part of this consultation
            const isPatientOrDoctor = 
                (consultation.patient_id === sender_id && consultation.doctor_id === receiver_id) ||
                (consultation.doctor_id === sender_id && consultation.patient_id === receiver_id);
            
            if (!isPatientOrDoctor) {
                return res.status(403).json({ message: "Unauthorized to send messages in this consultation" });
            }

            // Create the message
            const newMessage = await ChatMessage.createMessage(
                sender_id,
                receiver_id,
                consultation_id,
                message_text,
                media_url,
                message_type
            );

            // Emit the message via Socket.IO for real-time updates (implementation in step 4)
            if (req.io) {
                req.io.to(`consultation_${consultation_id}`).emit('new_message', newMessage);
            }

            res.status(201).json({
                message: "Message sent successfully",
                chat_message: newMessage
            });
        } catch (error) {
            console.error('Error sending message:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get consultation chat history
    static async getConsultationChat(req, res) {
        try {
            const { consultation_id } = req.params;
            const { user_id } = req.query; // User requesting the messages

            if (!consultation_id) {
                return res.status(400).json({ message: "Consultation ID is required" });
            }

            // Validate the consultation exists
            const consultation = await Consultation.getById(consultation_id);
            if (!consultation) {
                return res.status(404).json({ message: "Consultation not found" });
            }

            // Verify that the user is part of this consultation
            const isParticipant = (consultation.patient_id == user_id || consultation.doctor_id == user_id);
            if (!isParticipant && !req.user.isAdmin) {
                return res.status(403).json({ message: "Unauthorized to view this consultation's messages" });
            }

            // Get all messages for the consultation
            const messages = await ChatMessage.getConsultationMessages(consultation_id);

            // If user_id is provided, mark messages as read
            if (user_id) {
                await ChatMessage.markAsRead(user_id, consultation_id);
            }

            res.status(200).json(messages);
        } catch (error) {
            console.error('Error getting consultation chat:', error);
            res.status(500).json({ message: "Server error" });
        }
    }

    // Get unread message count for a user
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
            res.status(500).json({ message: "Server error" });
        }
    }

    // Mark messages as read
    static async markMessagesAsRead(req, res) {
        try {
            const { user_id, consultation_id } = req.body;

            if (!user_id || !consultation_id) {
                return res.status(400).json({ message: "User ID and Consultation ID are required" });
            }

            // Verify the user has access to this consultation
            const consultation = await Consultation.getById(consultation_id);
            if (!consultation) {
                return res.status(404).json({ message: "Consultation not found" });
            }

            if (consultation.patient_id != user_id && consultation.doctor_id != user_id) {
                return res.status(403).json({ message: "Unauthorized to mark messages as read in this consultation" });
            }

            const updatedMessages = await ChatMessage.markAsRead(user_id, consultation_id);

            // Emit the read receipt via Socket.IO
            if (req.io) {
                const otherUser = consultation.patient_id == user_id 
                    ? consultation.doctor_id 
                    : consultation.patient_id;
                
                req.io.to(`user_${otherUser}`).emit('messages_read', {
                    consultation_id,
                    user_id,
                    count: updatedMessages.length
                });
            }

            res.status(200).json({
                message: `${updatedMessages.length} messages marked as read`,
                updated_messages: updatedMessages
            });
        } catch (error) {
            console.error('Error marking messages as read:', error);
            res.status(500).json({ message: "Server error" });
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
            res.status(500).json({ message: "Server error" });
        }
    }

    // Search chat messages
    static async searchMessages(req, res) {
        try {
            const user_id = req.user.id; // From auth middleware
            const { query } = req.params;

            if (!query) {
                return res.status(400).json({ message: "Search query is required" });
            }

            const messages = await ChatMessage.searchMessages(user_id, query);

            res.status(200).json(messages);
        } catch (error) {
            console.error('Error searching messages:', error);
            res.status(500).json({ message: "Server error" });
        }
    }
}

module.exports = ChatController;