# 📜 Scripts de Construcción del Frontend

Este proyecto incluye scripts multiplataforma para construir e implementar automáticamente el frontend Vue.js.

## 📂 Archivos

| Archivo | Plataforma | Descripción |
|---------|-----------|-------------|
| `build_frontend.sh` | Linux, Mac, Git Bash | Script bash multiplataforma |
| `build_frontend.bat` | Windows CMD/PowerShell | Script batch nativo de Windows |
| `frontend.tf` | Todos | Orquestación Terraform con detección automática de SO |

## 🔄 Detección Automática de Sistema Operativo

Terraform detecta automáticamente tu sistema operativo y ejecuta el script correcto:

```hcl
# En frontend.tf
provisioner "local-exec" {
  command     = substr(pathexpand("~"), 0, 1) == "/" ? 
                "bash build_frontend.sh ${module.alb.dns_name}" : 
                "build_frontend.bat ${module.alb.dns_name}"
  interpreter = substr(pathexpand("~"), 0, 1) == "/" ? 
                ["bash", "-c"] : 
                ["cmd", "/C"]
}
```

**Cómo funciona:**
- `pathexpand("~")` → Expande el directorio home
- En Linux/Mac: `/home/user` o `/Users/user` (empieza con `/`)
- En Windows: `C:\Users\user` (empieza con `C`)
- `substr(..., 0, 1) == "/"` → Detecta si es Unix o Windows

## 🎯 Flujo de Ejecución

### En Linux/Mac/Git Bash

```bash
terraform apply
  ↓
Detecta sistema Unix (path empieza con /)
  ↓
Ejecuta: bash build_frontend.sh <alb_dns>
  ↓
build_frontend.sh:
  1. git clone/update del frontend
  2. Crea .env con VITE_API_BASE_URL
  3. npm install
  4. npm run build
  5. cp -r frontend-source/dist/* dist/
  ↓
Terraform sube archivos a S3
```

### En Windows CMD

```cmd
terraform apply
  ↓
Detecta sistema Windows (path NO empieza con /)
  ↓
Ejecuta: build_frontend.bat <alb_dns>
  ↓
build_frontend.bat:
  1. git clone/update del frontend
  2. Crea .env con VITE_API_BASE_URL
  3. npm install
  4. npm run build
  5. xcopy frontend-source\dist\* dist\
  ↓
Terraform sube archivos a S3
```

## 🛠️ Diferencias entre Scripts

### build_frontend.sh (Bash)
```bash
# Manejo de errores
set -e  # Exit on error

# Operaciones de archivos
rm -rf dist/*
cp -r "$FRONTEND_DIR/dist/"* dist/

# Variables
ALB_URL=$1
```

### build_frontend.bat (Windows)
```batch
@echo off
setlocal EnableDelayedExpansion

REM Manejo de errores
if errorlevel 1 (
    echo Error: npm install failed
    exit /b 1
)

REM Operaciones de archivos
rmdir /s /q dist
xcopy /E /I /Y "%FRONTEND_DIR%\dist\*" "dist\"

REM Variables
set ALB_URL=%1
```

## 🧪 Pruebas Manuales

### Probar el script bash
```bash
# Linux/Mac/Git Bash
bash build_frontend.sh "my-alb-123456.us-east-1.elb.amazonaws.com"
```

### Probar el script batch
```cmd
REM Windows CMD
build_frontend.bat my-alb-123456.us-east-1.elb.amazonaws.com
```

### Probar con Terraform
```bash
# Cualquier sistema
terraform init
terraform plan
terraform apply
```

## 📋 Comparación de Comandos

| Operación | Bash (sh) | Batch (bat) |
|-----------|-----------|-------------|
| Comentarios | `#` | `REM` |
| Variables | `VAR=$1` | `set VAR=%1` |
| Condicional | `if [ -d "dir" ]` | `if exist "dir"` |
| Eliminar dir | `rm -rf dir` | `rmdir /s /q dir` |
| Copiar recursivo | `cp -r src/ dst/` | `xcopy /E /I /Y src\* dst\` |
| Cambiar dir | `cd dir` | `cd dir` |
| Ejecutar comando | `npm install` | `call npm install` |
| Salir con error | `exit 1` | `exit /b 1` |
| Crear archivo | `cat > file << EOF` | `(echo line1 & echo line2) > file` |

## 🔍 Troubleshooting por Plataforma

### Linux/Mac
```bash
# Dar permisos de ejecución
chmod +x build_frontend.sh

# Ver errores detallados
bash -x build_frontend.sh "alb-dns-here"

# Verificar bash
which bash
bash --version
```

### Windows CMD
```cmd
REM Ver errores detallados
build_frontend.bat alb-dns-here

REM Verificar que CMD está en modo correcto
chcp 65001

REM Ejecutar como administrador si hay problemas de permisos
```

### Windows Git Bash
```bash
# Usar el script de Linux
bash build_frontend.sh "alb-dns-here"

# Verificar Git Bash
which bash
bash --version
```

## 🎓 Funciones Terraform Utilizadas

En el sistema de build utilizamos estas funciones de Terraform:

1. **`substr(string, offset, length)`** - Extraer substring para detectar SO
2. **`pathexpand(path)`** - Expandir el path del home directory
3. **Operador ternario `? :`** - Condicional para elegir comando correcto
4. **`module.alb.dns_name`** - Interpolación de outputs de módulos

## 📚 Referencias

- **Bash Scripting**: [GNU Bash Manual](https://www.gnu.org/software/bash/manual/)
- **Windows Batch**: [Microsoft CMD Reference](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands)
- **Terraform Functions**: [Terraform String Functions](https://www.terraform.io/language/functions/string)
- **Node.js**: [nodejs.org](https://nodejs.org/)
- **Vite Environment Variables**: [Vite Env Variables](https://vitejs.dev/guide/env-and-mode.html)

## ✅ Checklist de Compatibilidad

Antes de ejecutar `terraform apply`, verifica:

- [ ] Node.js instalado (`node --version`)
- [ ] npm instalado (`npm --version`)
- [ ] Git instalado (`git --version`)
- [ ] Terraform instalado (`terraform --version`)
- [ ] Conexión a internet (para clonar repo y npm install)
- [ ] Permisos de escritura en el directorio actual

## 🚀 Inicio Rápido

```bash
# 1. Verificar requisitos
node --version && npm --version && git --version && terraform --version

# 2. Inicializar Terraform
terraform init

# 3. Aplicar (incluye build automático del frontend)
terraform apply

# 4. Ver URLs
terraform output website_url
terraform output frontend_backend_url
```

¡Eso es todo! El sistema detecta automáticamente tu SO y ejecuta el script correcto. 🎉

