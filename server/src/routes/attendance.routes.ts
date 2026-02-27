import express, { Response } from 'express';
import prisma from '../lib/prisma';
import { authenticateToken, authorizeRole, AuthRequest } from '../middleware/auth.middleware';

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// Mark attendance via QR code (student scans/enters QR code)
router.post('/qr', async (req: AuthRequest, res: Response) => {
  try {
    const { qrCode } = req.body;

    if (!qrCode) {
      return res.status(400).json({ error: 'QR code is required' });
    }

    // Find lesson by QR code
    const lesson = await prisma.lesson.findFirst({
      where: {
        qrCode: qrCode,
        isActive: true
      },
      include: { group: true }
    });

    if (!lesson) {
      return res.status(404).json({ error: 'Занятие не найдено или уже завершено' });
    }

    // Find student profile for current user
    const student = await prisma.student.findFirst({
      where: { userId: req.userId }
    });

    if (!student) {
      return res.status(404).json({ error: 'Профиль студента не найден' });
    }

    // Verify student is in the lesson's group
    if (student.groupId !== lesson.groupId) {
      return res.status(403).json({ error: 'Вы не состоите в группе этого занятия' });
    }

    // Check if already marked
    const existing = await prisma.attendance.findUnique({
      where: {
        lessonId_studentId: {
          lessonId: lesson.id,
          studentId: student.id
        }
      }
    });

    if (existing) {
      return res.status(200).json({
        message: 'Вы уже отметились на этом занятии',
        attendance: existing,
        alreadyMarked: true
      });
    }

    // Mark attendance
    const attendance = await prisma.attendance.create({
      data: {
        lessonId: lesson.id,
        studentId: student.id,
        status: 'present',
        scannedAt: new Date()
      }
    });

    res.status(201).json({
      message: 'Посещаемость отмечена успешно!',
      attendance,
      lesson: {
        title: lesson.title,
        groupName: lesson.group.name
      }
    });
  } catch (error: any) {
    console.error('Mark attendance via QR error:', error);
    res.status(500).json({ error: 'Failed to mark attendance' });
  }
});

// Get current student's attendance history
router.get('/me', async (req: AuthRequest, res: Response) => {
  try {
    const student = await prisma.student.findFirst({
      where: { userId: req.userId }
    });

    if (!student) {
      return res.status(404).json({ error: 'Student profile not found' });
    }

    const attendance = await prisma.attendance.findMany({
      where: { studentId: student.id },
      include: {
        lesson: {
          include: {
            group: true
          }
        }
      },
      orderBy: { timestamp: 'desc' }
    });

    // Calculate stats
    const totalLessons = await prisma.lesson.count({
      where: {
        group: {
          students: {
            some: { id: student.id }
          }
        }
      }
    });

    const presentCount = attendance.filter(a => a.status === 'present').length;
    const lateCount = attendance.filter(a => a.status === 'late').length;
    const percentage = totalLessons > 0
      ? Math.round(((presentCount + lateCount) / totalLessons) * 100)
      : 0;

    res.json({
      attendance,
      stats: {
        totalLessons,
        present: presentCount,
        late: lateCount,
        absent: totalLessons - presentCount - lateCount,
        percentage
      }
    });
  } catch (error: any) {
    console.error('Get student attendance error:', error);
    res.status(500).json({ error: 'Failed to get attendance' });
  }
});

// Mark attendance (students and teachers)
router.post('/', async (req: AuthRequest, res: Response) => {
  try {
    const { lessonId, studentId, status, scannedAt } = req.body;

    if (!lessonId || !studentId) {
      return res.status(400).json({ error: 'Lesson ID and student ID are required' });
    }

    // Verify lesson exists
    const lesson = await prisma.lesson.findUnique({
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
    const existingAttendance = await prisma.attendance.findUnique({
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
      attendance = await prisma.attendance.update({
        where: { id: existingAttendance.id },
        data: {
          status: status || 'present',
          scannedAt: scannedAt ? new Date(scannedAt) : new Date()
        }
      });
    } else {
      // Create new attendance
      attendance = await prisma.attendance.create({
        data: {
          lessonId,
          studentId,
          status: status || 'present',
          scannedAt: scannedAt ? new Date(scannedAt) : new Date()
        }
      });
    }

    res.status(201).json(attendance);
  } catch (error: any) {
    console.error('Mark attendance error:', error);
    res.status(500).json({ error: 'Failed to mark attendance' });
  }
});

// Get attendance for a lesson
router.get('/lesson/:lessonId', async (req: AuthRequest, res: Response) => {
  try {
    const { lessonId } = req.params;

    // Verify lesson access
    const lesson = await prisma.lesson.findUnique({
      where: { id: lessonId }
    });

    if (!lesson) {
      return res.status(404).json({ error: 'Lesson not found' });
    }

    if (req.userRole === 'teacher' && lesson.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const attendance = await prisma.attendance.findMany({
      where: { lessonId },
      include: {
        student: true
      },
      orderBy: { timestamp: 'desc' }
    });

    res.json(attendance);
  } catch (error: any) {
    console.error('Get attendance error:', error);
    res.status(500).json({ error: 'Failed to get attendance' });
  }
});

// Get attendance for a student
router.get('/student/:studentId', async (req: AuthRequest, res: Response) => {
  try {
    const { studentId } = req.params;

    const attendance = await prisma.attendance.findMany({
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
  } catch (error: any) {
    console.error('Get student attendance error:', error);
    res.status(500).json({ error: 'Failed to get student attendance' });
  }
});

// Update attendance (teachers only)
router.put('/:id', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const attendance = await prisma.attendance.findUnique({
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

    const updatedAttendance = await prisma.attendance.update({
      where: { id },
      data: { status }
    });

    res.json(updatedAttendance);
  } catch (error: any) {
    console.error('Update attendance error:', error);
    res.status(500).json({ error: 'Failed to update attendance' });
  }
});

// Delete attendance (teachers only)
router.delete('/:id', authorizeRole(['teacher']), async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;

    const attendance = await prisma.attendance.findUnique({
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

    await prisma.attendance.delete({
      where: { id }
    });

    res.json({ message: 'Attendance deleted successfully' });
  } catch (error: any) {
    console.error('Delete attendance error:', error);
    res.status(500).json({ error: 'Failed to delete attendance' });
  }
});

// Get attendance statistics for a group
router.get('/stats/group/:groupId', async (req: AuthRequest, res: Response) => {
  try {
    const { groupId } = req.params;

    // Verify group access
    const group = await prisma.group.findUnique({
      where: { id: groupId }
    });

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    if (req.userRole === 'teacher' && group.teacherId !== req.userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const stats = await prisma.attendance.groupBy({
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
  } catch (error: any) {
    console.error('Get stats error:', error);
    res.status(500).json({ error: 'Failed to get statistics' });
  }
});

export default router;
