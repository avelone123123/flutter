@echo off
echo ====================================
echo Smart Attendance Backend Setup
echo ====================================
echo.

echo Step 1: Installing dependencies...
call npm install
if %errorlevel% neq 0 (
    echo Error installing dependencies
    pause
    exit /b %errorlevel%
)

echo.
echo Step 2: Generating Prisma Client...
call npm run prisma:generate
if %errorlevel% neq 0 (
    echo Error generating Prisma client
    pause
    exit /b %errorlevel%
)

echo.
echo Step 3: Running database migrations...
call npx prisma migrate dev --name init
if %errorlevel% neq 0 (
    echo Error running migrations
    echo Make sure PostgreSQL is running and .env file is configured
    pause
    exit /b %errorlevel%
)

echo.
echo ====================================
echo Setup completed successfully!
echo ====================================
echo.
echo To start the server, run: npm run dev
echo.
pause
