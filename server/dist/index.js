"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const auth_routes_1 = __importDefault(require("./routes/auth.routes"));
const group_routes_1 = __importDefault(require("./routes/group.routes"));
const student_routes_1 = __importDefault(require("./routes/student.routes"));
const lesson_routes_1 = __importDefault(require("./routes/lesson.routes"));
const attendance_routes_1 = __importDefault(require("./routes/attendance.routes"));
// Load environment variables
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
process.on('uncaughtException', (err) => {
    console.error('🔥 Uncaught Exception:', err);
});
process.on('unhandledRejection', (reason, promise) => {
    console.error('🔥 Unhandled Rejection at:', promise, 'reason:', reason);
});
process.on('exit', (code) => {
    console.log('🛑 Process exiting with code:', code);
});
// Middleware
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use(express_1.default.urlencoded({ extended: true }));
// Health check
app.get('/', (req, res) => {
    res.json({
        message: 'Smart Attendance API Server',
        status: 'running',
        timestamp: new Date().toISOString()
    });
});
// Routes
app.use('/api/auth', auth_routes_1.default);
app.use('/api/groups', group_routes_1.default);
app.use('/api/students', student_routes_1.default);
app.use('/api/lessons', lesson_routes_1.default);
app.use('/api/attendance', attendance_routes_1.default);
// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(err.status || 500).json({
        error: err.message || 'Internal Server Error',
        status: err.status || 500
    });
});
// Start server
const server = app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log(`📊 Database: ${process.env.DATABASE_URL ? 'Connected' : 'Not configured'}`);
});
setInterval(() => {
    console.log('Tick to keep event loop alive...');
}, 5000);
