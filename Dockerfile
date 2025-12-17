# syntax=docker/dockerfile:1

# Stage 1: Builder
FROM python:3.13-slim-bookworm AS builder

WORKDIR /app

# Configura o APT para ser mais resiliente a falhas de rede (DNS/Timeouts)
# Removemos o 'docker-clean' para garantir que o cache do APT persista entre builds
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::http::Timeout "20";' >> /etc/apt/apt.conf.d/80-retries

# Instala dependências do sistema
# CORREÇÃO: Removemos o cache de /var/lib/apt para evitar o erro de "directory missing".
# Mantemos apenas /var/cache/apt para não baixar os .deb novamente.
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev

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

# Configurações de rede para o estágio final
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries

# Instala dependências de runtime
# Aqui usamos 'rm -rf /var/lib/apt/lists/*' no final para limpar o que foi baixado NESTA camada,
# mantendo a imagem final leve.
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
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

# Troca para usuário seguro
USER falai

# Variáveis de ambiente
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Comando de execução
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]