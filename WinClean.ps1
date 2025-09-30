# Script PowerShell para limpiar carpetas de usuario (Win10/Win11)
# ⚠️ ADVERTENCIA: Esto borra todo en las carpetas listadas sin confirmación.
# WinClean.ps1 - Script para Windows 10/11 que borra todos los archivos y subcarpetas 
# de Escritorio, Documentos, Descargas, Música, Imágenes, Videos y Objetos 3D, dejándolas vacías.

#####################################################################
# ⚡ EJECUCIÓN RÁPIDA
#
# 1. Copia este script en un archivo, por ejemplo: WinClean.ps1
# 2. Abre PowerShell como el usuario que quieras limpiar.
# 3. Ejecuta el script con:
#    powershell -ExecutionPolicy Bypass -File .\WinClean.ps1
#
# ✅ Al finalizar, las carpetas Desktop, Documents, Downloads, Music, 
#    Pictures, Videos y 3D Objects quedarán totalmente vacías.
#####################################################################



# Carpeta base del usuario
$UserProfile = [Environment]::GetFolderPath("UserProfile")

# Carpetas principales a limpiar
$Folders = @(
    "Desktop",
    "Documents",
    "Downloads",
    "Music",
    "Pictures",
    "Videos",
    "3D Objects"
)

foreach ($Folder in $Folders) {
    $Path = Join-Path $UserProfile $Folder
    if (Test-Path $Path) {
        Write-Host "Limpiando $Path ..." -ForegroundColor Yellow
        # Borra TODO (archivos y subcarpetas) dentro, dejando solo la carpeta raíz
        Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n¡Todas las carpetas de usuario fueron limpiadas!" -ForegroundColor Green
