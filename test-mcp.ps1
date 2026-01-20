# Test MCP Server
$baseUrl = "http://localhost:8000/_mcp"

Write-Host "=== Testing MCP Calculator Server ===" -ForegroundColor Green

# 1. Initialize
Write-Host ""
Write-Host "1. Initializing session..." -ForegroundColor Yellow
$initBody = @{
    jsonrpc = "2.0"
    method = "initialize"
    params = @{
        protocolVersion = "2024-11-05"
        capabilities = @{}
        clientInfo = @{
            name = "test-client"
            version = "1.0.0"
        }
    }
    id = 1
} | ConvertTo-Json -Depth 10

$initResponse = Invoke-RestMethod -Uri $baseUrl -Method Post -Body $initBody -ContentType "application/json"
$initResponse | ConvertTo-Json -Depth 10
Write-Host "Server initialized" -ForegroundColor Green

# 2. List tools
Write-Host ""
Write-Host "2. Listing available tools..." -ForegroundColor Yellow
$listToolsBody = @{
    jsonrpc = "2.0"
    method = "tools/list"
    params = @{}
    id = 2
} | ConvertTo-Json -Depth 10

$toolsResponse = Invoke-RestMethod -Uri $baseUrl -Method Post -Body $listToolsBody -ContentType "application/json"
$toolsResponse | ConvertTo-Json -Depth 10
Write-Host "Tools listed" -ForegroundColor Green

# 3. Call add_numbers tool
Write-Host ""
Write-Host "3. Calling add_numbers tool (5 + 7)..." -ForegroundColor Yellow
$callToolBody = @{
    jsonrpc = "2.0"
    method = "tools/call"
    params = @{
        name = "add_numbers"
        arguments = @{
            number1 = 5
            number2 = 7
        }
    }
    id = 3
} | ConvertTo-Json -Depth 10

$callResponse = Invoke-RestMethod -Uri $baseUrl -Method Post -Body $callToolBody -ContentType "application/json"
$callResponse | ConvertTo-Json -Depth 10
Write-Host "Tool executed successfully" -ForegroundColor Green

Write-Host ""
Write-Host "=== All tests completed ===" -ForegroundColor Green
