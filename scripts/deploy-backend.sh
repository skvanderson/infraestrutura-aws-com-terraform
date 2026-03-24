#!/bin/bash
# Faz login no ECR, build e push da imagem do backend.
# Execute a partir da raiz do projeto: ./scripts/deploy-backend.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

REGION="${AWS_REGION:-us-east-1}"
ECR_URL=$(terraform -chdir=terraform output -raw backend_ecr_repository_url 2>/dev/null | tr -d '\r\n' || true)
if [ -z "$ECR_URL" ]; then
  echo "Erro: execute 'terraform apply' em terraform/ antes e garanta que o output backend_ecr_repository_url existe."
  exit 1
fi

echo "Região: $REGION"
echo "ECR Repository: $ECR_URL"
echo "Fazendo login no ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${ECR_URL%%/*}"
echo "Build da imagem..."
docker build -t portfolio-cloud-backend ./backend-app
docker tag portfolio-cloud-backend:latest "$ECR_URL:latest"
echo "Push da imagem..."
docker push "$ECR_URL:latest"
echo "Concluído. O ECS irá usar a nova imagem em breve."
