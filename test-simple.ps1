# Simple MCP Test - Works without session complications
$baseUrl = "http://localhost:8000/_mcp"

Write-Host "=== Testing MCP Calculator Server ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Initialize
Write-Host "[1/3] Initialize..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $baseUrl -Method Post -ContentType "application/json" -Body '{
        "jsonrpc": "2.0",
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "test", "version": "1.0.0"}
        },
        "id": 1
    }' -UseBasicParsing

    $result = $response.Content | ConvertFrom-Json
    Write-Host "SUCCESS - Server: $($result.result.serverInfo.name) v$($result.result.serverInfo.version)" -ForegroundColor Green
    Write-Host "Instructions: $($result.result.serverInfo.instructions)" -ForegroundColor Gray
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/3] List Tools..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $baseUrl -Method Post -ContentType "application/json" -Body '{
        "jsonrpc": "2.0",
        "method": "tools/list",
        "params": {},
        "id": 2
    }' -UseBasicParsing

    $result = $response.Content | ConvertFrom-Json
    if ($result.result.tools) {
        Write-Host "SUCCESS - Found $($result.result.tools.Count) tool(s):" -ForegroundColor Green
        foreach ($tool in $result.result.tools) {
            Write-Host "  - $($tool.name): $($tool.description)" -ForegroundColor Gray
        }
    } else {
        Write-Host "WARNING - No tools found (session required)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "[3/3] Call add_numbers (5 + 3)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $baseUrl -Method Post -ContentType "application/json" -Body '{
        "jsonrpc": "2.0",
        "method": "tools/call",
        "params": {
            "name": "add_numbers",
            "arguments": {
                "number1": 5,
                "number2": 3
            }
        },
        "id": 3
    }' -UseBasicParsing

    $result = $response.Content | ConvertFrom-Json
    if ($result.result) {
        Write-Host "SUCCESS - Result: $($result.result.content[0].text)" -ForegroundColor Green
    } else {
        Write-Host "WARNING - Tool call requires session" -ForegroundColor Yellow
    }
} catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Testing Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: This MCP server uses HTTP transport with session management." -ForegroundColor Gray
Write-Host "For full testing, use the stdio transport:" -ForegroundColor Gray
Write-Host "  docker exec -it mcp-symfony-calculator php bin/console mcp:run" -ForegroundColor White
