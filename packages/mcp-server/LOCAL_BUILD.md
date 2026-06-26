# Local Build & Installation Guide

## Prerequisites

- Python 3.11+ (uv handles venv creation)
- [uv](https://github.com/astral-sh/uv) package manager
- Claude Code CLI
- AAP Gateway credentials

## Installation

### 1. Clone Repository

```bash
git clone github.com:chadmf/ansible.platform.git
cd ansible.platform
```

### 2. Install MCP Server + SDK

```bash
cd packages/mcp-server

# Create venv
uv venv

# Activate venv
source .venv/bin/activate

# Install SDK + MCP server in editable mode
uv pip install -e ../sdk -e .
```

Verify installation:

```bash
ansible-platform-mcp --version
# Should output: ansible-platform MCP server v0.1.0
```

### 3. Configure Environment Variables

Add to `~/.zshrc` or `~/.bashrc`:

```bash
export AAP_GATEWAY_URL="https://your-aap-gateway.example.com"
export AAP_USERNAME="your-username"
export AAP_PASSWORD="your-password"
```

Reload:

```bash
source ~/.zshrc  # or ~/.bashrc
```

### 4. Configure Claude Code MCP

Edit `~/.claude/mcp.json`:

```json
{
  "mcpServers": {
    "ansible-platform": {
      "type": "stdio",
      "command": "/absolute/path/to/ansible.platform/packages/mcp-server/.venv/bin/ansible-platform-mcp",
      "env": {
        "AAP_GATEWAY_URL": "${env:AAP_GATEWAY_URL}",
        "AAP_USERNAME": "${env:AAP_USERNAME}",
        "AAP_PASSWORD": "${env:AAP_PASSWORD}"
      }
    }
  }
}
```

**Replace `/absolute/path/to/`** with your actual clone location (e.g., `/Users/yourname/Documents/GitHub/`).

### 5. Restart Claude Code

```bash
# Exit current session
/exit

# Restart Claude Code
claude
```

## Verification

Check MCP server loaded:

```bash
# In Claude Code session
/mcp list
```

Should see `ansible-platform` with 22 tools.

Test a tool:

```text
list all ansible jobs
```

## Troubleshooting

### MCP Server Not Appearing

1. Verify absolute path in mcp.json is correct
2. Check env vars set: `echo $AAP_GATEWAY_URL`
3. Test standalone: 
   ```bash
   /absolute/path/to/.venv/bin/ansible-platform-mcp
   # Paste: {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "test", "version": "1.0"}}}
   # Should return: {"jsonrpc":"2.0","id":1,"result":{...}}
   ```

### Import Errors

Reinstall both packages:

```bash
cd packages/mcp-server
source .venv/bin/activate
uv pip install -e ../sdk -e . --force-reinstall
```

### Credentials Issues

Test AAP Gateway access:

```bash
curl -u "$AAP_USERNAME:$AAP_PASSWORD" "$AAP_GATEWAY_URL/api/v1/"
```

Should return JSON response, not 401/403.

## Development Workflow

When editing SDK or MCP code, changes apply immediately (editable install). Restart Claude Code to reload:

```bash
/exit
claude
```

## Why Native Install > Container?

- **macOS stdio flakiness**: Podman stdio pipes unreliable on macOS
- **Faster startup**: No container overhead
- **Live edits**: Changes apply immediately
- **Debugging**: Can attach debugger, add print statements

Container still useful for CI/CD and distribution.
