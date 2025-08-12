param(
  [string]$Workflow = ".github/workflows/build-windows.yml",
  [string]$Artifact = "CellShot-win64",
  [string]$Branch = "",      # autodetect por defecto
  [string]$OutDir = "dist"
)

# 1) Requisitos
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "GitHub CLI 'gh' no está instalado. Instala con: winget install --id GitHub.cli -s winget"
  exit 1
}

# 2) Login si hace falta
try { gh auth status | Out-Null } catch { gh auth login }

# 3) Detectar rama actual si no se pasó -Branch
if ([string]::IsNullOrWhiteSpace($Branch)) {
  try { $Branch = (git branch --show-current) 2>$null } catch {}
}

# 4) Carpeta de salida
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Get-Runs([string]$wf, [string]$br) {
  $args = @("run","list","--json","databaseId,status,conclusion,headBranch","-L","50")
  if ($wf) { $args += @("--workflow", $wf) }
  if ($br) { $args += @("--branch", $br) }
  $out = & gh @args
  if ([string]::IsNullOrWhiteSpace($out)) { return @() }
  return ($out | ConvertFrom-Json)
}

$ok = $false
$used = $null
$tried = @()

# 5) Estrategia de búsqueda (ramas y/o workflow)
$scopes = @(
  @{ wf=$Workflow; br=$Branch },
  @{ wf=$Workflow; br=$null },
  @{ wf=$null;     br=$Branch },
  @{ wf=$null;     br=$null }
)

foreach ($scope in $scopes) {
  $runs = Get-Runs $scope.wf $scope.br
  foreach ($r in $runs) {
    if ($r.status -ne "completed" -or $r.conclusion -ne "success") { continue }
    if ($tried -contains $r.databaseId) { continue }
    $tried += $r.databaseId
    Write-Host "Probando run #$($r.databaseId) (branch=$($r.headBranch))..."
    try {
      gh run download $r.databaseId -n $Artifact -D $OutDir
      $ok = $true
      $used = $r
      break
    } catch {
      Write-Host " - no tiene artefacto '$Artifact' o fallo de descarga; probando otro..."
    }
  }
  if ($ok) { break }
}

if (-not $ok) {
  Write-Error "No se pudo encontrar/descargar el artefacto '$Artifact' en los últimos runs."
  exit 3
}

# 6) Listar archivos descargados
Get-ChildItem -Recurse -File $OutDir | Select-Object FullName
Write-Host "Descargado OK desde run #$($used.databaseId) (branch=$($used.headBranch))." -ForegroundColor Green