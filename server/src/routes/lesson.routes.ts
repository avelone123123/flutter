import express, { Response } from 'express';
import prisma from '../lib/prisma';
import { authenticateToken, authorizeRole, AuthRequest } from '../middleware/auth.middleware';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Create a new lesson (teachers only)
router.post('/', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { groupId, title, description, date, duration, qrCode, type, startTime, endTime, classroom } = req.body;

    if (!groupId || !title || !date) {
      return res.status(400).json({ error: 'Group ID, title, and date are required' });
    }

    // Verify teacher owns the group
    const group = await prisma.group.findUnique({
      where: { id: groupId }
    });

    if (!group || group.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied to this group' });
    }

    const lesson = await prisma.lesson.create({
      data: {
        groupId,
        teacherId: req.userId!,
        title,
        description,
        date: new Date(date),
        duration: duration || 90,
        qrCode,
        type,
        startTime,
        endTime,
        classroom
      }
    });

    res.status(201).json(lesson);
  } catch (error: any) {
    console.error('Create lesson error:', error);
    res.status(500).json({ error: 'Failed to create lesson' });
  }
});

// Get active lessons for a teacher
router.get('/active', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  console.log('HIT /active ROUTE for', req.userId);
  try {
    const lessons = await prisma.lesson.findMany({
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
  } catch (error: any) {
    console.error('Get active lessons error:', error);
    res.status(500).json({ error: 'Failed to get active lessons' });
  }
});

// Get all lessons for a specific teacher
router.get('/teacher/:teacherId', async (req: AuthRequest, res: Response) => {
  try {
    const { teacherId } = req.params;

    // Check if user has access to this teacher's lessons
    if (req.userRole === 'teacher' && req.userId !== teacherId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const lessons = await prisma.lesson.findMany({
      where: {
        teacherId: teacherId
      },
      include: {
        group: true,
        attendance: true
      },
      orderBy: { date: 'desc' }
    });

    res.json({ lessons });
  } catch (error: any) {
    console.error('Get teacher lessons error:', error);
    res.status(500).json({ error: 'Failed to get teacher lessons' });
  }
});

// Refresh QR code for a lesson
router.post('/:id/refresh-qr', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { qrCode } = req.body;

    const lesson = await prisma.lesson.findUnique({ where: { id } });
    if (!lesson || lesson.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updated = await prisma.lesson.update({
      where: { id },
      data: { qrCode }
    });
    res.json(updated);
  } catch (error: any) {
    console.error('Refresh QR error:', error);
    res.status(500).json({ error: 'Failed to refresh QR' });
  }
});

// End a lesson
router.post('/:id/end', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const lesson = await prisma.lesson.findUnique({ where: { id } });
    if (!lesson || lesson.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updated = await prisma.lesson.update({
      where: { id },
      data: { isActive: false }
    });
    res.json(updated);
  } catch (error: any) {
    console.error('End lesson error:', error);
    res.status(500).json({ error: 'Failed to end lesson' });
  }
});

// Get all lessons for a group
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

    const lessons = await prisma.lesson.findMany({
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
  } catch (error: any) {
    console.error('Get lessons error:', error);
    res.status(500).json({ error: 'Failed to get lessons' });
  }
});

// Get lesson by ID
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const lesson = await prisma.lesson.findUnique({
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
  } catch (error: any) {
    console.error('Get lesson error:', error);
    res.status(500).json({ error: 'Failed to get lesson' });
  }
});

// Update lesson (teachers only)
router.put('/:id', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { title, description, date, duration, qrCode, isActive, type, startTime, endTime, classroom } = req.body;

    const lesson = await prisma.lesson.findUnique({
      where: { id }
    });

    if (!lesson) {
      return res.status(404).json({ error: 'Lesson not found' });
    }

    if (lesson.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updatedLesson = await prisma.lesson.update({
      where: { id },
      data: {
        title,
        description,
        date: date ? new Date(date) : undefined,
        duration,
        qrCode,
        isActive,
        type,
        startTime,
        endTime,
        classroom
      }
    });

    res.json(updatedLesson);
  } catch (error: any) {
    console.error('Update lesson error:', error);
    res.status(500).json({ error: 'Failed to update lesson' });
  }
});

// Delete lesson (teachers only)
router.delete('/:id', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const lesson = await prisma.lesson.findUnique({
      where: { id }
    });

    if (!lesson) {
      return res.status(404).json({ error: 'Lesson not found' });
    }

    if (lesson.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await prisma.lesson.delete({
      where: { id }
    });

    res.json({ message: 'Lesson deleted successfully' });
  } catch (error: any) {
    console.error('Delete lesson error:', error);
    res.status(500).json({ error: 'Failed to delete lesson' });
  }
});

export default router;
