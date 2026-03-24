# Passo a passo – Testar na AWS

Guia passo a passo na ordem. Execute os comandos na raiz do projeto

**Portabilidade:** o projeto funciona em **qualquer conta AWS** e em **qualquer máquina**. Não há conta, ou caminho fixo no código: a conta usada é a do `aws configure`; a região pode ser definida no `aws configure` ou em `terraform.tfvars` (opcional). Quem receber o projeto só precisa ter Terraform, AWS CLI e Docker instalados e configurar as credenciais AWS.

---

## Configurar o AWS CLI (faça isso primeiro, se ainda não fez)

O AWS CLI precisa de **credenciais** da sua conta AWS (Access Key e Secret Key) para o Terraform e os comandos `aws` funcionarem. Siga abaixo.

### 1. Entrar no console da AWS

- Acesse [https://console.aws.amazon.com](https://console.aws.amazon.com) e faça login na conta onde quer rodar o projeto.

### 2. Criar um usuário com Access Key (se ainda não tiver)

Você pode usar uma das opções abaixo. A **Opção B** segue boas práticas (menor privilégio) e usa a política incluída no projeto.

#### Opção A – Rápido (AdministratorAccess)

1. No console, busque por **IAM** (ou **Serviços** → **Segurança, Identidade e Conformidade** → **IAM**).
2. **Usuários** → **Criar usuário**.
3. Nome (ex.: `terraform-portfolio-cloud`, ) → **Próximo**.
4. Em permissões: **Anexar políticas diretamente** → marque **AdministratorAccess** → **Próximo** → **Criar usuário**.
5. Clique no usuário → **Credenciais de segurança** → **Chaves de acesso** → **Criar chave de acesso** → **Uso da CLI** → **Criar chave de acesso**.
6. Copie e guarde o **Access Key ID** e a **Secret Access Key**.

#### Opção B – Boas práticas (política mínima do projeto)

Use um usuário com **apenas** as permissões necessárias para este projeto (política em `terraform/iam-policy-project.json`).

**2.1 – Criar a política no IAM**

1. No console AWS: **IAM** → **Políticas** → **Criar política**.
2. Aba **JSON** → apague o conteúdo padrão e cole **todo** o conteúdo do arquivo **`terraform/iam-policy-project.json`** deste repositório (abrir o arquivo e copiar).
3. **Próximo** → nome da política, ex.: **`PortfolioCloudTerraform`** → **Criar política**.

**2.2 – Criar o usuário e anexar a política**

1. **IAM** → **Usuários** → **Criar usuário**.
2. Nome (ex.: `terraform-portfolio-cloud`) → **Próximo**.
3. Em permissões: **Anexar políticas diretamente** → busque **PortfolioCloudTerraform** (a política que você criou) → marque → **Próximo** → **Criar usuário**.
4. Clique no usuário → **Credenciais de segurança** → **Chaves de acesso** → **Criar chave de acesso** → **Uso da CLI** → **Criar chave de acesso**.
5. Copie e guarde o **Access Key ID** e a **Secret Access Key**.

---

## Antes de começar (checklist)

- [ ] **Terraform** instalado (`terraform version`)
- [ ] **AWS CLI** instalado e **configurado** (acima) — teste com `aws sts get-caller-identity`
- [ ] **Docker** instalado (para o backend)

---

### 3. Configurar o AWS CLI no seu computador

No terminal, rode:

Linux/macOS/Windows (Bash/PowerShell):

```bash
aws configure
```

O comando vai pedir quatro coisas (pode pressionar Enter para deixar em branco o que for opcional):

| Pergunta | O que digitar |
|----------|----------------|
| **AWS Access Key ID** | Cole o **ID da chave de acesso** (ex.: `AKIA...`) |
| **AWS Secret Access Key** | Cole a **chave de acesso secreta** |
| **Default region name** | Região onde quer criar os recursos, ex.: **us-east-1** |
| **Default output format** | Pode deixar em branco ou digitar **json** |

Exemplo:

```
AWS Access Key ID [****************____]: AKIA....................
AWS Secret Access Key [****************____]: ........................
Default region name [None]: us-east-1
Default output format [None]: json
```

### 4. Testar se está funcionando

Rode:

Linux/macOS/Windows (Bash/PowerShell)

```bash
aws sts get-caller-identity
```

Se aparecer algo como seu **Account**, **UserId** e **Arn**, está configurado corretamente. A partir daí você pode seguir o restante do passo a passo abaixo.



## Passo 1 – Subir a infraestrutura com Terraform

Linux/macOS/Windows (Bash/PowerShell)

```bash
cd terraform
terraform init
terraform apply
```

Quando perguntar **"Enter a value:"**, digite **`yes`** e pressione Enter.

Aguarde até terminar. No final, o Terraform mostrará os **outputs** (URLs e nomes dos recursos).

---

## Passo 2 – Anotar as URLs (outputs)

Depois do `terraform apply`, anote:

| Output | O que é |
|--------|--------|
| **frontend_url** | URL do site (portfólio) via **CloudFront** (HTTPS) — use esta para acessar o site. *Só aparece depois que o apply termina por completo (CloudFront leva ~5–15 min).* |
| **frontend_url_s3** | URL direta do S3 (site estático; use se o CloudFront ainda não estiver pronto) |
| **backend_api_url** | URL da API em container (Serviço 2). *Só aparece depois que ALB e ECS service forem criados.* |
| **backend_ecr_repository_url** | URL do repositório para enviar a imagem Docker |
| **scheduler_bucket_name** | Bucket onde a Lambda grava os arquivos diários (Serviço 3) |
| **lambda_function_name** | Nome da função Lambda da rotina diária |

Para ver de novo a qualquer momento:

Linux/macOS/Windows (Bash/PowerShell)

```bash
cd terraform
terraform output
```
---

## Passo 3 – Fazer deploy da imagem do Backend (Serviço 2)

O Backend só funciona depois que a imagem Docker for enviada para o ECR. Na **raiz do projeto** (sair da pasta `terraform`):

Linux/macOS/Windows (Bash/PowerShell)

```bash
cd ..   # volta para a raiz do projeto
```

Defina a região (igual à usada no Terraform, neste caso `us-east-1`):

Linux/macOS (Bash):

```bash
export AWS_REGION=$(aws configure get region)
```

Windows (PowerShell):

```powershell
$env:AWS_REGION = (aws configure get region).Trim()
```

```markdown
- [ ] **Região consistente** — verifique a região do seu AWS CLI:
  ```bash
  aws configure get region
  ```
  O Terraform usa `us-east-1` por padrão. Se sua região for diferente, crie o
  arquivo `terraform/terraform.tfvars` com:
  ```hcl
  aws_region = "sua-regiao"
  ```
```

**Use estes comandos** (na raiz do projeto). A conta AWS usada é a que está configurada no seu `aws configure`:

Linux/macOS (Bash):

**Alternativa Recomendada:** em vez dos comandos acima, use o script pronto:

Entre na pasta de scripts do projeto 

```bash
./deploy-backend.sh
```
Ou se comandos abaixo.

```bash
export AWS_REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY
docker build -t portfolio-cloud-backend ./backend-app
docker tag portfolio-cloud-backend:latest $REGISTRY/portfolio-cloud-backend:latest
docker push $REGISTRY/portfolio-cloud-backend:latest
```

Windows (PowerShell):

```powershell
$env:AWS_REGION = "us-east-1"
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text).Trim()
$REGISTRY = "$ACCOUNT_ID.dkr.ecr.$env:AWS_REGION.amazonaws.com"
aws ecr get-login-password --region $env:AWS_REGION | docker login --username AWS --password-stdin $REGISTRY
docker build -t portfolio-cloud-backend ./backend-app
docker tag portfolio-cloud-backend:latest "$REGISTRY/portfolio-cloud-backend:latest"
docker push "$REGISTRY/portfolio-cloud-backend:latest"
```

Aguarde alguns minutos. O ECS vai puxar a nova imagem e o serviço ficará saudável.

---

## Passo 4 – Ver as URLs e testar os 3 serviços

### Como ver as URLs (outputs do Terraform)

Execute na pasta do projeto para visualizar **todas** as saídas:

Linux/macOS/Windows (Bash/PowerShell)

```bash
terraform -chdir=terraform output
```
Para ver **cada URL/nome** separadamente (útil para copiar ou usar em scripts):

```bash
# URL do site (portfólio) - CloudFront, HTTPS
terraform -chdir=terraform output frontend_url

# URL da API (Backend)
terraform -chdir=terraform output backend_api_url

# Nome do bucket onde a Lambda grava os arquivos (Serviço 3)
terraform -chdir=terraform output scheduler_bucket_name

# Nome da função Lambda (para invocar no teste)
terraform -chdir=terraform output lambda_function_name
```
---

### Serviço 1 – Frontend estático (portfólio)

O site estático é o **portfólio** (HTML/CSS/JS e imagens), servido pelo S3 e distribuído via **CloudFront** (HTTPS).

1. Pegue a URL (CloudFront):
   
   Linux/macOS/Windows (Bash/PowerShell)
   ```bash
   terraform -chdir=terraform output frontend_url
   ```

2. Abra essa URL no navegador. Você deve ver a página do portfólio (perfil e certificações).
3. Se preferir testar direto pelo S3: use `terraform -chdir=terraform output frontend_url_s3` (HTTP).

---

### Serviço 2 – Backend (API)

Em 2–5 minutos após o push da imagem, o ECS sobe o container. Então:

1. Pegue a URL do ALB:
   Linux/macOS/Windows (Bash/PowerShell)
   ```bash
   terraform -chdir=terraform output backend_api_url
   ```

2. Abra essa URL no navegador ou teste no terminal:
   Linux/macOS (Bash):
   ```bash
   curl "$(terraform -chdir=terraform output -raw backend_api_url)/api/health"
   ```
   Windows (PowerShell):
   ```powershell
   $backendUrl = terraform -chdir=terraform output -raw backend_api_url
   curl.exe "$backendUrl/api/health"
   ```
   Deve retornar algo como `{"status":"ok",...}`.
3. Outros endpoints: `/`, `/api`, `/api/echo?msg=teste`

Se retornar 503 ou não abrir, espere mais 2–3 minutos (ALB e ECS estabilizando) e tente de novo.

**Sobre o BackEnd:** O frontend (portfólio) é estático e **não chama** a API do backend. Os dois coexistem: o **frontend** é o site público (portfólio) na URL do CloudFront; o **backend** é a API de demonstração no ECS, acessível pela URL do ALB. Se no futuro o portfólio precisar de dados dinâmicos, você pode apontar chamadas JavaScript para `backend_api_url`.

---

### Serviço 3 – Rotina diária (Lambda + S3)

**Testar a Lambda na hora (sem esperar as 10:00):**

Linux/macOS (Bash):

Volte para a raiz do projeto 

```bash
cd ..
```
Execute

```bash
aws lambda invoke --function-name $(terraform -chdir=terraform output -raw lambda_function_name) --region "${AWS_REGION:-us-east-1}" out.json && cat out.json
```

Windows (PowerShell):

```powershell
$lambdaName = terraform -chdir=terraform output -raw lambda_function_name
$region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }
aws lambda invoke --function-name $lambdaName --region $region out.json
Get-Content .\out.json
```

**Ver os buckets no S3:**

1. Por linha de comandos:

   ```bash
   aws s3 ls s3://
   ```

2. No console AWS: **S3** → abra o bucket com esse nome. Depois de rodar a Lambda (comando acima ou no horário agendado), deve aparecer um arquivo com nome no formato **YYYY-MM-DD_HH-MM-SS.txt**.

A rotina também roda **automaticamente todo dia às 10:00 UTC** (horário configurável no Terraform).

---

## Resumo rápido

| # | O que fazer |
|---|-------------|
| 1 | `cd terraform` → `terraform init` → `terraform apply` (yes) |
| 2 | Ver as URLs: `terraform -chdir=terraform output` (ou os comandos do Passo 4) |
| 3 | Na raiz: build + push da imagem Docker para o ECR (comandos do Passo 3) |
| 4 | Testar: ver URLs no Passo 4, abrir frontend_url, backend_api_url e invocar Lambda / conferir S3 |

---

## Para destruir tudo depois do teste

Linux/macOS/Windows (Bash/PowerShell)

```bash
cd terraform
terraform destroy
```

Windows (PowerShell):

```powershell
cd terraform
terraform destroy
```

Digite **`yes`** quando solicitado. Isso remove todos os recursos criados na AWS.

**Aguarde:** o destroy pode levar vários minutos (5–10 min). Mensagens como *"Still destroying... [05m20s elapsed]"* no ECS ou no Internet Gateway são normais — deixe rodar até aparecer *"Destroy complete"* em todos os recursos.

**Importante:** Rode o `terraform destroy` **na mesma pasta** onde você rodou o `terraform apply`. Se aparecer erro de "AlreadyExists" ao rodar `apply` (recursos de um teste anterior na conta), na **raiz do projeto** rode o script de limpeza e depois `terraform apply` de novo:

Linux/macOS (Bash):

```bash
./scripts/limpar_aws.sh
cd terraform && terraform apply
```

Windows (PowerShell):

```powershell
bash ./scripts/limpar_aws.sh
cd terraform
terraform apply
```

### Se o destroy falhar (bucket não vazio ou ECR com imagens)

O Terraform já está configurado com `force_destroy` (S3) e `force_delete` (ECR). Se ainda assim der erro, esvazie e tente o destroy de novo (use a região que você está usando):

Linux/macOS (Bash):

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rm s3://portfolio-cloud-scheduler-${ACCOUNT_ID} --recursive
aws ecr batch-delete-image --repository-name portfolio-cloud-backend --image-ids imageTag=latest --region "${AWS_REGION:-us-east-1}"
cd terraform && terraform destroy
```

Windows (PowerShell):

```powershell
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text).Trim()
$region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }
aws s3 rm "s3://portfolio-cloud-scheduler-$ACCOUNT_ID" --recursive
aws ecr batch-delete-image --repository-name portfolio-cloud-backend --image-ids imageTag=latest --region $region
cd terraform
terraform destroy
```
