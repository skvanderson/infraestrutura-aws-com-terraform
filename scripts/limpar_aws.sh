#!/bin/bash
# Remove todos os recursos portfolio-cloud na AWS (para poder rodar terraform apply de novo).
# Uso: na raiz do projeto, ./scripts/limpar_aws.sh
# Requer: AWS CLI configurado (aws configure)
AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="${ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text 2>/dev/null | tr -d '\r\n')}"
if [ -z "$ACCOUNT_ID" ]; then
  echo "Erro: configure o AWS CLI (aws configure) ou defina ACCOUNT_ID."
  exit 1
fi
echo "Região: $AWS_REGION | Conta: $ACCOUNT_ID"
echo "Removendo recursos portfolio-cloud..."

# 1. ECS
echo "[1/7] ECS..."
aws ecs update-service --cluster portfolio-cloud-cluster --service portfolio-cloud-backend --desired-count 0 --region "$AWS_REGION" 2>/dev/null || true
aws ecs delete-service --cluster portfolio-cloud-cluster --service portfolio-cloud-backend --force --region "$AWS_REGION" 2>/dev/null || true
sleep 15
aws ecs delete-cluster --cluster portfolio-cloud-cluster --region "$AWS_REGION" 2>/dev/null || true

# 2. ALB e Target Group
echo "[2/7] ALB e Target Group..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names portfolio-cloud-backend-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text --region "$AWS_REGION" 2>/dev/null) || true
if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
  LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query 'Listeners[0].ListenerArn' --output text --region "$AWS_REGION" 2>/dev/null) || true
  [ -n "$LISTENER_ARN" ] && [ "$LISTENER_ARN" != "None" ] && aws elbv2 delete-listener --listener-arn "$LISTENER_ARN" --region "$AWS_REGION" 2>/dev/null || true
  aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region "$AWS_REGION" 2>/dev/null || true
fi
sleep 10
TG_ARN=$(aws elbv2 describe-target-groups --names portfolio-cloud-backend-tg --query 'TargetGroups[0].TargetGroupArn' --output text --region "$AWS_REGION" 2>/dev/null) || true
[ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ] && aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region "$AWS_REGION" 2>/dev/null || true

# 3. Lambda e EventBridge
echo "[3/7] Lambda e EventBridge..."
aws events remove-targets --rule portfolio-cloud-daily-10am --ids Lambda --region "$AWS_REGION" 2>/dev/null || true
aws lambda delete-function --function-name portfolio-cloud-daily-scheduler --region "$AWS_REGION" 2>/dev/null || true
aws events delete-rule --name portfolio-cloud-daily-10am --region "$AWS_REGION" 2>/dev/null || true

# 4. IAM roles
echo "[4/7] IAM roles..."
aws iam detach-role-policy --role-name portfolio-cloud-ecs-task-execution --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 2>/dev/null || true
aws iam delete-role --role-name portfolio-cloud-ecs-task-execution 2>/dev/null || true
aws iam delete-role-policy --role-name portfolio-cloud-ecs-task --policy-name portfolio-cloud-ecs-task 2>/dev/null || true
aws iam delete-role --role-name portfolio-cloud-ecs-task 2>/dev/null || true
aws iam delete-role-policy --role-name portfolio-cloud-lambda-scheduler --policy-name portfolio-cloud-lambda-scheduler 2>/dev/null || true
aws iam delete-role --role-name portfolio-cloud-lambda-scheduler 2>/dev/null || true

# 5. ECR e S3
echo "[5/7] ECR e S3..."
aws ecr batch-delete-image --repository-name portfolio-cloud-backend --image-ids imageTag=latest --region "$AWS_REGION" 2>/dev/null || true
aws ecr delete-repository --repository-name portfolio-cloud-backend --region "$AWS_REGION" 2>/dev/null || true
aws s3 rm "s3://portfolio-cloud-frontend-${ACCOUNT_ID}" --recursive 2>/dev/null || true
aws s3 rb "s3://portfolio-cloud-frontend-${ACCOUNT_ID}" 2>/dev/null || true
aws s3 rm "s3://portfolio-cloud-scheduler-${ACCOUNT_ID}" --recursive 2>/dev/null || true
aws s3 rb "s3://portfolio-cloud-scheduler-${ACCOUNT_ID}" 2>/dev/null || true

# 6. CloudWatch Logs
echo "[6/7] CloudWatch Logs..."
aws logs delete-log-group --log-group-name /ecs/portfolio-cloud-backend --region "$AWS_REGION" 2>/dev/null || true

# 7. VPC
echo "[7/7] VPC..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=portfolio-cloud-backend-vpc" --query 'Vpcs[0].VpcId' --output text --region "$AWS_REGION" 2>/dev/null) || true
[ -z "$VPC_ID" ] || [ "$VPC_ID" = "None" ] && VPC_ID=$(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.0.0.0/16" --query 'Vpcs[0].VpcId' --output text --region "$AWS_REGION" 2>/dev/null) || true
if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
  for sg in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text --region "$AWS_REGION" 2>/dev/null); do
    aws ec2 delete-security-group --group-id "$sg" --region "$AWS_REGION" 2>/dev/null || true
  done
  sleep 5
  for sid in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text --region "$AWS_REGION" 2>/dev/null); do
    aws ec2 delete-subnet --subnet-id "$sid" --region "$AWS_REGION" 2>/dev/null || true
  done
  for rt in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text --region "$AWS_REGION" 2>/dev/null); do
    aws ec2 delete-route-table --route-table-id "$rt" --region "$AWS_REGION" 2>/dev/null || true
  done
  IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text --region "$AWS_REGION" 2>/dev/null) || true
  [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ] && aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$AWS_REGION" 2>/dev/null && aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region "$AWS_REGION" 2>/dev/null || true
  aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$AWS_REGION" 2>/dev/null || true
fi

echo "Limpeza concluída. Agora rode: cd terraform && terraform apply"
