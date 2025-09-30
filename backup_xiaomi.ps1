# Script para copiar archivos desde 'Download' en un dispositivo MTP a una carpeta de backup en PC

# Crear el objeto Shell.Application
$shell = New-Object -ComObject Shell.Application

# Abrir "Este equipo"
$myComputer = $shell.Namespace(17)

Write-Host "Dispositivos conectados:"
$myComputer.Items() | ForEach-Object { Write-Host " - " $_.Name }

# Nombre del dispositivo
$deviceName = "Redmi Note 11S"

# Buscar el dispositivo
$device = $myComputer.Items() | Where-Object { $_.Name -like "*$deviceName*" }

if (-not $device) {
    Write-Host "ERROR: No se encontró el dispositivo '$deviceName'."
    exit
}

Write-Host "Dispositivo encontrado: $($device.Name)"

# Acceder al almacenamiento interno
$internalStorage = $device.GetFolder.Items() | Where-Object { $_.Name -like "*Internal*" }

if (-not $internalStorage) {
    Write-Host "ERROR: No se encontró el almacenamiento interno del dispositivo."
    exit
}

$internalFolder = $internalStorage.GetFolder

# Buscar la carpeta "Download"
$downloadFolder = $internalFolder.Items() | Where-Object { $_.Name -eq "Download" }

if (-not $downloadFolder) {
    Write-Host "ERROR: No se encontró la carpeta 'Download'."
    exit
}

$download = $downloadFolder.GetFolder

# Contar archivos
$totalFiles = $download.Items().Count
Write-Host "Se encontraron $totalFiles archivos en la carpeta 'Download'."

if ($totalFiles -eq 0) {
    Write-Host "No hay archivos para copiar."
    exit
}

# Carpeta de destino
$destPath = "D:\phone_backup\xiomi-backup-abril-2025\Download"

# Crear si no existe
if (-not (Test-Path $destPath)) {
    New-Item -ItemType Directory -Path $destPath | Out-Null
}

# Obtener destino como objeto Shell
$destinationFolder = $shell.Namespace($destPath)

if (-not $destinationFolder) {
    Write-Host "ERROR: No se pudo acceder a la carpeta de destino."
    exit
}

# Función para copiar con reintentos
function Copy-MTPFile {
    param (
        [object]$file,
        [object]$destShellFolder
    )

    $maxRetries = 3
    $attempt = 0
    $success = $false

    while ($attempt -lt $maxRetries -and -not $success) {
        try {
            $destShellFolder.CopyHere($file, 16)
            Start-Sleep -Seconds 3
            $success = $true
        } catch {
            Write-Host "Error copiando $($file.Name) (Intento $($attempt + 1))"
        }
        $attempt++
    }

    return $success
}

# Copiar archivos
Write-Host ""
Write-Host "Iniciando copia de archivos..."
$copiedFiles = 0

foreach ($file in $download.Items()) {
    Write-Host ("[{0}/{1}] Copiando: {2}" -f ($copiedFiles + 1), $totalFiles, $file.Name)

    if (Copy-MTPFile -file $file -destShellFolder $destinationFolder) {
        $copiedFiles++
    } else {
        Write-Host "NO se pudo copiar: $($file.Name)"
    }
}

Write-Host ""
Write-Host "Copia terminada. Archivos copiados: $copiedFiles de $totalFiles."
Pause
