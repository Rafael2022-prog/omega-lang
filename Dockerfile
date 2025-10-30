# Multi-stage build for OMEGA Universal Blockchain Programming Language
# Optimized for production deployment with security best practices

# Build stage
FROM rust:1.70-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    musl-dev \
    openssl-dev \
    pkgconfig \
    git \
    ca-certificates

# Create app user
RUN addgroup -g 1000 omega && \
    adduser -D -s /bin/sh -u 1000 -G omega omega

# Set working directory
WORKDIR /app

# Copy dependency files first for better caching
COPY Cargo.toml Cargo.lock ./

# Create dummy main.rs to build dependencies
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copy source code
COPY src/ ./src/
COPY docs/ ./docs/
COPY examples/ ./examples/
COPY test_suites/ ./test_suites/

# Build OMEGA compiler
RUN cargo build --release --target x86_64-unknown-linux-musl

# Verify the binary works
RUN ./target/x86_64-unknown-linux-musl/release/omega --version

# Runtime stage
FROM alpine:3.18

# Install runtime dependencies
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
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/omega /app/bin/omega

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
ENV RUST_LOG="info"
ENV RUST_BACKTRACE="1"

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
      version="1.0.0" \
      description="OMEGA Universal Blockchain Programming Language Compiler" \
      org.opencontainers.image.title="OMEGA Compiler" \
      org.opencontainers.image.description="Universal blockchain programming language compiler" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="OMEGA Team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/omega-lang/omega" \
      org.opencontainers.image.documentation="https://docs.omega-lang.org"