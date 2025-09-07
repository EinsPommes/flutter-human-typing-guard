# Multi-stage build for Typing Guard Service
FROM rust:1.75-slim as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy manifest files
COPY Cargo.toml Cargo.lock ./

# Copy source code
COPY src ./src
COPY config ./config

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -r -s /bin/false typingguard

# Set working directory
WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/target/release/typing-guard-svc /app/typing-guard-svc

# Copy configuration
COPY --from=builder /app/config /app/config

# Change ownership
RUN chown -R typingguard:typingguard /app

# Switch to non-root user
USER typingguard

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

# Run the application
CMD ["./typing-guard-svc"]
