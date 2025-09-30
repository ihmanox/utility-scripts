# Script para eliminar completamente VirtualBox de Windows
# Ejecutar como Administrador

Write-Host "=== ELIMINACIÓN COMPLETA DE VIRTUALBOX ===" -ForegroundColor Yellow

# Verificar si se ejecuta como administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Este script debe ejecutarse como Administrador. Abre PowerShell como administrador y vuelve a ejecutarlo." -ForegroundColor Red
    exit 1
}

Write-Host "Deteniendo servicios de VirtualBox..." -ForegroundColor Yellow

# Detener servicios de VirtualBox
$services = @("VirtualBox", "VBoxSDS", "VBoxDrv", "VBoxNetAdp", "VBoxNetLwf", "VBoxUSBMon")
foreach ($service in $services) {
    try {
        if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Write-Host "Servicio $service detenido" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "No se pudo detener el servicio $service" -ForegroundColor Red
    }
}

# Esperar un momento para que los servicios se detengan completamente
Start-Sleep -Seconds 3

Write-Host "Desinstalando VirtualBox..." -ForegroundColor Yellow

# Buscar y desinstalar VirtualBox desde programas instalados
$uninstallStrings = @()
$uninstallStrings += Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
                    Where-Object { $_.DisplayName -like "*VirtualBox*" } | 
                    Select-Object -ExpandProperty UninstallString

$uninstallStrings += Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | 
                    Where-Object { $_.DisplayName -like "*VirtualBox*" } | 
                    Select-Object -ExpandProperty UninstallString

if ($uninstallStrings.Count -eq 0) {
    Write-Host "VirtualBox no encontrado en programas instalados" -ForegroundColor Yellow
} else {
    foreach ($uninstallString in $uninstallStrings) {
        try {
            Write-Host "Ejecutando: $uninstallString" -ForegroundColor Cyan
            $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $uninstallString /S" -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-Host "VirtualBox desinstalado correctamente" -ForegroundColor Green
            } else {
                Write-Host "Error en la desinstalación (Código: $($process.ExitCode))" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Error al ejecutar el desinstalador: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "Eliminando archivos y carpetas residuales..." -ForegroundColor Yellow

# Eliminar carpetas comunes de VirtualBox
$foldersToDelete = @(
    "${env:ProgramFiles}\Oracle\VirtualBox",
    "${env:ProgramFiles(x86)}\Oracle\VirtualBox",
    "$env:PUBLIC\Desktop\VirtualBox.lnk",
    "$env:USERPROFILE\Desktop\VirtualBox.lnk",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Oracle VM VirtualBox",
    "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Oracle VM VirtualBox",
    "$env:USERPROFILE\.VirtualBox"
)

foreach ($folder in $foldersToDelete) {
    if (Test-Path $folder) {
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
            Write-Host "Eliminado: $folder" -ForegroundColor Green
        }
        catch {
            Write-Host "No se pudo eliminar: $folder - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "Eliminando registros de VirtualBox..." -ForegroundColor Yellow

# Eliminar entradas del registro
$registryPaths = @(
    "HKLM:\SOFTWARE\Oracle\VirtualBox",
    "HKLM:\SOFTWARE\WOW6432Node\Oracle\VirtualBox",
    "HKLM:\SYSTEM\CurrentControlSet\Services\VBox*",
    "HKLM:\SYSTEM\CurrentControlSet\Services\VirtualBox",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{CFF3C5F7-4C55-48DB-8C34-32E15B1F0CF7}",
    "HKCU:\Software\Oracle\VirtualBox"
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        try {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
            Write-Host "Eliminado registro: $regPath" -ForegroundColor Green
        }
        catch {
            Write-Host "No se pudo eliminar registro: $regPath - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "Eliminando controladores y dispositivos..." -ForegroundColor Yellow

# Eliminar dispositivos VirtualBox usando devcon (si está disponible)
$devconPath = "${env:ProgramFiles}\Windows Kits\10\Tools\x64\devcon.exe"
if (Test-Path $devconPath) {
    try {
        & $devconPath remove "VBox*"
        & $devconPath remove "VirtualBox*"
        Write-Host "Dispositivos VirtualBox eliminados" -ForegroundColor Green
    }
    catch {
        Write-Host "Error al eliminar dispositivos con devcon" -ForegroundColor Red
    }
}

Write-Host "Limpiando variables de entorno..." -ForegroundColor Yellow

# Eliminar variables de entorno de VirtualBox
$envPaths = $env:PATH -split ';'
$newEnvPath = ($envPaths | Where-Object { $_ -notlike "*VirtualBox*" -and $_ -notlike "*Oracle*" }) -join ';'

# Actualizar PATH temporalmente
$env:PATH = $newEnvPath

Write-Host "Realizando limpieza final..." -ForegroundColor Yellow

# Limpiar archivos temporales
$tempFolders = @(
    "$env:TEMP\VirtualBox*",
    "$env:TEMP\Oracle*",
    "$env:TEMP\VBox*"
)

foreach ($tempFolder in $tempFolders) {
    Get-ChildItem -Path $tempFolder -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "Eliminado temporal: $($_.FullName)" -ForegroundColor Green
        }
        catch {
            Write-Host "No se pudo eliminar temporal: $($_.FullName)" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== LIMPIEZA COMPLETADA ===" -ForegroundColor Green
Write-Host "VirtualBox ha sido eliminado completamente del sistema." -ForegroundColor Green
Write-Host "Es recomendable reiniciar el equipo para completar la eliminación." -ForegroundColor Yellow

# Preguntar si reiniciar
$reboot = Read-Host "¿Deseas reiniciar el equipo ahora? (S/N)"
if ($reboot -eq 'S' -or $reboot -eq 's') {
    Write-Host "Reiniciando equipo..." -ForegroundColor Yellow
    Restart-Computer -Force
}

