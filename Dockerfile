# Multi-stage build for FalAI API (FastAPI + Python)
# Debian slim-based for better compatibility and DNS reliability

# Stage 1: Builder - Install dependencies
FROM python:3.13-slim AS builder

WORKDIR /app

# Install system dependencies (Debian uses apt)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files
COPY pyproject.toml setup.py ./
COPY src ./src

# Create virtual environment and install dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies including greenlet
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir greenlet && \
    pip install --no-cache-dir -e .

# Stage 2: Runtime - Minimal production image
FROM python:3.13-slim

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY src ./src
COPY migrations ./migrations
COPY alembic.ini ./
COPY scripts ./scripts

# Create non-root user for security
RUN groupadd --system falai && useradd --system --gid falai falai && \
    chown -R falai:falai /app

# Switch to non-root user
USER falai

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Run the application
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]