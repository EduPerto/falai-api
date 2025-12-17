# Deploy para EasyPanel - Guia Rápido

## Problema Identificado

O servidor EasyPanel está com **falha de DNS** que impede o download de pacotes durante o build do Docker. Isso afeta tanto repositórios Debian quanto Alpine.

## Solução: Build Local + Push para Registry

### Passo 1: Login no Docker Hub

```bash
docker login
```

Insira suas credenciais do Docker Hub. Se não tiver conta, crie em: https://hub.docker.com

### Passo 2: Fazer Build e Push

Na pasta `falai-api`, execute:

```bash
./build-and-push.sh
```

Ou manualmente:

```bash
# Build
docker build -t evoapicloud/falai-api:latest .

# Push
docker push evoapicloud/falai-api:latest
```

### Passo 3: Configurar EasyPanel

No EasyPanel, configure para usar a imagem do Docker Hub ao invés de fazer build:

**Opção A: Via Interface do EasyPanel**
1. Vá em configurações do serviço
2. Mude de "Build from Dockerfile" para "Use Docker Image"
3. Coloque a imagem: `evoapicloud/falai-api:latest`

**Opção B: Via docker-compose.yml** (se aplicável)
```yaml
services:
  api:
    image: evoapicloud/falai-api:latest  # Ao invés de build: .
    # ... resto das configurações
```

## Alternativa: GitHub Container Registry (GHCR)

Se preferir usar o GitHub Container Registry (gratuito e privado):

```bash
# Login
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Build e tag
docker build -t ghcr.io/seu-usuario/falai-api:latest .

# Push
docker push ghcr.io/seu-usuario/falai-api:latest
```

No EasyPanel, use: `ghcr.io/seu-usuario/falai-api:latest`

## Workflow Recomendado para CI/CD

### GitHub Actions (Automático)

Crie `.github/workflows/build-and-push.yml`:

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main, master ]
    paths:
      - 'falai-api/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: ./falai-api
          push: true
          tags: evoapicloud/falai-api:latest
```

Adicione os secrets no GitHub:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

## Troubleshooting

### Build falhando localmente?

Certifique-se de ter memória suficiente:

```bash
# Aumentar memória do Docker Desktop (Mac/Windows)
# Docker Desktop > Settings > Resources > Memory: 4GB+
```

### Imagem muito grande?

Otimize o .dockerignore:

```
__pycache__/
*.pyc
.git/
.env
.venv/
node_modules/
.pytest_cache/
```

### Contato com Suporte EasyPanel

Se quiser resolver o problema de DNS no servidor:

1. Abra um ticket reportando: "DNS resolution failing during Docker build"
2. Inclua os logs mostrando: `Temporary failure resolving 'deb.debian.org'`
3. Solicite verificação de DNS servers do host Docker

## Dockerfiles Disponíveis

- **Dockerfile** (Alpine) - Padrão, mais leve
- **Dockerfile.debian-bookworm** - Debian sem DNS customizado
- **Dockerfile.debian-dns** - Debian com DNS configurado (8.8.8.8)

Para testar outro Dockerfile localmente:

```bash
docker build -f Dockerfile.debian-dns -t evoapicloud/falai-api:debian .
```

## Status das Correções

- ✅ CORS_ORIGINS configurado corretamente
- ✅ Dockerfile otimizado (Alpine + Debian)
- ✅ Script de build local criado
- ⚠️ Problema de DNS no EasyPanel (infraestrutura)
