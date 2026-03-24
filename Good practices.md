# Good Practices - Boas praticas aplicadas

Este documento relaciona as boas praticas aplicadas no projeto e como cada uma foi implementada.

| Boa pratica | Como foi aplicada no projeto |
|-------------|------------------------------|
| Infraestrutura como Codigo (IaC) | Toda a infraestrutura foi implementada com Terraform, centralizada em `terraform/main.tf`, com suporte em `terraform/variables.tf`, `terraform/outputs.tf` e `terraform/versions.tf`. |
| Documentacao de execucao | O fluxo de configuracao e validacao esta documentado em `Instructions.md`, incluindo provisionamento, deploy do backend e verificacoes. |
| Portabilidade entre contas e maquinas | O projeto usa variaveis e dados dinamicos da conta atual (`data.aws_caller_identity.current`), evitando dependencia de conta fixa. |
| Versionamento de dependencias | Os providers Terraform foram versionados em `terraform/versions.tf` (AWS `~> 5.0` e Archive `~> 2.4`). |
| Separacao de responsabilidades | Foram criadas roles separadas para ECS e Lambda em `terraform/main.tf`, com politica de apoio em `terraform/iam-policy-project.json`. |
| Padrao de nomes e tags | Recursos usam prefixo padrao do projeto e tags `Name`, facilitando rastreabilidade operacional na AWS. |
| Backend containerizado | O backend foi empacotado com Docker em `backend-app/Dockerfile` e possui script de deploy para ECR em `scripts/deploy-backend.sh`. |
| Automacao de rotina diaria | A rotina diaria foi implementada com EventBridge acionando Lambda para gravacao em S3, definida em `terraform/main.tf`. |
| Logs centralizados | O ECS envia logs para CloudWatch Logs com log group dedicado, e a Lambda possui permissoes para escrita de logs em CloudWatch. |

## Referencias principais

- `terraform/main.tf`
- `terraform/variables.tf`
- `terraform/outputs.tf`
- `terraform/versions.tf`
- `terraform/iam-policy-project.json`
- `backend-app/Dockerfile`
- `backend-app/server.js`
- `scripts/deploy-backend.sh`
- `Instructions.md`
