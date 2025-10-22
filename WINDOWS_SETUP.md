# 🪟 Guía Rápida para Windows

## ✅ Requisitos

Antes de ejecutar `terraform apply`, asegúrate de tener instalado:

1. **Node.js** - [Descargar aquí](https://nodejs.org/)
   - Versión recomendada: 18 o superior
   - Incluye npm automáticamente

2. **Git for Windows** - [Descargar aquí](https://git-scm.com/download/win)
   - Necesario para clonar el repositorio del frontend

3. **Terraform** - [Descargar aquí](https://www.terraform.io/downloads)

## 🚀 Verificación Rápida

Abre **CMD** o **PowerShell** y ejecuta:

```cmd
node --version
npm --version
git --version
terraform --version
```

Si todos los comandos funcionan, ¡estás listo! ✅

## 🎯 Cómo Funciona

Cuando ejecutes `terraform apply`:

1. ✅ Terraform detecta automáticamente que estás en Windows
2. ✅ Usa el script `build_frontend.bat` (nativo de Windows CMD)
3. ✅ Clona el repositorio del frontend
4. ✅ Configura la URL del backend automáticamente
5. ✅ Construye el frontend con `npm run build`
6. ✅ Sube todo a S3

**No necesitas hacer nada más**, todo es automático.

## 📝 Comandos Útiles

### Aplicar infraestructura
```cmd
terraform init
terraform plan
terraform apply
```

### Ver URLs generadas
```cmd
terraform output website_url
terraform output frontend_backend_url
terraform output alb_dns_name
```

### Reconstruir solo el frontend
```cmd
terraform taint null_resource.build_frontend
terraform apply
```

### Construcción manual del frontend
```cmd
REM Obtener DNS del ALB
for /f "delims=" %%i in ('terraform output -raw alb_dns_name') do set ALB_DNS=%%i

REM Construir frontend
build_frontend.bat %ALB_DNS%
```

## 🐛 Problemas Comunes

### ❌ Error: "'node' is not recognized"

**Causa**: Node.js no está instalado o no está en el PATH

**Solución**:
1. Instala Node.js desde [nodejs.org](https://nodejs.org/)
2. **Reinicia CMD/PowerShell** (importante)
3. Verifica: `node --version`

### ❌ Error: "'git' is not recognized"

**Causa**: Git no está instalado o no está en el PATH

**Solución**:
1. Instala Git for Windows desde [git-scm.com](https://git-scm.com/download/win)
2. Durante la instalación, marca "Add Git to PATH"
3. **Reinicia CMD/PowerShell**
4. Verifica: `git --version`

### ❌ Error: "npm install failed"

**Posibles causas**:
- Sin conexión a internet
- Firewall corporativo bloqueando npm

**Solución**:
1. Verifica tu conexión a internet
2. Si estás en una red corporativa, consulta con IT sobre proxy de npm
3. Configura proxy si es necesario:
   ```cmd
   npm config set proxy http://proxy.company.com:8080
   npm config set https-proxy http://proxy.company.com:8080
   ```

### ❌ Error: "Access denied" al copiar archivos

**Causa**: Permisos insuficientes

**Solución**:
- Ejecuta CMD como **Administrador**
- Clic derecho en CMD → "Ejecutar como administrador"

### ❌ El frontend no se actualiza

**Solución**:
```cmd
terraform taint null_resource.build_frontend
terraform apply
```

O manualmente:
```cmd
rmdir /s /q frontend-source
rmdir /s /q dist
terraform apply
```

## 💡 Tips

### Usar Git Bash (Alternativa)

Si prefieres usar Git Bash en lugar de CMD:

1. Instala Git for Windows (incluye Git Bash)
2. Abre **Git Bash** en lugar de CMD
3. Usa los comandos de Linux:
   ```bash
   terraform apply
   bash build_frontend.sh $(terraform output -raw alb_dns_name)
   ```

### Usar PowerShell (Alternativa)

PowerShell también funciona perfectamente:

```powershell
# Los mismos comandos de CMD funcionan
terraform apply

# O con sintaxis de PowerShell
$ALB_DNS = terraform output -raw alb_dns_name
.\build_frontend.bat $ALB_DNS
```

## 📞 Ayuda Adicional

Si tienes problemas:

1. Lee el archivo completo: `FRONTEND_BUILD.md`
2. Verifica los requisitos en la sección de arriba
3. Asegúrate de haber reiniciado la terminal después de instalar Node.js o Git

## ✨ ¡Eso es todo!

Solo necesitas ejecutar `terraform apply` y todo se construye automáticamente. 🎉

