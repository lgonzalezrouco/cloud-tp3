# 🚀 Construcción Automática del Frontend

Este proyecto incluye un sistema automatizado para construir e implementar el frontend de Vue.js en S3.

## 📋 Funcionamiento

### Flujo Automático

1. **Terraform crea la infraestructura** (VPC, ALB, ECS, RDS, S3)
2. **Obtiene el DNS del ALB** (donde corre el backend)
3. **Ejecuta el script de build** que:
   - Clona/actualiza el repositorio del frontend
   - Crea archivo `.env` con la URL del backend
   - Instala dependencias (`npm install`)
   - Construye el proyecto (`npm run build`)
   - Copia los archivos a `dist/`
4. **Sube los archivos a S3** automáticamente

### Archivos Clave

- **`build_frontend.sh`** - Script bash para Linux/Mac/Git Bash
- **`build_frontend.bat`** - Script batch para Windows CMD
- **`frontend.tf`** - Recurso Terraform que orquesta el proceso (detecta SO automáticamente)
- **`s3.tf`** - Sube los archivos construidos a S3

## 🔧 Requisitos Previos

### Windows
**Opción 1 (CMD):**
- CMD (incluido en Windows)
- Node.js 18+ 
- npm
- git

**Opción 2 (Git Bash):**
- Git Bash (incluido con [Git for Windows](https://git-scm.com/download/win))
- Node.js 18+ 
- npm

### Linux/Mac
- bash (pre-instalado)
- Node.js 18+
- npm
- git

**Nota:** Terraform detecta automáticamente tu sistema operativo y usa el script apropiado.

## 📦 Variables de Entorno Generadas

El script crea automáticamente un `.env` en el frontend con:

```env
VITE_API_BASE_URL=http://<alb-dns-name>
VITE_APP_TITLE=Match Market
VITE_APP_DESCRIPTION=Tu marketplace de confianza
```

## 🎯 Uso

### Construcción Automática (Recomendado)

```bash
terraform apply
```

Terraform automáticamente:
1. ✅ Crea toda la infraestructura
2. ✅ Construye el frontend con la URL correcta del backend
3. ✅ Sube los archivos a S3

### Construcción Manual

Si necesitas reconstruir el frontend sin Terraform:

**Linux/Mac/Git Bash:**
```bash
# Obtener el DNS del ALB desde Terraform
ALB_DNS=$(terraform output -raw alb_dns_name)

# Ejecutar el script manualmente
bash build_frontend.sh $ALB_DNS
```

**Windows CMD:**
```cmd
REM Obtener el DNS del ALB desde Terraform
for /f "delims=" %%i in ('terraform output -raw alb_dns_name') do set ALB_DNS=%%i

REM Ejecutar el script manualmente
build_frontend.bat %ALB_DNS%
```

## 🔄 Triggers de Reconstrucción

El frontend se reconstruye automáticamente cuando:

- El DNS del ALB cambia
- Ejecutas `terraform taint null_resource.build_frontend`
- Ejecutas `terraform apply -replace="null_resource.build_frontend"`

### Forzar Reconstrucción

```bash
terraform taint null_resource.build_frontend
terraform apply
```

O directamente:

```bash
terraform apply -replace="null_resource.build_frontend"
```

## 📁 Estructura de Archivos

```
cloud-tp3/
├── build_frontend.sh        # Script de construcción
├── frontend.tf              # Orquestación Terraform
├── s3.tf                    # Upload a S3
├── dist/                    # Archivos construidos (git ignored)
└── frontend-source/         # Repo clonado (git ignored)
    ├── .env                 # Variables de entorno generadas
    ├── dist/                # Build de Vite
    └── ...
```

## 🐛 Troubleshooting

### Error: "bash: command not found" (Windows)

**Solución 1**: Terraform automáticamente usará `build_frontend.bat` en CMD  
**Solución 2**: O instala Git for Windows que incluye Git Bash

### Error: "'npm' is not recognized" (Windows)

**Solución**: 
1. Instala Node.js desde [nodejs.org](https://nodejs.org)
2. Reinicia CMD/PowerShell
3. Verifica: `npm --version`

### Error: "npm: command not found" (Linux/Mac)

**Solución**: Instala Node.js desde [nodejs.org](https://nodejs.org) o usa tu package manager:
```bash
# Ubuntu/Debian
sudo apt install nodejs npm

# Mac
brew install node
```

### Error: "permission denied: build_frontend.sh" (Linux/Mac)

**Solución**:
```bash
chmod +x build_frontend.sh
```

### El frontend no se actualiza en S3

**Solución**: Forzar reconstrucción:
```bash
terraform taint null_resource.build_frontend
terraform apply
```

### Error de clonación del repositorio

**Solución**: Verifica tu conexión a internet y acceso a GitHub:
```bash
git clone https://github.com/gcandisano/CloudFront.git
```

## 🔍 Verificación

Después de `terraform apply`, verifica:

1. **URL del frontend**:
   ```bash
   terraform output website_url
   ```

2. **URL del backend configurada**:
   ```bash
   terraform output frontend_backend_url
   ```

3. **Archivos en S3**:
   ```bash
   # Linux/Mac/Git Bash
   aws s3 ls s3://matchmarket-testing-emi/
   
   # Windows CMD (si tienes AWS CLI)
   aws s3 ls s3://matchmarket-testing-emi/
   ```

4. **Verificar que el script correcto se ejecutó**:
   - Windows CMD usará `build_frontend.bat`
   - Linux/Mac/Git Bash usará `build_frontend.sh`
   - Terraform lo detecta automáticamente

## 📝 Notas Importantes

- El directorio `frontend-source/` no se sube a git (está en `.gitignore`)
- El directorio `dist/` tampoco se sube a git
- El script siempre hace `git reset --hard` para garantizar un build limpio
- La construcción solo ocurre si el DNS del ALB cambia (gracias a `triggers`)

## 🎓 Meta-argumentos Utilizados

Este sistema utiliza varios meta-argumentos de Terraform:

1. **`depends_on`** - En todos los recursos de S3 para esperar el build
2. **`triggers`** - En `null_resource` para detectar cambios en el ALB
3. **`for_each`** - En los archivos CSS/JS para subirlos dinámicamente

## 🔗 Referencias

- [Repositorio del Frontend](https://github.com/gcandisano/CloudFront)
- [Terraform null_resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)
- [Vite Environment Variables](https://vitejs.dev/guide/env-and-mode.html)

