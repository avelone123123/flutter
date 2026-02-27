import express, { Response } from 'express';
import prisma from '../lib/prisma';
import { authenticateToken, authorizeRole, AuthRequest } from '../middleware/auth.middleware';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Create a new group (teachers only)
router.post('/', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { name, description, courseCode, semester } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Group name is required' });
    }

    const group = await prisma.group.create({
      data: {
        name,
        description,
        courseCode,
        semester,
        teacherId: req.userId!
      }
    });

    res.status(201).json(group);
  } catch (error: any) {
    console.error('Create group error:', error);
    res.status(500).json({ error: 'Failed to create group' });
  }
});

// Get all groups for the current teacher
router.get('/my-groups', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const groups = await prisma.group.findMany({
      where: {
        teacherId: req.userId,
        isActive: true
      },
      include: {
        students: true,
        lessons: {
          orderBy: { date: 'desc' },
          take: 5
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json(groups);
  } catch (error: any) {
    console.error('Get groups error:', error);
    res.status(500).json({ error: 'Failed to get groups' });
  }
});

// Get all groups for a specific teacher (for web client)
router.get('/teacher/:teacherId', async (req: AuthRequest, res: Response) => {
  try {
    const { teacherId } = req.params;

    // Check if user has access to this teacher's groups
    if (req.userRole === 'teacher' && req.userId !== teacherId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const groups = await prisma.group.findMany({
      where: {
        teacherId: teacherId,
        isActive: true
      },
      include: {
        students: true,
        lessons: {
          orderBy: { date: 'desc' },
          take: 5
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ groups });
  } catch (error: any) {
    console.error('Get teacher groups error:', error);
    res.status(500).json({ error: 'Failed to get teacher groups' });
  }
});

// Get group by ID
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const group = await prisma.group.findUnique({
      where: { id },
      include: {
        teacher: {
          select: {
            id: true,
            name: true,
            email: true
          }
        },
        students: true,
        lessons: {
          orderBy: { date: 'desc' }
        }
      }
    });

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user has access to this group
    if (req.userRole === 'teacher' && group.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.json(group);
  } catch (error: any) {
    console.error('Get group error:', error);
    res.status(500).json({ error: 'Failed to get group' });
  }
});

// Update group (teachers only)
router.put('/:id', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { name, description, courseCode, semester, isActive } = req.body;

    // Check if teacher owns this group
    const group = await prisma.group.findUnique({
      where: { id }
    });

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    if (group.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updatedGroup = await prisma.group.update({
      where: { id },
      data: {
        name,
        description,
        courseCode,
        semester,
        isActive
      }
    });

    res.json(updatedGroup);
  } catch (error: any) {
    console.error('Update group error:', error);
    res.status(500).json({ error: 'Failed to update group' });
  }
});

// Add student to group (teachers only)
router.post('/:id/students', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { studentId } = req.body;

    const group = await prisma.group.findUnique({ where: { id } });
    if (!group || group.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updatedStudent = await prisma.student.update({
      where: { id: studentId },
      data: { groupId: id }
    });

    res.json(updatedStudent);
  } catch (error: any) {
    console.error('Add student error:', error);
    res.status(500).json({ error: 'Failed to add student to group' });
  }
});

// Remove student from group (teachers only)
router.delete('/:id/students/:studentId', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id, studentId } = req.params;

    const group = await prisma.group.findUnique({ where: { id } });
    if (!group || group.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updatedStudent = await prisma.student.update({
      where: { id: studentId },
      data: { groupId: null }
    });

    res.json(updatedStudent);
  } catch (error: any) {
    console.error('Remove student error:', error);
    res.status(500).json({ error: 'Failed to remove student from group' });
  }
});

// Delete group (teachers only)
router.delete('/:id', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    // Check if teacher owns this group
    const group = await prisma.group.findUnique({
      where: { id }
    });

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    if (group.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await prisma.group.delete({
      where: { id }
    });

    res.json({ message: 'Group deleted successfully' });
  } catch (error: any) {
    console.error('Delete group error:', error);
    res.status(500).json({ error: 'Failed to delete group' });
  }
});

export default router;
