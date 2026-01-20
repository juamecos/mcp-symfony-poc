#!/bin/bash

# Test MCP Server
BASE_URL="http://localhost:8000/_mcp"

echo "1. Initialize session..."
INIT_RESPONSE=$(curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {
        "name": "test-client",
        "version": "1.0.0"
      }
    },
    "id": 1
  }')

echo "$INIT_RESPONSE" | jq .
SESSION_ID=$(echo "$INIT_RESPONSE" | jq -r '.result.sessionId // empty')

if [ -z "$SESSION_ID" ]; then
  echo "No session ID returned, trying without it..."
  SESSION_HEADER=""
else
  echo -e "\nSession ID: $SESSION_ID"
  SESSION_HEADER="-H \"Mcp-Session-Id: $SESSION_ID\""
fi

echo -e "\n2. List tools..."
curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  $SESSION_HEADER \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 2
  }' | jq .

echo -e "\n3. Call AddNumbers tool..."
curl -s -X POST "$BASE_URL" \
  -H "Content-Type: application/json" \
  $SESSION_HEADER \
  -d '{
    "jsonrpc": "2.0",
    "method": "tools/call",
    "params": {
      "name": "add_numbers",
      "arguments": {
        "a": 5,
        "b": 7
      }
    },
    "id": 3
  }' | jq .
