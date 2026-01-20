@echo off
echo ========================================
echo MCP Symfony Calculator - Quick Start
echo ========================================
echo.

echo [1/3] Checking Docker...
docker --version
if errorlevel 1 (
    echo ERROR: Docker is not running!
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

echo.
echo [2/3] Building and starting containers...
docker-compose up --build -d

echo.
echo [3/3] Waiting for server to be ready...
timeout /t 5 /nobreak > nul

echo.
echo ========================================
echo ✅ MCP Server is running!
echo ========================================
echo.
echo 📍 MCP Endpoint: http://localhost:8000/_mcp
echo.
echo 🧪 Test with MCP Inspector:
echo    npx @modelcontextprotocol/inspector
echo.
echo 📖 Check README.md for more details
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

docker-compose logs -f
