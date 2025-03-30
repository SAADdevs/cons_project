// controllers/ChatController.js
const ChatMessage = require('../Models/ChatMessage');
const User = require('../Models/User');
const Doctor = require('../Models/Doctor');
const Patient = require('../Models/Patient');

class ChatController {
    // Send a new message
    static async sendMessage(req, res) {
        try {
            const { sender_id, receiver_id, consultation_id, message_text } = req.body;

            // Validate required fields
            if (!sender_id || !receiver_id || !consultation_id || !message_text) {
                return res.status(400).json({ message: "Missing required fields" });
            }

            // Create the message
            const newMessage = await ChatMessage.createMessage(
                sender_id,
                receiver_id,
                consultation_id,
                message_text
            );

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

            const updatedMessages = await ChatMessage.markAsRead(user_id, consultation_id);

            res.status(200).json({
                message: `${updatedMessages.length} messages marked as read`,
                updated_messages: updatedMessages
            });
        } catch (error) {
            console.error('Error marking messages as read:', error);
            res.status(500).json({ message: "Server error" });
        }
    }
}

module.exports = ChatController;