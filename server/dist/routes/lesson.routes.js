"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const prisma_1 = __importDefault(require("../lib/prisma"));
const auth_middleware_1 = require("../middleware/auth.middleware");
const router = express_1.default.Router();
// All routes require authentication
router.use(auth_middleware_1.authenticateToken);
// Create a new lesson (teachers only)
router.post('/', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const { groupId, title, description, date, duration, qrCode } = req.body;
        if (!groupId || !title || !date) {
            return res.status(400).json({ error: 'Group ID, title, and date are required' });
        }
        // Verify teacher owns the group
        const group = await prisma_1.default.group.findUnique({
            where: { id: groupId }
        });
        if (!group || group.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied to this group' });
        }
        const lesson = await prisma_1.default.lesson.create({
            data: {
                groupId,
                teacherId: req.userId,
                title,
                description,
                date: new Date(date),
                duration: duration || 90,
                qrCode
            }
        });
        res.status(201).json(lesson);
    }
    catch (error) {
        console.error('Create lesson error:', error);
        res.status(500).json({ error: 'Failed to create lesson' });
    }
});
// Get active lessons for a teacher
router.get('/active', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    console.log('HIT /active ROUTE for', req.userId);
    try {
        const lessons = await prisma_1.default.lesson.findMany({
            where: {
                teacherId: req.userId,
                isActive: true
            },
            include: {
                group: true,
                attendance: true
            },
            orderBy: { date: 'asc' }
        });
        res.json(lessons);
    }
    catch (error) {
        console.error('Get active lessons error:', error);
        res.status(500).json({ error: 'Failed to get active lessons' });
    }
});
// Refresh QR code for a lesson
router.post('/:id/refresh-qr', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const { id } = req.params;
        const { qrCode } = req.body;
        const lesson = await prisma_1.default.lesson.findUnique({ where: { id } });
        if (!lesson || lesson.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        const updated = await prisma_1.default.lesson.update({
            where: { id },
            data: { qrCode }
        });
        res.json(updated);
    }
    catch (error) {
        console.error('Refresh QR error:', error);
        res.status(500).json({ error: 'Failed to refresh QR' });
    }
});
// End a lesson
router.post('/:id/end', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const { id } = req.params;
        const lesson = await prisma_1.default.lesson.findUnique({ where: { id } });
        if (!lesson || lesson.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        const updated = await prisma_1.default.lesson.update({
            where: { id },
            data: { isActive: false }
        });
        res.json(updated);
    }
    catch (error) {
        console.error('End lesson error:', error);
        res.status(500).json({ error: 'Failed to end lesson' });
    }
});
// Get all lessons for a group
router.get('/group/:groupId', async (req, res) => {
    try {
        const { groupId } = req.params;
        // Verify access to group
        const group = await prisma_1.default.group.findUnique({
            where: { id: groupId }
        });
        if (!group) {
            return res.status(404).json({ error: 'Group not found' });
        }
        if (req.userRole === 'teacher' && group.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        const lessons = await prisma_1.default.lesson.findMany({
            where: { groupId },
            include: {
                attendance: {
                    include: {
                        student: true
                    }
                }
            },
            orderBy: { date: 'desc' }
        });
        res.json(lessons);
    }
    catch (error) {
        console.error('Get lessons error:', error);
        res.status(500).json({ error: 'Failed to get lessons' });
    }
});
// Get lesson by ID
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const lesson = await prisma_1.default.lesson.findUnique({
            where: { id },
            include: {
                group: {
                    include: {
                        teacher: {
                            select: {
                                id: true,
                                name: true,
                                email: true
                            }
                        }
                    }
                },
                attendance: {
                    include: {
                        student: true
                    }
                }
            }
        });
        if (!lesson) {
            return res.status(404).json({ error: 'Lesson not found' });
        }
        // Verify access
        if (req.userRole === 'teacher' && lesson.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        res.json(lesson);
    }
    catch (error) {
        console.error('Get lesson error:', error);
        res.status(500).json({ error: 'Failed to get lesson' });
    }
});
// Update lesson (teachers only)
router.put('/:id', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const { id } = req.params;
        const { title, description, date, duration, qrCode, isActive } = req.body;
        const lesson = await prisma_1.default.lesson.findUnique({
            where: { id }
        });
        if (!lesson) {
            return res.status(404).json({ error: 'Lesson not found' });
        }
        if (lesson.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        const updatedLesson = await prisma_1.default.lesson.update({
            where: { id },
            data: {
                title,
                description,
                date: date ? new Date(date) : undefined,
                duration,
                qrCode,
                isActive
            }
        });
        res.json(updatedLesson);
    }
    catch (error) {
        console.error('Update lesson error:', error);
        res.status(500).json({ error: 'Failed to update lesson' });
    }
});
// Delete lesson (teachers only)
router.delete('/:id', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const { id } = req.params;
        const lesson = await prisma_1.default.lesson.findUnique({
            where: { id }
        });
        if (!lesson) {
            return res.status(404).json({ error: 'Lesson not found' });
        }
        if (lesson.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        await prisma_1.default.lesson.delete({
            where: { id }
        });
        res.json({ message: 'Lesson deleted successfully' });
    }
    catch (error) {
        console.error('Delete lesson error:', error);
        res.status(500).json({ error: 'Failed to delete lesson' });
    }
});
exports.default = router;
