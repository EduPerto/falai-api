#!/bin/bash

# Script para fazer build local e push para Docker Hub
# Uso: ./build-and-push.sh [TAG]

set -e

# Configurações
DOCKER_USERNAME="${DOCKER_USERNAME:-evoapicloud}"
IMAGE_NAME="falai-api"
TAG="${1:-latest}"
FULL_IMAGE="${DOCKER_USERNAME}/${IMAGE_NAME}:${TAG}"

echo "========================================="
echo "Build e Push para Docker Hub"
echo "========================================="
echo "Imagem: ${FULL_IMAGE}"
echo ""

# Verificar se está logado no Docker Hub
if ! docker info | grep -q "Username"; then
    echo "⚠️  Você precisa fazer login no Docker Hub primeiro:"
    echo "   docker login"
    exit 1
fi

# Build da imagem
echo "📦 Fazendo build da imagem..."
docker build -t "${FULL_IMAGE}" .

if [ $? -ne 0 ]; then
    echo "❌ Erro no build!"
    exit 1
fi

echo "✅ Build concluído!"
echo ""

# Push para o Docker Hub
echo "🚀 Enviando para Docker Hub..."
docker push "${FULL_IMAGE}"

if [ $? -ne 0 ]; then
    echo "❌ Erro no push!"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ Sucesso!"
echo "========================================="
echo "Imagem disponível em: ${FULL_IMAGE}"
echo ""
echo "No EasyPanel, use a imagem:"
echo "  ${FULL_IMAGE}"
echo "========================================="
