# Troubleshooting Guide

## Common Issues and Solutions

### ❌ Problem: `docker-compose up --build` fails with composer errors

**Symptoms:**
```
composer install failed!
```

**Solutions:**

#### Solution 1: Install dependencies locally first (Recommended)

```bash
# Before running docker-compose, install dependencies on your host machine
composer install --ignore-platform-reqs

# Then build and run Docker
docker-compose up --build
```

**Why this works:** The volume mount in `docker-compose.yml` shares the `vendor` directory between host and container.

#### Solution 2: Build without cache

```bash
# Clean everything
docker-compose down -v
docker system prune -f

# Rebuild from scratch
docker-compose build --no-cache
docker-compose up
```

#### Solution 3: Two-stage approach

```bash
# Step 1: Build image
docker-compose build

# Step 2: Install dependencies inside container
docker-compose run --rm symfony-mcp composer install --ignore-platform-reqs

# Step 3: Start server
docker-compose up
```

---

### ❌ Problem: Port 8000 already in use

**Symptoms:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:8000: bind: address already in use
```

**Solutions:**

#### Option 1: Change port in docker-compose.yml

```yaml
ports:
  - "8080:8000"  # Use port 8080 instead
```

#### Option 2: Stop process using port 8000

**Windows:**
```powershell
# Find process using port 8000
netstat -ano | findstr :8000

# Kill the process (replace <PID> with actual process ID)
taskkill /PID <PID> /F
```

**Linux/Mac:**
```bash
# Find and kill process
lsof -ti:8000 | xargs kill -9
```

---

### ❌ Problem: Container starts but server doesn't respond

**Symptoms:**
- Container is running (`docker ps` shows it)
- But `curl http://localhost:8000/_mcp` fails

**Solutions:**

#### Check container logs
```bash
docker-compose logs -f
```

#### Verify container is actually running
```bash
docker ps | grep mcp-symfony-calculator
```

#### Test inside the container
```bash
# Access container shell
docker exec -it mcp-symfony-calculator bash

# Test server locally
php bin/console mcp:server
```

#### Restart container
```bash
docker-compose restart
```

---

### ❌ Problem: Missing vendor/autoload.php

**Symptoms:**
```
Fatal error: require(/app/vendor/autoload.php): failed to open stream: No such file or directory
```

**Solution:**

```bash
# Install dependencies
composer install --ignore-platform-reqs

# Or inside container
docker exec -it mcp-symfony-calculator composer install --ignore-platform-reqs

# Restart container
docker-compose restart
```

---

### ❌ Problem: PHP extensions missing

**Symptoms:**
```
requires ext-zip
requires ext-simplexml
```

**Solution:**

The Dockerfile already includes required extensions. If you're running locally without Docker:

**Windows (with XAMPP/WAMP):**
Edit `php.ini` and enable:
```ini
extension=zip
extension=simplexml
extension=dom
```

**Linux:**
```bash
sudo apt-get install php-zip php-xml php-mbstring
```

**Mac:**
```bash
brew install php
pecl install zip
```

---

### ❌ Problem: Claude Desktop doesn't see the server

**Symptoms:**
- Container is running
- But Claude Desktop shows "No tools available"

**Solutions:**

#### 1. Verify configuration file location

**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
**Mac:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Linux:** `~/.config/Claude/claude_desktop_config.json`

#### 2. Correct configuration format

```json
{
  "mcpServers": {
    "symfony-calculator": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-symfony-calculator", "php", "bin/console", "mcp:server"]
    }
  }
}
```

#### 3. Verify container name

```bash
# Check actual container name
docker ps --format "{{.Names}}"

# Should show: mcp-symfony-calculator
# If different, update config with correct name
```

#### 4. Restart Claude Desktop completely

**Windows:** Press `Ctrl+Q` to quit, then reopen
**Mac:** Press `Cmd+Q` to quit, then reopen

#### 5. Check Claude Desktop logs

- Open Claude Desktop
- Go to: Settings → Developer → View Logs
- Look for errors related to MCP servers

---

### ❌ Problem: Permission denied errors (Linux/Mac)

**Symptoms:**
```
Permission denied: /app/var/cache
```

**Solutions:**

```bash
# Fix permissions
sudo chown -R $USER:$USER .

# Or run with proper user in docker-compose.yml
services:
  symfony-mcp:
    user: "${UID}:${GID}"
```

