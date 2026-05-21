import express from 'express';
import {
    createEvent,
    getAllEvents,
    getEventById,
    getEventsByOrganizer,
    attendEvent,
    cancelEventAttendance,
    updateEvent,
    deleteEvent,
    getEventAttendees,
    createEventOrder,
    createEventPaymentLink,
    verifyEventPayment,
    getMyUpcomingEvents
} from '../controllers/eventController.js';
import { protect } from '../middleware/auth.js';

const eventRoutes = express.Router();

// All routes require authentication
eventRoutes.use(protect);

// GET /api/events - Get all events (with optional filters)
eventRoutes.get('/', getAllEvents);

// GET /api/events/my-upcoming - Get user's upcoming events with reminder status
eventRoutes.get('/my-upcoming', getMyUpcomingEvents);

// GET /api/events/:eventId - Get event by ID
eventRoutes.get('/:eventId', getEventById);

// GET /api/events/organizer/:organizerId - Get events by organizer
eventRoutes.get('/organizer/:organizerId', getEventsByOrganizer);

// GET /api/events/:eventId/attendees - Get event attendees list
eventRoutes.get('/:eventId/attendees', getEventAttendees);

// POST /api/events - Create a new event (Temple/Creator only)
eventRoutes.post('/', createEvent);

// POST /api/events/:eventId/attend - Register to attend an event
eventRoutes.post('/:eventId/attend', attendEvent);

// POST /api/events/:eventId/cancel-attendance - Cancel event attendance
eventRoutes.post('/:eventId/cancel-attendance', cancelEventAttendance);

// POST /api/events/:eventId/create-order - Create Razorpay order for paid event
eventRoutes.post('/:eventId/create-order', createEventOrder);

// POST /api/events/:eventId/payment-link - Create Razorpay Payment Link for paid event
eventRoutes.post('/:eventId/payment-link', createEventPaymentLink);

// POST /api/events/:eventId/verify-payment - Verify payment and register for event
eventRoutes.post('/:eventId/verify-payment', verifyEventPayment);

// PUT /api/events/:eventId - Update an event (organizer only)
eventRoutes.put('/:eventId', updateEvent);

// DELETE /api/events/:eventId - Delete an event (organizer only)
eventRoutes.delete('/:eventId', deleteEvent);

export default eventRoutes;
