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
// Mark attendance (students and teachers)
router.post('/', async (req, res) => {
    try {
        const { lessonId, studentId, status, scannedAt } = req.body;
        if (!lessonId || !studentId) {
            return res.status(400).json({ error: 'Lesson ID and student ID are required' });
        }
        // Verify lesson exists
        const lesson = await prisma_1.default.lesson.findUnique({
            where: { id: lessonId }
        });
        if (!lesson) {
            return res.status(404).json({ error: 'Lesson not found' });
        }
        // Verify access
        if (req.userRole === 'teacher' && lesson.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        // Check if attendance already exists
        const existingAttendance = await prisma_1.default.attendance.findUnique({
            where: {
                lessonId_studentId: {
                    lessonId,
                    studentId
                }
            }
        });
        let attendance;
        if (existingAttendance) {
            // Update existing attendance
            attendance = await prisma_1.default.attendance.update({
                where: { id: existingAttendance.id },
                data: {
                    status: status || 'present',
                    scannedAt: scannedAt ? new Date(scannedAt) : new Date()
                }
            });
        }
        else {
            // Create new attendance
            attendance = await prisma_1.default.attendance.create({
                data: {
                    lessonId,
                    studentId,
                    status: status || 'present',
                    scannedAt: scannedAt ? new Date(scannedAt) : new Date()
                }
            });
        }
        res.status(201).json(attendance);
    }
    catch (error) {
        console.error('Mark attendance error:', error);
        res.status(500).json({ error: 'Failed to mark attendance' });
    }
});
// Get attendance for a lesson
router.get('/lesson/:lessonId', async (req, res) => {
    try {
        const { lessonId } = req.params;
        // Verify lesson access
        const lesson = await prisma_1.default.lesson.findUnique({
            where: { id: lessonId }
        });
        if (!lesson) {
            return res.status(404).json({ error: 'Lesson not found' });
        }
        if (req.userRole === 'teacher' && lesson.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        const attendance = await prisma_1.default.attendance.findMany({
            where: { lessonId },
            include: {
                student: true
            },
            orderBy: { timestamp: 'desc' }
        });
        res.json(attendance);
    }
    catch (error) {
        console.error('Get attendance error:', error);
        res.status(500).json({ error: 'Failed to get attendance' });
    }
});
// Get attendance for a student
router.get('/student/:studentId', async (req, res) => {
    try {
        const { studentId } = req.params;
        const attendance = await prisma_1.default.attendance.findMany({
            where: { studentId },
            include: {
                lesson: {
                    include: {
                        group: true
                    }
                }
            },
            orderBy: { timestamp: 'desc' }
        });
        res.json(attendance);
    }
    catch (error) {
        console.error('Get student attendance error:', error);
        res.status(500).json({ error: 'Failed to get student attendance' });
    }
});
// Update attendance (teachers only)
router.put('/:id', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        const attendance = await prisma_1.default.attendance.findUnique({
            where: { id },
            include: {
                lesson: true
            }
        });
        if (!attendance) {
            return res.status(404).json({ error: 'Attendance record not found' });
        }
        if (attendance.lesson.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        const updatedAttendance = await prisma_1.default.attendance.update({
            where: { id },
            data: { status }
        });
        res.json(updatedAttendance);
    }
    catch (error) {
        console.error('Update attendance error:', error);
        res.status(500).json({ error: 'Failed to update attendance' });
    }
});
// Delete attendance (teachers only)
router.delete('/:id', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const { id } = req.params;
        const attendance = await prisma_1.default.attendance.findUnique({
            where: { id },
            include: {
                lesson: true
            }
        });
        if (!attendance) {
            return res.status(404).json({ error: 'Attendance record not found' });
        }
        if (attendance.lesson.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        await prisma_1.default.attendance.delete({
            where: { id }
        });
        res.json({ message: 'Attendance deleted successfully' });
    }
    catch (error) {
        console.error('Delete attendance error:', error);
        res.status(500).json({ error: 'Failed to delete attendance' });
    }
});
// Get attendance statistics for a group
router.get('/stats/group/:groupId', async (req, res) => {
    try {
        const { groupId } = req.params;
        // Verify group access
        const group = await prisma_1.default.group.findUnique({
            where: { id: groupId }
        });
        if (!group) {
            return res.status(404).json({ error: 'Group not found' });
        }
        if (req.userRole === 'teacher' && group.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        const stats = await prisma_1.default.attendance.groupBy({
            by: ['status', 'studentId'],
            where: {
                lesson: {
                    groupId
                }
            },
            _count: {
                id: true
            }
        });
        res.json(stats);
    }
    catch (error) {
        console.error('Get stats error:', error);
        res.status(500).json({ error: 'Failed to get statistics' });
    }
});
exports.default = router;
