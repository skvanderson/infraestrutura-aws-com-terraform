output "frontend_url" {
  description = "URL do site (CloudFront — use esta; HTTPS)"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "frontend_url_s3" {
  description = "URL direta do S3 (website; use se CloudFront não estiver pronto)"
  value       = "http://${aws_s3_bucket.frontend.id}.s3-website.${var.aws_region}.amazonaws.com"
}

output "frontend_bucket_name" {
  description = "Nome do bucket S3 do frontend"
  value       = aws_s3_bucket.frontend.id
}

output "backend_api_url" {
  description = "URL do Load Balancer (Backend API)"
  value       = "http://${aws_lb.backend.dns_name}"
}

output "backend_ecr_repository_url" {
  description = "URL do repositório ECR para push da imagem Docker"
  value       = aws_ecr_repository.backend.repository_url
}

output "scheduler_bucket_name" {
  description = "Nome do bucket S3 onde a Lambda grava os arquivos diários"
  value       = aws_s3_bucket.scheduler.id
}

output "lambda_function_name" {
  description = "Nome da função Lambda da rotina diária"
  value       = aws_lambda_function.scheduler.function_name
}
