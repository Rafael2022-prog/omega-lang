# Multi-stage build for OMEGA Universal Blockchain Programming Language
# Pure Native Compiler - No external toolchain dependencies
# Optimized for production deployment with security best practices

# Build stage - using pure OMEGA native compiler
FROM alpine:3.18 AS builder

# Install build dependencies (minimal - no PowerShell, no Rust)
RUN apk add --no-cache \
    musl-dev \
    gcc \
    g++ \
    make \
    git \
    ca-certificates

# Create app user
RUN addgroup -g 1000 omega && \
    adduser -D -s /bin/sh -u 1000 -G omega omega

# Set working directory
WORKDIR /app

# Copy source files for OMEGA pure native compiler
COPY omega ./bin/omega
COPY src/ ./src/
COPY omega.toml ./omega.toml
COPY bootstrap.mega ./bootstrap.mega

# Build OMEGA compiler (pure native, cross-platform)
RUN chmod +x ./bin/omega && \
    ./bin/omega --version && \
    ./bin/omega compile bootstrap.mega

# Copy documentation and examples
COPY README.md ./
COPY CONTRIBUTING.md ./
COPY examples/ ./examples/
COPY docs/ ./docs/

# Runtime stage
FROM alpine:3.18

# Install minimal runtime dependencies (no PowerShell needed)
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    tini

# Create non-root user
RUN addgroup -g 1000 omega && \
    adduser -D -s /bin/sh -u 1000 -G omega omega

# Create necessary directories
RUN mkdir -p /app/bin /app/lib /app/examples /app/docs && \
    chown -R omega:omega /app

# Copy binary from builder stage
COPY --from=builder /app/bin/omega /app/bin/omega
COPY --from=builder /app/bootstrap.mega /app/lib/bootstrap.mega

# Copy standard library and examples
COPY --from=builder /app/examples/ /app/examples/
COPY --from=builder /app/docs/ /app/docs/

# Set permissions
RUN chmod +x /app/bin/omega

# Create symlink for global access
RUN ln -s /app/bin/omega /usr/local/bin/omega

# Switch to non-root user
USER omega

# Set working directory
WORKDIR /app

# Set environment variables
ENV PATH="/app/bin:${PATH}"
ENV OMEGA_HOME="/app"
ENV OMEGA_LIB_PATH="/app/lib"

# Expose port for web interface (if applicable)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD omega --version || exit 1

# Use tini as init system
ENTRYPOINT ["/sbin/tini", "--"]

# Default command
CMD ["omega", "--help"]

# Labels for metadata
LABEL maintainer="OMEGA Team <team@omega-lang.org>" \
      version="2.0.0" \
      description="OMEGA Pure Native Blockchain Programming Language Compiler" \
      org.opencontainers.image.title="OMEGA Compiler" \
      org.opencontainers.image.description="Pure native cross-platform blockchain programming language compiler" \
      org.opencontainers.image.version="2.0.0" \
      org.opencontainers.image.vendor="OMEGA Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/Rafael2022-prog/omega-lang" \
      org.opencontainers.image.documentation="https://docs.omega-lang.org"