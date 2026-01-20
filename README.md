# MCP Symfony Calculator - POC

## 🎯 Objective

Simple MCP server with Symfony that exposes an endpoint to add two numbers.

## 📋 Requirements

- Docker Desktop
- Docker Compose

## 🚀 Installation and Execution

### Option 1: With Docker (Recommended)

```bash
# 1. Navigate to project directory
cd C:\projects\mcp-symfony-poc

# 2. Build and start container
docker-compose up --build

# 3. Server will be available at:
# http://localhost:8000/_mcp
```

### Option 2: Local (without Docker)

```bash
# 1. Install dependencies
composer install

# 2. Start server
php -S localhost:8000 -t public

# 3. Access at:
# http://localhost:8000/_mcp
```

## 🧪 Test the MCP

### With MCP Inspector

```bash
npx @modelcontextprotocol/inspector
```

1. URL: `http://localhost:8000/_mcp`
2. Type: `Streamable HTTP`
3. Click "Connect"
4. In "Tools" → "List Tools" you'll see: `add_numbers`
5. Test with:
   - number1: `5`
   - number2: `3`
6. Result: `{"result": 8, "operation": "5 + 3 = 8"}`

### With Claude Desktop / Cursor / Claude.ai

Configure in `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "calculator": {
      "url": "http://localhost:8000/_mcp",
      "transport": "streamable-http"
    }
  }
}
```

Then in the chat:
```
Use your tools to add 15 + 27
```

### With cURL (Direct HTTP)

```bash
# View server info
curl http://localhost:8000/_mcp

# Call the tool (requires full MCP protocol)
curl -X POST http://localhost:8000/_mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "add_numbers",
      "arguments": {
        "number1": 10,
        "number2": 20
      }
    },
    "id": 1
  }'
```

## 📁 Project Structure

```
mcp-symfony-poc/
├── config/
│   ├── packages/
│   │   ├── framework.yaml    # Symfony config
│   │   └── mcp.yaml          # MCP config
│   ├── bundles.php           # Registered bundles
│   ├── routes.yaml           # Routes (includes MCP)
│   └── services.yaml         # Services
├── public/
│   └── index.php             # Entry point
├── src/
│   ├── Kernel.php            # Symfony kernel
│   └── Mcp/
│       └── Tools/
│           └── AddNumbers.php # Addition tool
├── .env                      # Environment variables
├── composer.json             # Dependencies
├── docker-compose.yml        # Docker config
├── Dockerfile                # Docker image
└── README.md                 # This file
```

## 🔧 How It Works

### The Tool (src/Mcp/Tools/AddNumbers.php)

```php
#[Tool(
    name: 'add_numbers',
    description: 'Add two numbers together and return the result'
)]
public function add(int $number1, int $number2): array
{
    $result = $number1 + $number2;
    
    return [
        'number1' => $number1,
        'number2' => $number2,
        'result' => $result,
        'operation' => "$number1 + $number2 = $result"
    ];
}
```

### Key Points

1. **`#[Tool]` Attribute**: Defines the method as an MCP Tool
2. **Typed parameters**: `int $number1, int $number2`
3. **Return array**: Result is automatically serialized to JSON
4. **Auto route**: `/_mcp` (configured in routes.yaml)

## 🎓 MCP Concepts

### What is an MCP Server?

A server that exposes tools that AI agents can use.

### Components:

- **Tools**: Functions the agent can execute
- **Resources**: Data the agent can read
- **Prompts**: Predefined prompt templates

### Flow:

1. Agent asks: "What is 5 + 3?"
2. Agent detects available tool: `add_numbers`
3. Agent executes: `add_numbers(5, 3)`
4. MCP Server responds: `{"result": 8}`
5. Agent responds: "The result is 8"

## 🐛 Troubleshooting

### Error: "Composer not found"
```bash
# Install Composer globally
composer --version
```

### Error: "Port 8000 already in use"
```bash
# Change port in docker-compose.yml:
ports:
  - "8001:8000"  # Use 8001 instead of 8000
```

### Error: "Class 'Symfony\Bundle\McpBundle\McpBundle' not found"
```bash
# Reinstall dependencies
composer install --no-cache
```

### Docker won't start
```bash
# Verify Docker Desktop is running
docker --version
docker ps

# Rebuild image
docker-compose down
docker-compose up --build
```

## 📚 Next Steps

### Add more operations

Create `src/Mcp/Tools/MultiplyNumbers.php`:

```php
#[Tool(name: 'multiply_numbers')]
public function multiply(int $a, int $b): array
{
    return ['result' => $a * $b];
}
```

### Añadir validación
dd validation

```php
public function add(int $number1, int $number2): array
{
    if ($number1 > 1000000 || $number2 > 1000000) {
        throw new \InvalidArgumentException('Numbers too large');
    }
    
    return ['result' => $number1 + $number2];
}
```

### Connect to database

1. Install Doctrine: `composer require symfony/orm-pack`
2. Create entity
3. Use in Tool

## 🔗 Reference
- [Symfony MCP Bundle](https://github.com/symfony/mcp-bundle)
- [MCP Protocol Spec](https://spec.modelcontextprotocol.io/)
- [MCP Inspector](https://github.com/modelcontextprotocol/inspector)
- [Video Tutorial (Johan Dev)](https://www.youtube.com/watch?v=...)

## 📝 Important Notes

⚠️ **Minimum Stability**: composer.json has `"minimum-stability": "dev"` because MCP Bundle is not yet stable.

⚠️ **Autowiring**: Autowiring does NOT work in Tools. If you need dependencies, you must instantiate them manually with `new`.

⚠️ **PSR-7**: You need `nyholm/psr7` for HTTP transport to work.

✅ **Production**: For production, use a real web server (Nginx/Apache) instead of `php -S`.

---

**Project created by
