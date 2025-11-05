# Smart Attendance API Server

Backend REST API server with Prisma and PostgreSQL for the Smart Attendance application.

## Setup Instructions

### 1. Install Dependencies
```bash
cd server
npm install
```

### 2. Configure Environment Variables
Create a `.env` file in the server directory:
```bash
DATABASE_URL="postgresql://postgres:2008181@localhost:5432/test2"
JWT_SECRET="your-secret-key-change-this-in-production"
PORT=3000
```

### 3. Generate Prisma Client
```bash
npm run prisma:generate
```

### 4. Run Database Migrations
```bash
npm run prisma:migrate
```

### 5. Start Development Server
```bash
npm run dev
```

The server will be running at `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - Logout user

### Groups
- `POST /api/groups` - Create group (teacher only)
- `GET /api/groups/my-groups` - Get teacher's groups
- `GET /api/groups/:id` - Get group by ID
- `PUT /api/groups/:id` - Update group (teacher only)
- `DELETE /api/groups/:id` - Delete group (teacher only)

### Students
- `POST /api/students` - Create student (teacher only)
- `GET /api/students/group/:groupId` - Get students in group
- `GET /api/students/:id` - Get student by ID
- `PUT /api/students/:id` - Update student (teacher only)
- `DELETE /api/students/:id` - Delete student (teacher only)

### Lessons
- `POST /api/lessons` - Create lesson (teacher only)
- `GET /api/lessons/group/:groupId` - Get lessons for group
- `GET /api/lessons/:id` - Get lesson by ID
- `PUT /api/lessons/:id` - Update lesson (teacher only)
- `DELETE /api/lessons/:id` - Delete lesson (teacher only)

### Attendance
- `POST /api/attendance` - Mark attendance
- `GET /api/attendance/lesson/:lessonId` - Get attendance for lesson
- `GET /api/attendance/student/:studentId` - Get student attendance
- `PUT /api/attendance/:id` - Update attendance (teacher only)
- `DELETE /api/attendance/:id` - Delete attendance (teacher only)
- `GET /api/attendance/stats/group/:groupId` - Get group statistics

## Database Schema

- **Users** - User accounts (teachers and students)
- **Students** - Student profiles
- **Groups** - Class groups
- **Lessons** - Class sessions
- **Attendance** - Attendance records
