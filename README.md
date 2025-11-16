# Cloud TP3 - MatchMarket Infrastructure

Infraestructura como código (IaC) usando Terraform para desplegar una aplicación web completa en AWS.

## 🏗️ Arquitectura

- **Frontend**: Vue.js servido desde S3 con configuración de website estático
- **Backend**: Node.js containerizado en ECS Fargate usando imágenes de ECR
- **Base de Datos**: PostgreSQL en RDS
- **Autenticación**: AWS Cognito User Pool con autenticación directa (SRP)
- **Load Balancer**: Application Load Balancer (ALB)
- **Networking**: VPC personalizada con subnets públicas y privadas

## 📋 Requisitos Previos

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- [Docker Desktop](https://www.docker.com/products/docker-desktop) (para builds del backend)
- [Node.js](https://nodejs.org/) >= 18 (para builds del frontend)

## 🚀 Inicio Rápido

### 1. Configurar Variables (Opcional)

Edita `variables.tf` o crea un archivo `terraform.tfvars`:

```hcl
app_name        = "MatchMarket"
aws_region      = "us-east-1"
db_name         = "matchmarket"
db_username     = "postgres"
db_password     = "tu-password-seguro"
s3_bucket_name  = "tu-bucket-unico"
```

**Nota sobre Cognito**: El User Pool y App Client se crean automáticamente con la configuración necesaria para autenticación directa.

### 2. Desplegar la Infraestructura

```bash
# Inicializar Terraform
terraform init

# Ver plan de ejecución
terraform plan

# Aplicar configuración
terraform apply
```

## Posibles errores

- "Error: fileset function return an inconsistent result". Solución: ejecutar `terraform apply` nuevamente.

### 3. Desplegar TODO

```bash
terraform apply
```

**¿Qué hace automáticamente?**

- ✅ Crea toda la infraestructura (VPC, RDS, ALB, ECR, Cognito, etc.)
- ✅ Clona repo del backend de GitHub
- ✅ Construye imagen Docker y la sube a ECR
- ✅ Despliega el servicio ECS
- ✅ Construye el frontend con las variables de entorno configuradas

**Opción alternativa** (sin Docker):

```bash
terraform apply -var="use_dockerhub=true"
```

## 🔀 Configuración de Imagen del Backend

### Opción 1: ECR con Build Automático (default)

```hcl
use_dockerhub = false  # default
```

Terraform clona automáticamente https://github.com/EmiN364/CloudBackEnd, construye y sube a ECR.

**Requiere**: Docker instalado y corriendo

### Opción 2: Docker Hub (sin Docker local)

```hcl
use_dockerhub   = true
dockerhub_image = "emin364/cloud-backend:latest"
```

**No requiere**: Docker instalado

## 🔐 Configuración de Autenticación (Cognito)

El proyecto utiliza **AWS Cognito** para autenticación con autenticación directa (SRP - Secure Remote Password). No se utiliza la interfaz hospedada de Cognito.

### Variables de Entorno del Frontend

El frontend se construye automáticamente con las siguientes variables de entorno:

```env
# AWS Cognito Configuration
VITE_COGNITO_USER_POOL_ID=<user-pool-id>
VITE_COGNITO_CLIENT_ID=<client-id>

# S3 Configuration
VITE_S3_URL=<s3-bucket-url>

# API BASE URL
VITE_API_BASE_URL=http://<alb-dns-name>
```

Estas variables se configuran automáticamente durante el build del frontend usando los valores de los recursos de Terraform.

### Flujos de Autenticación Soportados

- ✅ **ALLOW_USER_SRP_AUTH**: Autenticación SRP (recomendado)
- ✅ **ALLOW_REFRESH_TOKEN_AUTH**: Renovación de tokens
- ✅ **ALLOW_USER_PASSWORD_AUTH**: Autenticación con usuario/contraseña

### Configuración del User Pool

- Email como nombre de usuario
- Verificación automática de email
- Política de contraseñas: mínimo 8 caracteres, requiere mayúsculas, minúsculas, números y símbolos
- Tokens válidos por 1 hora (access token e ID token)
- Refresh token válido por 30 días

## 📁 Estructura del Proyecto

```text
cloud-tp3/
├── alb.tf                  # Application Load Balancer
├── cognito.tf              # AWS Cognito User Pool y App Client
├── datasources.tf          # Data sources de AWS
├── ecr.tf                  # Repositorio ECR para el backend
├── ecs.tf                  # ECS Cluster, Task y Service
├── frontend.tf             # Configuración del frontend en S3
├── outputs.tf              # Outputs de Terraform
├── provider.tf             # Configuración del provider AWS
├── rds.tf                  # Base de datos PostgreSQL
├── s3.tf                   # Buckets S3
├── security_groups.tf      # Security Groups
├── variables.tf            # Variables de entrada
├── vpc.tf                  # VPC y networking
├── modules/                # Módulos personalizados
│   └── s3/                 # Módulo S3
├── scripts/                # Scripts de build multiplataforma
│   ├── build_backend.sh    # Build backend (Linux/Mac)
│   ├── build_backend.ps1   # Build backend (Windows)
├── build_frontend.sh       # Build frontend (Linux/Mac)
├── build_frontend.bat      # Build frontend (Windows)
└── README.md               # Este archivo
```

## 🔍 Outputs Útiles

Después de `terraform apply`, obtén información importante:

```bash
# URL del sitio web
terraform output website_url

# DNS del Load Balancer
terraform output alb_dns_name

# URL del repositorio ECR
terraform output ecr_repository_url

# Endpoint de la base de datos
terraform output db_endpoint

# Ver logs en CloudWatch
terraform output cloudwatch_logs_url

# Configuración de Cognito
terraform output cognito_user_pool_id
terraform output cognito_app_client_id
terraform output cognito_region
```

## 🔄 Workflow de Desarrollo

### Actualizar Backend (con ECR)

```bash
# Opción 1: Con Terraform (automático - RECOMENDADO)
terraform apply -replace='null_resource.backend_image[0]'

# Opción 2: Script manual (más rápido si solo cambió el backend)
bash scripts/build_backend.sh           # Linux/Mac/Git Bash
.\scripts\build_backend.ps1             # Windows sin Git Bash
```

### Actualizar Infraestructura

```bash
terraform plan
terraform apply
```

## ✅ Requisitos Técnicos Implementados

### 1. Módulos Terraform

- ✅ Módulo personalizado: `modules/s3`
- ✅ Módulo externo: `terraform-aws-modules/vpc`
- ✅ Módulo externo: `terraform-aws-modules/alb`
- ✅ Módulo externo: `terraform-aws-modules/rds`
- ✅ Módulo externo: `terraform-aws-modules/security-group`

### 2. Variables y Outputs

- ✅ Variables parametrizadas en `variables.tf`
- ✅ Outputs informativos en `outputs.tf`

### 3. Funciones Terraform

- ✅ `jsonencode()` - Para definiciones de contenedores
- ✅ `replace()` - Para formatear URLs
- ✅ `data.aws_caller_identity.current` - Para obtener account ID
- ✅ `data.aws_availability_zones.available` - Para AZs

### 4. Meta-argumentos

- ✅ `depends_on` - En ECS Service y otros recursos
- ✅ `for_each` - En módulos y recursos múltiples
- ✅ `count` - En recursos condicionales
- ✅ `lifecycle` - En políticas de ciclo de vida

### 5. Estructura del Proyecto

- ✅ Organización lógica por servicio (alb.tf, ecs.tf, rds.tf, etc.)
- ✅ Nomenclatura consistente
- ✅ Principio DRY con módulos

## 🔐 Seguridad

- Security Groups configurados con reglas necesarias
- RDS en subnets privadas
- Escaneo automático de vulnerabilidades en ECR
- IAM Roles con permisos específicos (LabRole)
- AWS Cognito con autenticación segura (SRP)
- Política de contraseñas robusta configurada
- Tokens con validez limitada para mayor seguridad
