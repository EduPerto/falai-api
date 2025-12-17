# syntax=docker/dockerfile:1

# Stage 1: Builder - Instala dependências e compila
# Usamos 'bookworm' explicitamente para garantir estabilidade (evita repositórios instáveis)
FROM python:3.13-slim-bookworm AS builder

WORKDIR /app

# Configura o APT para ser mais resiliente a falhas de rede
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::http::Timeout "20";' >> /etc/apt/apt.conf.d/80-retries

# Instala dependências do sistema com Cache Mount
# O cache em /var/cache/apt acelera builds futuros
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
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
# Isso salva muito tempo evitando baixar rodas (wheels) repetidamente
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install greenlet && \
    pip install -e .

# Stage 2: Runtime - Imagem de produção mínima
FROM python:3.13-slim-bookworm

WORKDIR /app

# Configura retries para o APT no estágio final também
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries

# Instala dependências de runtime
# O 'rm -rf' é mantido aqui para manter a imagem final pequena
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copia o venv do builder
COPY --from=builder /opt/venv /opt/venv

# Copia código da aplicação e scripts
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

# Health check (Mantido conforme original)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Comando de execução
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]