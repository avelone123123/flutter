import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import axios from 'axios';
dotenv.config();

async function test() {
    const token = jwt.sign(
        { userId: 'test-user', role: 'teacher' },
        process.env.JWT_SECRET || 'secret'
    );

    try {
        const res = await axios.get('http://localhost:3000/api/lessons/active', {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log('SUCCESS', res.data);
    } catch (err: any) {
        console.log('ERROR', err.response?.data || err.message);
    }
}
test();
