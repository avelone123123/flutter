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
// Get all students
router.get('/', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const students = await prisma_1.default.student.findMany({
            orderBy: { name: 'asc' }
        });
        res.json(students);
    }
    catch (error) {
        console.error('Get all students error:', error);
        res.status(500).json({ error: 'Failed to get students' });
    }
});
// Create a new student (teachers only)
router.post('/', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const { name, email, phone, groupId } = req.body;
        if (!name) {
            return res.status(400).json({ error: 'Student name is required' });
        }
        // If groupId provided, verify teacher owns the group
        if (groupId) {
            const group = await prisma_1.default.group.findUnique({
                where: { id: groupId }
            });
            if (!group || group.teacherId !== req.userId) {
                return res.status(403).json({ error: 'Access denied to this group' });
            }
        }
        const student = await prisma_1.default.student.create({
            data: {
                userId: `student_${Date.now()}`, // Temporary userId for manual students
                name,
                email,
                phone,
                groupId
            }
        });
        res.status(201).json(student);
    }
    catch (error) {
        console.error('Create student error:', error);
        res.status(500).json({ error: 'Failed to create student' });
    }
});
// Get all students in a group
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
        const students = await prisma_1.default.student.findMany({
            where: { groupId },
            include: {
                attendance: {
                    include: {
                        lesson: true
                    }
                }
            },
            orderBy: { name: 'asc' }
        });
        res.json(students);
    }
    catch (error) {
        console.error('Get students error:', error);
        res.status(500).json({ error: 'Failed to get students' });
    }
});
// Get student by ID
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const student = await prisma_1.default.student.findUnique({
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
                        lesson: true
                    },
                    orderBy: { timestamp: 'desc' }
                }
            }
        });
        if (!student) {
            return res.status(404).json({ error: 'Student not found' });
        }
        res.json(student);
    }
    catch (error) {
        console.error('Get student error:', error);
        res.status(500).json({ error: 'Failed to get student' });
    }
});
// Update student (teachers only)
router.put('/:id', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const { id } = req.params;
        const { name, email, phone, groupId } = req.body;
        const student = await prisma_1.default.student.findUnique({
            where: { id },
            include: { group: true }
        });
        if (!student) {
            return res.status(404).json({ error: 'Student not found' });
        }
        // Verify teacher owns the current or new group
        if (student.group && student.group.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        if (groupId && groupId !== student.groupId) {
            const newGroup = await prisma_1.default.group.findUnique({
                where: { id: groupId }
            });
            if (!newGroup || newGroup.teacherId !== req.userId) {
                return res.status(403).json({ error: 'Access denied to new group' });
            }
        }
        const updatedStudent = await prisma_1.default.student.update({
            where: { id },
            data: {
                name,
                email,
                phone,
                groupId
            }
        });
        res.json(updatedStudent);
    }
    catch (error) {
        console.error('Update student error:', error);
        res.status(500).json({ error: 'Failed to update student' });
    }
});
// Delete student (teachers only)
router.delete('/:id', (0, auth_middleware_1.authorizeRole)(['teacher']), async (req, res) => {
    try {
        const { id } = req.params;
        const student = await prisma_1.default.student.findUnique({
            where: { id },
            include: { group: true }
        });
        if (!student) {
            return res.status(404).json({ error: 'Student not found' });
        }
        if (student.group && student.group.teacherId !== req.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }
        await prisma_1.default.student.delete({
            where: { id }
        });
        res.json({ message: 'Student deleted successfully' });
    }
    catch (error) {
        console.error('Delete student error:', error);
        res.status(500).json({ error: 'Failed to delete student' });
    }
});
exports.default = router;
