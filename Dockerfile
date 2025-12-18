# syntax=docker/dockerfile:1

# Stage 1: Builder
FROM python:3.13-slim-bookworm AS builder

WORKDIR /app

# Install system dependencies with multiple mirror fallbacks
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    # Try standard mirror first
    (apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev) || \
    # Fallback 1: US mirror
    (echo "deb http://ftp.us.debian.org/debian bookworm main" > /etc/apt/sources.list && \
     echo "deb http://ftp.us.debian.org/debian bookworm-updates main" >> /etc/apt/sources.list && \
     echo "deb http://security.debian.org/debian-security bookworm-security main" >> /etc/apt/sources.list && \
     apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev) || \
    # Fallback 2: Cloudflare mirror
    (echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list && \
     apt-get -o Acquire::http::Proxy="false" update && \
     apt-get install -y --no-install-recommends gcc libpq-dev) \
    && rm -rf /var/lib/apt/lists/*

# Copia arquivos de dependência
COPY pyproject.toml setup.py ./
COPY src ./src

# Cria venv
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Instala dependências Python com Cache Mount do PIP
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install greenlet && \
    pip install -e .

# Stage 2: Runtime
FROM python:3.13-slim-bookworm

WORKDIR /app

# Install runtime dependencies with multiple mirror fallbacks
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    # Try standard mirror first
    (apt-get update && apt-get install -y --no-install-recommends libpq5 curl) || \
    # Fallback 1: US mirror
    (echo "deb http://ftp.us.debian.org/debian bookworm main" > /etc/apt/sources.list && \
     echo "deb http://ftp.us.debian.org/debian bookworm-updates main" >> /etc/apt/sources.list && \
     echo "deb http://security.debian.org/debian-security bookworm-security main" >> /etc/apt/sources.list && \
     apt-get update && apt-get install -y --no-install-recommends libpq5 curl) || \
    # Fallback 2: Cloudflare mirror
    (echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list && \
     apt-get -o Acquire::http::Proxy="false" update && \
     apt-get install -y --no-install-recommends libpq5 curl) \
    && rm -rf /var/lib/apt/lists/*

# Copia o venv do builder
COPY --from=builder /opt/venv /opt/venv

# Copia código da aplicação
COPY src ./src
COPY migrations ./migrations
COPY alembic.ini ./
COPY scripts ./scripts

# Cria usuário não-root
RUN groupadd --system falai && useradd --system --gid falai falai && \
    chown -R falai:falai /app

USER falai

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]