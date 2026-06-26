# ==========================================
# Stage 1: Build dependencies and packages
# ==========================================
FROM registry.access.redhat.com/ubi8/python-311 AS builder

USER root
WORKDIR /build

# Copy collection files (required by MCP server discovery)
COPY galaxy.yml ./galaxy.yml
COPY plugins/ ./plugins/

# Copy workspaces from the repository layout
COPY packages/sdk/ ./packages/sdk/
COPY packages/mcp-server/ ./packages/mcp-server/

# Build wheels for the SDK and the MCP server packages
RUN pip install --upgrade pip build && \
    python -m build --wheel --outdir /build/dist ./packages/sdk && \
    python -m build --wheel --outdir /build/dist ./packages/mcp-server

# ==========================================
# Stage 2: Final Runtime Image
# ==========================================
FROM registry.access.redhat.com/ubi8/python-311

LABEL maintainer="Ansible Platform Team" \
      summary="Model Context Protocol (MCP) server for AI-agent access to AAP Gateway" \
      description="Exposes idempotent ansible.platform SDK capabilities natively to AI tools."

USER root
WORKDIR /app

# Copy collection files for MCP server discovery
COPY --from=builder /build/galaxy.yml ./galaxy.yml
COPY --from=builder /build/plugins ./plugins/

# Copy the built wheels from the builder stage
COPY --from=builder /build/dist /app/dist

# Install the generated wheels along with required MCP runtime dependencies
RUN pip install --no-cache-dir /app/dist/*.whl && \
    rm -rf /app/dist

# Link collection files for MCP server discovery from site-packages
RUN ln -s /app/galaxy.yml /opt/app-root/lib64/python3.11/site-packages/ansible_collections/ansible/platform/../../../../../../galaxy.yml && \
    ln -s /app/plugins /opt/app-root/lib64/python3.11/site-packages/ansible_collections/ansible/platform/../../../../../../plugins

# Switch to standard non-privileged user for security compliance
USER 1001

# The MCP server operates natively over stdio transport layer
ENTRYPOINT ["python", "-m", "ansible_platform_mcp.server"]
