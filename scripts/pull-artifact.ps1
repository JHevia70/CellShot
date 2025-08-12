param(
  [string]$Workflow = ".github/workflows/build-windows.yml",
  [string]$Artifact = "CellShot-win64",
  [string]$Branch = "main",
  [string]$OutDir = "dist"
)

# 1) Requisitos
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "GitHub CLI 'gh' no está instalado. Instala con: winget install --id GitHub.cli -s winget"
  exit 1
}

# 2) Login si hace falta
try { gh auth status | Out-Null } catch { gh auth login }

# 3) Carpeta de salida
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# 4) Buscar el último run COMPLETADO con éxito en la rama indicada
$run = gh run list --workflow $Workflow --branch $Branch --json databaseId,status,conclusion,headSha -L 30 |
  ConvertFrom-Json |
  Where-Object { $_.status -eq "completed" -and $_.conclusion -eq "success" } |
  Select-Object -First 1

if (-not $run) {
  Write-Error "No hay runs exitosos para $Workflow en la rama '$Branch'."
  exit 2
}

$runId = $run.databaseId
Write-Host "Descargando artefacto '$Artifact' del run #$runId a '$OutDir'..."

# 5) Descargar
$prev = Get-ChildItem -Recurse -File $OutDir -ErrorAction SilentlyContinue
$null = gh run download $runId -n $Artifact -D $OutDir

# 6) Listar archivos nuevos
$now = Get-ChildItem -Recurse -File $OutDir
$added = Compare-Object -ReferenceObject $prev -DifferenceObject $now -Property FullName | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty FullName

if ($added) {
  Write-Host "Archivos descargados:" -ForegroundColor Green
  $added | ForEach-Object { Write-Host " - $_" }
} else {
  Write-Warning "No se detectaron archivos nuevos en '$OutDir'. Revisa que el artefacto exista y tenga contenido."
}