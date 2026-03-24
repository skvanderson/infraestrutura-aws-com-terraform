variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (prefixo dos recursos)"
  type        = string
  default     = "portfolio-cloud"
}

# Serviço 3: horário da rotina diária (cron em UTC)
# 10:00 AM UTC = "0 10 * * ? *"
# Para 10:00 AM BRT (UTC-3): use "0 13 * * ? *"
variable "daily_schedule_cron" {
  description = "Expressão cron para execução diária (UTC). Padrão: 10:00 AM UTC"
  type        = string
  default     = "cron(0 10 * * ? *)"
}
