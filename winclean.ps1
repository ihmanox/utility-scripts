# Script PowerShell para limpiar carpetas de usuario (Win10/Win11)
# ⚠️ ADVERTENCIA: Esto borra todo en las carpetas listadas sin confirmación.
# WinClean.ps1 - Script para Windows 10/11 que borra todos los archivos y subcarpetas 
# de Escritorio, Documentos, Descargas, Música, Imágenes, Videos y Objetos 3D, dejándolas vacías.

#####################################################################
# ⚡ EJECUCIÓN RÁPIDA
#
# Quick execution Commands:
#     Set-Location "$env:USERPROFILE\Desktop"
#  Ejecuta el script con:
#    powershell -ExecutionPolicy Bypass -File .\winclean.ps1
#
# ✅ Al finalizar, las carpetas Desktop, Documents, Downloads, Music, 
#    Pictures, Videos y 3D Objects quedarán totalmente vacías.
#####################################################################

# WinClean-Force.ps1
# Script agresivo para limpiar carpetas de usuario (Win10/Win11)
# Elimina incluso archivos con nombres largos, bloqueados o con permisos extraños

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

        # Buscar todos los elementos, incluyendo ocultos y del sistema
        Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $FullPath = $_.FullName

                # Usar la ruta extendida \\?\ para evitar problemas con nombres largos
                $ExtendedPath = "\\?\$FullPath"

                # Forzar reset de permisos (en caso de Access Denied)
                takeown /F "$FullPath" /A /R /D Y | Out-Null
                icacls "$FullPath" /grant Administrators:F /T /C | Out-Null

                # Intentar eliminar con Remove-Item
                Remove-Item -LiteralPath $ExtendedPath -Recurse -Force -ErrorAction Stop
                Write-Host "   Borrado: $FullPath" -ForegroundColor Green
            }
            catch {
                Write-Host "   No se pudo borrar: $($_.FullName)" -ForegroundColor Red
            }
        }
    }
}

Write-Host "`nTodas las carpetas de usuario fueron limpiadas (con fuerza bruta)." -ForegroundColor Green
