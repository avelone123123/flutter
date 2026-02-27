import express, { Response } from 'express';
import prisma from '../lib/prisma';
import { authenticateToken, authorizeRole, AuthRequest } from '../middleware/auth.middleware';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Get all students
router.get('/', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const students = await prisma.student.findMany({
      orderBy: { name: 'asc' }
    });
    res.json(students);
  } catch (error: any) {
    console.error('Get all students error:', error);
    res.status(500).json({ error: 'Failed to get students' });
  }
});

// Get current student profile (by userId from JWT)
router.get('/me', async (req: AuthRequest, res: Response) => {
  try {
    const student = await prisma.student.findFirst({
      where: { userId: req.userId },
      include: {
        group: {
          include: {
            teacher: {
              select: { id: true, name: true, email: true }
            }
          }
        }
      }
    });

    if (!student) {
      return res.status(404).json({ error: 'Student profile not found' });
    }

    res.json(student);
  } catch (error: any) {
    console.error('Get student profile error:', error);
    res.status(500).json({ error: 'Failed to get student profile' });
  }
});

// Get current student's groups with lessons
router.get('/me/groups', async (req: AuthRequest, res: Response) => {
  try {
    // Find all student records for this user
    const students = await prisma.student.findMany({
      where: { userId: req.userId },
      select: { groupId: true }
    });

    const groupIds = students
      .map(s => s.groupId)
      .filter((id): id is string => id !== null);

    if (groupIds.length === 0) {
      return res.json([]);
    }

    const groups = await prisma.group.findMany({
      where: {
        id: { in: groupIds },
        isActive: true
      },
      include: {
        teacher: {
          select: { id: true, name: true, email: true }
        },
        lessons: {
          orderBy: { date: 'desc' },
          include: {
            attendance: {
              where: {
                student: {
                  userId: req.userId
                }
              }
            }
          }
        },
        _count: {
          select: { students: true }
        }
      },
      orderBy: { name: 'asc' }
    });

    res.json(groups);
  } catch (error: any) {
    console.error('Get student groups error:', error);
    res.status(500).json({ error: 'Failed to get student groups' });
  }
});

// Create a new student (teachers only)
router.post('/', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { name, email, phone, groupId } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Student name is required' });
    }

    // If groupId provided, verify teacher owns the group
    if (groupId) {
      const group = await prisma.group.findUnique({
        where: { id: groupId }
      });

      if (!group || group.teacherId !== req.userId) {
        return res.status(403).json({ error: 'Access denied to this group' });
      }
    }

    const student = await prisma.student.create({
      data: {
        userId: `student_${Date.now()}`, // Temporary userId for manual students
        name,
        email,
        phone,
        groupId
      }
    });

    res.status(201).json(student);
  } catch (error: any) {
    console.error('Create student error:', error);
    res.status(500).json({ error: 'Failed to create student' });
  }
});

// Get all students in a group
router.get('/group/:groupId', async (req: AuthRequest, res: Response) => {
  try {
    const { groupId } = req.params;

    // Verify access to group
    const group = await prisma.group.findUnique({
      where: { id: groupId }
    });

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    if (req.userRole === 'teacher' && group.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const students = await prisma.student.findMany({
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
  } catch (error: any) {
    console.error('Get students error:', error);
    res.status(500).json({ error: 'Failed to get students' });
  }
});

// Get student by ID
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const student = await prisma.student.findUnique({
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
  } catch (error: any) {
    console.error('Get student error:', error);
    res.status(500).json({ error: 'Failed to get student' });
  }
});

// Update student (teachers only)
router.put('/:id', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { name, email, phone, groupId } = req.body;

    const student = await prisma.student.findUnique({
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
      const newGroup = await prisma.group.findUnique({
        where: { id: groupId }
      });

      if (!newGroup || newGroup.teacherId !== req.userId) {
        return res.status(403).json({ error: 'Access denied to new group' });
      }
    }

    const updatedStudent = await prisma.student.update({
      where: { id },
      data: {
        name,
        email,
        phone,
        groupId
      }
    });

    res.json(updatedStudent);
  } catch (error: any) {
    console.error('Update student error:', error);
    res.status(500).json({ error: 'Failed to update student' });
  }
});

// Delete student (teachers only)
router.delete('/:id', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const student = await prisma.student.findUnique({
      where: { id },
      include: { group: true }
    });

    if (!student) {
      return res.status(404).json({ error: 'Student not found' });
    }

    if (student.group && student.group.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await prisma.student.delete({
      where: { id }
    });

    res.json({ message: 'Student deleted successfully' });
  } catch (error: any) {
    console.error('Delete student error:', error);
    res.status(500).json({ error: 'Failed to delete student' });
  }
});

export default router;
