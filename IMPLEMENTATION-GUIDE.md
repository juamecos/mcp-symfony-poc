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

### 1. Project Setup

Create a Symfony project with the necessary dependencies:

```json
{
  "require": {
    "php": ">=8.2",
    "symfony/framework-bundle": "7.3.*",
    "symfony/mcp-bundle": "dev-main",
    "nyholm/psr7": "^1.8"
  }
}
```

### 2. MCP Bundle Configuration

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

### 3. Routes Configuration

File: `config/routes/mcp.yaml`

```yaml
mcp:
  resource: .
  type: mcp
```

### 4. Tool Implementation

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

### 5. Containerization with Docker

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

Configure in `%APPDATA%\Claude\claude_desktop_config.json`:

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

Restart Claude Desktop to apply the configuration.

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
