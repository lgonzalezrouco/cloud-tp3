# Cloud TP3 - MatchMarket Infrastructure

Infraestructura como código (IaC) usando Terraform para desplegar una aplicación web completa en AWS.

## 🏗️ Arquitectura

- **Frontend**: Vue.js servido desde S3 con configuración de website estático
- **Backend**: Node.js containerizado en ECS Fargate usando imágenes de ECR
- **Base de Datos**: PostgreSQL en RDS
- **Load Balancer**: Application Load Balancer (ALB)
- **Networking**: VPC personalizada con subnets públicas y privadas

## 📋 Requisitos Previos

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- [Docker Desktop](https://www.docker.com/products/docker-desktop) (para builds del backend)
- [Node.js](https://nodejs.org/) >= 18 (para builds del frontend)

## 🚀 Inicio Rápido

### 1. Configurar Variables

Edita `variables.tf` o crea un archivo `terraform.tfvars`:

```hcl
app_name        = "MatchMarket"
aws_region      = "us-east-1"
db_name         = "matchmarket"
db_username     = "postgres"
db_password     = "tu-password-seguro"
s3_bucket_name  = "tu-bucket-unico"
```

### 2. Desplegar la Infraestructura

```bash
# Inicializar Terraform
terraform init

# Ver plan de ejecución
terraform plan

# Aplicar configuración
terraform apply
```

### 3. Desplegar TODO

```bash
terraform apply
```

**¿Qué hace automáticamente?**
- ✅ Crea toda la infraestructura (VPC, RDS, ALB, ECR, etc.)
- ✅ Clona repo del backend de GitHub
- ✅ Construye imagen Docker y la sube a ECR
- ✅ Despliega el servicio ECS

**Opción alternativa** (sin Docker):
```bash
terraform apply -var="use_dockerhub=true"
```

### 4. Desplegar Frontend

Después de que `terraform apply` termine, construye el frontend:

```bash
# Linux/Mac/Git Bash
bash scripts/build_frontend.sh

# Windows PowerShell (si no tienes Git Bash)
.\scripts\build_frontend.ps1
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

## 📁 Estructura del Proyecto

```
cloud-tp3/
├── alb.tf                  # Application Load Balancer
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
├── frontend-source/        # Código fuente del frontend (Vue.js)
├── scripts/                # Scripts de build multiplataforma
│   ├── build_backend.sh    # Build backend (Linux/Mac)
│   ├── build_backend.ps1   # Build backend (Windows)
│   ├── build_frontend.sh   # Build frontend (Linux/Mac)
│   └── build_frontend.ps1  # Build frontend (Windows)
├── build_backend.tf        # Terraform: automatiza build del backend
├── DEPLOY.md               # Guía completa de despliegue
└── README.md               # Este archivo
```

## 📚 Documentación

- [**QUICKSTART.md**](QUICKSTART.md) - ⚡ Inicio rápido (empieza aquí)
- [**DEPLOY.md**](DEPLOY.md) - Guía completa de despliegue
- [**WINDOWS_SETUP.md**](WINDOWS_SETUP.md) - Configuración en Windows
- [**README_SCRIPTS.md**](README_SCRIPTS.md) - Información adicional sobre scripts

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

### Actualizar Frontend
```bash
bash scripts/build_frontend.sh          # Linux/Mac
.\scripts\build_frontend.ps1            # Windows
```

### Actualizar Backend (con Docker Hub)
1. Sube nueva imagen a Docker Hub manualmente
2. ```bash
   aws ecs update-service \
     --cluster $(terraform output -raw ecs_cluster_name) \
     --service $(terraform output -raw ecs_service_name) \
     --force-new-deployment
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

- Security Groups configurados con reglas mínimas necesarias
- RDS en subnets privadas
- Escaneo automático de vulnerabilidades en ECR
- IAM Roles con permisos específicos (LabRole)

## 💰 Costos Estimados

Recursos principales (us-east-1):
- **ECS Fargate**: ~$30-50/mes (2 tareas, 0.5 vCPU, 1GB RAM)
- **RDS db.t3.micro**: ~$15/mes
- **ALB**: ~$20/mes
- **S3**: <$1/mes
- **ECR**: ~$0.10/GB/mes

**Total estimado**: ~$65-85/mes

## 🐛 Troubleshooting

### ECS no puede pull de ECR
- Verifica que la imagen exista: `aws ecr list-images --repository-name matchmarket-backend`
- Revisa los logs: `aws logs tail /ecs/MatchMarket --follow`

### Frontend no se actualiza
- Limpiar cache del bucket S3 o usar versionado de archivos
- Verificar que el build fue exitoso

### Base de datos no conecta
- Verificar security groups
- Verificar que el backend esté en las subnets privadas correctas

## 📞 Soporte

Para más información, revisa la documentación:
- **Despliegue completo**: [DEPLOY.md](DEPLOY.md)
- **Scripts multiplataforma**: `scripts/` directory