---

### ❌ Problem: Tool not found in debug:container

**Symptoms:**
```bash
docker exec mcp-symfony-calculator php bin/console debug:container --tag=mcp.tool
# Shows: No services found
```

**Solutions:**

#### 1. Verify attribute is correct

File: `src/Mcp/Tools/AddNumbers.php`

```php
use Mcp\Capability\Attribute\McpTool; // ✅ Correct

#[McpTool(name: 'add_numbers', description: '...')]
public function add(...) {}
```

**Common mistake:**
```php
use Mcp\Tool; // ❌ Wrong - this doesn't exist
```

#### 2. Clear cache

```bash
docker exec mcp-symfony-calculator php bin/console cache:clear
docker-compose restart
```

#### 3. Verify bundle is enabled

File: `config/bundles.php`

```php
return [
    Symfony\Bundle\FrameworkBundle\FrameworkBundle::class => ['all' => true],
    Mcp\Bundle\McpBundle\McpBundle::class => ['all' => true],
];
```

---

## Quick Diagnostic Script

Run this to check your setup:

```bash
#!/bin/bash

echo "=== MCP Symfony POC Diagnostics ==="

echo -e "\n1. Checking Docker..."
docker --version

echo -e "\n2. Checking container..."
docker ps | grep mcp-symfony-calculator

echo -e "\n3. Checking vendor directory..."
if [ -d "vendor" ]; then
    echo "✅ vendor directory exists"
else
    echo "❌ vendor directory missing - run: composer install --ignore-platform-reqs"
fi

echo -e "\n4. Checking composer.lock..."
if [ -f "composer.lock" ]; then
    echo "✅ composer.lock exists"
else
    echo "❌ composer.lock missing"
fi

echo -e "\n5. Testing server endpoint..."
curl -s http://localhost:8000/_mcp | head -n 5

echo -e "\n6. Checking registered tools..."
docker exec mcp-symfony-calculator php bin/console debug:container --tag=mcp.tool

echo -e "\n=== Diagnostics Complete ==="
```

**Windows PowerShell version:**

```powershell
Write-Host "=== MCP Symfony POC Diagnostics ===" -ForegroundColor Cyan

Write-Host "`n1. Checking Docker..." -ForegroundColor Yellow
docker --version

Write-Host "`n2. Checking container..." -ForegroundColor Yellow
docker ps | Select-String "mcp-symfony-calculator"

Write-Host "`n3. Checking vendor directory..." -ForegroundColor Yellow
if (Test-Path "vendor") {
    Write-Host "✅ vendor directory exists" -ForegroundColor Green
} else {
    Write-Host "❌ vendor directory missing - run: composer install --ignore-platform-reqs" -ForegroundColor Red
}

Write-Host "`n4. Checking composer.lock..." -ForegroundColor Yellow
if (Test-Path "composer.lock") {
    Write-Host "✅ composer.lock exists" -ForegroundColor Green
} else {
    Write-Host "❌ composer.lock missing" -ForegroundColor Red
}

Write-Host "`n5. Testing server endpoint..." -ForegroundColor Yellow
curl http://localhost:8000/_mcp

Write-Host "`n6. Checking registered tools..." -ForegroundColor Yellow
docker exec mcp-symfony-calculator php bin/console debug:container --tag=mcp.tool

Write-Host "`n=== Diagnostics Complete ===" -ForegroundColor Cyan
```

---

## Getting Help

If none of these solutions work:

1. **Collect diagnostic information:**
   ```bash
   docker-compose logs > logs.txt
   docker inspect mcp-symfony-calculator > inspect.txt
   ```

2. **Check versions:**
   ```bash
   docker --version
   docker-compose --version
   php --version
   composer --version
   ```

3. **Create an issue with:**
   - Error message (full output)
   - Docker logs
   - Your OS and versions
   - Steps you've already tried

---

## Prevention Checklist

Before sharing with colleagues, ensure:

- ✅ `composer.lock` is committed to git
- ✅ `vendor/` is in `.gitignore`
- ✅ README has clear step-by-step instructions
- ✅ Docker and docker-compose versions are documented
- ✅ Port 8000 is available or alternative is documented
- ✅ All required files are committed (Dockerfile, docker-compose.yml, etc.)
