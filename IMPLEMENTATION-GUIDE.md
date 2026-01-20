# MCP Server Implementation with Symfony

## Introduction

Model Context Protocol (MCP) is a standard protocol for communication between applications and AI models, enabling AI assistants to securely and structurally access external tools and resources.

This document describes the implementation of an MCP server using the Symfony PHP Framework.

## Prerequisites

- Docker and Docker Compose
- PHP 8.3 or higher
- Composer 2.x
- Symfony 7.3

## Architecture

```
mcp-symfony-poc/
├── config/
│   ├── packages/
│   │   └── mcp.yaml          # MCP bundle configuration
│   └── routes/
│       └── mcp.yaml          # MCP server routes
├── src/
│   └── Mcp/
│       └── Tools/
│           └── AddNumbers.php # Example tool
├── docker-compose.yml
└── Dockerfile
```

## Implementation Process

### 1. Clone the Repository

```bash
git clone https://github.com/juamecos/mcp-symfony-poc.git
cd mcp-symfony-poc
```

### 2. Install Dependencies

**⚠️ IMPORTANT:** Install Composer dependencies on your local machine BEFORE building Docker container:

```bash
composer install --ignore-platform-reqs
```

**Why?** The `docker-compose.yml` uses a volume mount (`.:/app`) that shares files between your host machine and the container. When you install dependencies locally, they're immediately available inside the container.

**If you don't have Composer installed locally:**

Option A - Install Composer: https://getcomposer.org/download/

Option B - Use Docker to install:
```bash
docker run --rm -v $(pwd):/app composer install --ignore-platform-reqs
```

### 3. Build and Start Container

```json
{
  "require": {
    "php": ">=8.2",
    "symfony/framework-bundle": "7.3.*",
    "symfony/mcp-bundle": "dev-main",
    "nyholm/psr7": "^1.8"
  }
### 3. Build and Start Container

```bash
# Build and start the Docker container
docker-compose up --build

# Or run in detached mode
docker-compose up -d --build
```

The server will be available at `http://localhost:8000/_mcp`

**Verify it's running:**
```bash
docker ps | grep mcp-symfony-calculator
```

### 4. Project Structure

The project includes the necessary dependencies:

File: `config/packages/mcp.yaml`

```yaml
mcp:
  app: "Calculator MCP Server"
  version: "1.0.0"
  instructions: "Calculator server with basic operations"
  client_transports:
    stdio: true    # For console use
    http: true     # For HTTP use
  http:
    path: "/_mcp"
    session:
      store: memory
```

### 5. Routes Configuration

File: `config/routes/mcp.yaml`

```yaml
mcp:
  resource: .
  type: mcp
```

### 6. Tool Implementation

Tools are implemented as PHP classes with the `#[McpTool]` attribute:

```php
<?php

namespace App\Mcp\Tools;

use Mcp\Capability\Attribute\McpTool;

class AddNumbers
{
    #[McpTool(
        name: 'add_numbers',
        description: 'Add two numbers and return the result'
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
}
```

### 7. Containerization with Docker

**Dockerfile:**

```dockerfile
FROM php:8.3-cli

RUN apt-get update && apt-get install -y git unzip libzip-dev \
    && docker-php-ext-install zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . /app

RUN composer install --no-interaction --optimize-autoloader

EXPOSE 8000
CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]
```

**docker-compose.yml:**

```yaml
services:
  symfony-mcp:
    build: .
    container_name: mcp-symfony-calculator
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    environment:
      - APP_ENV=dev
      - APP_DEBUG=1
      - DEFAULT_URI=http://localhost
```

## Deployment and Testing

### Start the Server

```bash
# Build and start container
docker-compose up -d

# Verify container is running
docker-compose ps
```

### Test the Server

**Option 1: Console Mode (stdio)**

```bash
docker exec -it mcp-symfony-calculator php bin/console mcp:server
```

Send JSON-RPC commands:

```json
{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}

{"jsonrpc":"2.0","method":"tools/list","params":{},"id":2}

{"jsonrpc":"2.0","method":"tools/call","params":{"name":"add_numbers","arguments":{"number1":5,"number2":7}},"id":3}
```

**Option 2: HTTP Endpoint**

```bash
curl -X POST http://localhost:8000/_mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}'
```

### Verify Registered Tools

```bash
docker exec mcp-symfony-calculator php bin/console debug:container --tag=mcp.tool
```

## Integration with Claude Desktop

### Configuration

1. **Create or edit the configuration file:**
   - Windows: `%APPDATA%\Claude\claude_desktop_config.json`
   - macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Linux: `~/.config/Claude/claude_desktop_config.json`

2. **Add the following configuration:**

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

3. **Restart Claude Desktop:**
   - Close Claude completely (Ctrl+Q on Windows, Cmd+Q on macOS)
   - Reopen Claude Desktop
   - The server should be available

4. **Test the integration:**
   - Ask Claude: "Can you add 15 and 27 using your tools?"
   - Claude should use the `add_numbers` tool from the symfony-calculator server

### Troubleshooting

- If the server doesn't appear, check that:
  - The Docker container is running: `docker ps | grep mcp-symfony-calculator`
  - The JSON configuration file is valid
  - Claude Desktop is version 0.7.0 or higher
- View Claude Desktop logs: Menu → Settings → Developer → View Logs

## Production Considerations

1. **Security**: Implement authentication and authorization for HTTP endpoints
2. **Logging**: Configure Monolog to capture MCP events
3. **Scalability**: Use Redis for session store instead of memory
4. **Monitoring**: Implement health checks and metrics
5. **Documentation**: Maintain up-to-date documentation of all available tools

## Conclusion

Implementing an MCP server with Symfony provides a solid and extensible foundation for integrating AI capabilities into enterprise applications. The use of PHP attributes facilitates automatic tool registration, and support for multiple transports (stdio/HTTP) allows flexibility in different usage scenarios.

## References

- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Symfony MCP Bundle](https://github.com/symfony/mcp-bundle)
- [MCP SDK PHP](https://github.com/modelcontextprotocol/php-sdk)
