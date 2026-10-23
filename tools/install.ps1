<#
.SYNOPSIS
    Instala, actualiza, diagnostica o quita agent-baseline en un proyecto o workspace.

.DESCRIPTION
    Modo local (recomendado): copia reglas y skills dentro del proyecto, en .baseline/,
    y deja un puntero en AGENTS.md. El modo global queda para una version posterior.

    -Project   instala en un proyecto
    -Workspace instala ruteo en la raiz de un workspace multi-proyecto
    -Update    refresca lo ya instalado segun el manifiesto
    -Doctor    verifica hashes contra el manifiesto
    -Uninstall quita solo lo que agrego, y conserva la memoria del proyecto

.PARAMETER Skills
    Skills a instalar, separadas por coma. Si se omite, se detectan por marcadores.

.PARAMETER Target
    Cliente a configurar: opencode (por defecto) o none.

.EXAMPLE
    .\tools\install.ps1 -Project D:\Repo\frontend -Skills angular
    .\tools\install.ps1 -Project . -WhatIf
    .\tools\install.ps1 -Workspace D:\Repo
    .\tools\install.ps1 -Project . -Doctor
    .\tools\install.ps1 -Project . -Uninstall -WhatIf
#>
param(
    [string]$Project,
    [string]$Workspace,
    [string[]]$Skills,
    [string]$Target = 'opencode',
    [switch]$Update,
    [switch]$Uninstall,
    [switch]$Doctor,
    [switch]$WhatIf,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Version = ([System.IO.File]::ReadAllText((Join-Path $Root 'VERSION'))).Trim()
$ManifestName = '.baseline.json'
$PayloadDir = '.baseline'
$BackupRoot = '.baseline-backup'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

function Fail { param([string]$Message) Write-Host $Message -ForegroundColor Red; exit 1 }
function Write-Utf8 { param([string]$Path, [string]$Text) [System.IO.File]::WriteAllText($Path, $Text, $Utf8) }
function Get-Sha { param([string]$Path) (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }

function Get-SkillNames {
    Get-ChildItem -LiteralPath (Join-Path $Root 'skills') -Directory |
        Sort-Object Name | Select-Object -ExpandProperty Name
}

function Detect-Skills {
    param([string]$Path)
    $found = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath (Join-Path $Path 'angular.json')) { $found.Add('angular') }
    if ((Test-Path -LiteralPath (Join-Path $Path 'pyproject.toml')) -or (Test-Path -LiteralPath (Join-Path $Path 'requirements.txt'))) {
        $found.Add('fastapi'); $found.Add('sql')
    }
    if (Test-Path -LiteralPath (Join-Path $Path 'Dockerfile')) { $found.Add('docker') }
    if (Test-Path -LiteralPath (Join-Path $Path 'docker-compose.yml')) { $found.Add('docker') }
    if (Test-Path -LiteralPath (Join-Path $Path '.github\workflows')) { $found.Add('github-actions') }
    if (Test-Path -LiteralPath (Join-Path $Path 'Chart.yaml')) { $found.Add('kubernetes') }
    Get-ChildItem -LiteralPath $Path -Filter *.csproj -ErrorAction SilentlyContinue | ForEach-Object { if ($found -notcontains 'dotnet') { $found.Add('dotnet') } }
    return @($found | Select-Object -Unique)
}

function Ask-Choice {
    param([string]$Question, [string[]]$Options)
    Write-Host ""
    Write-Host $Question -ForegroundColor Cyan
    for ($i = 0; $i -lt $Options.Count; $i++) { Write-Host ("  [{0}] {1}" -f ($i + 1), $Options[$i]) }
    while ($true) {
        $answer = Read-Host "Opcion"
        $n = 0
        if ([int]::TryParse($answer, [ref]$n) -and $n -ge 1 -and $n -le $Options.Count) { return $n }
        Write-Host "  Elige un numero entre 1 y $($Options.Count)" -ForegroundColor Yellow
    }
}

function Backup-File {
    param([string]$Path, [string]$BackupDir)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
    Copy-Item -LiteralPath $Path -Destination (Join-Path $BackupDir (Split-Path $Path -Leaf)) -Force
}

function Merge-Pointer {
    param([string]$Existing)
    $startMarker = '<!-- agent-baseline:start -->'
    $endMarker = '<!-- agent-baseline:end -->'
    $body = "# AGENTS.md`n`n> Las reglas de este proyecto viven en ``.baseline/AGENTS.md``. Leelas antes de tocar codigo.`n> Instalado con agent-baseline $Version. No edites este bloque: edita ``.baseline/AGENTS.md``."
    $block = $startMarker + "`n" + $body + "`n" + $endMarker
    if ($Existing -match '(?s)<!-- agent-baseline:start -->.*?<!-- agent-baseline:end -->') {
        return ($Existing -replace '(?s)<!-- agent-baseline:start -->.*?<!-- agent-baseline:end -->', $block)
    }
    if ([string]::IsNullOrWhiteSpace($Existing)) { return $block + "`n" }
    return $block + "`n`n" + $Existing.TrimStart()
}

function Merge-OpenCode {
    param([string]$ProjectPath)
    $cfgPath = Join-Path $ProjectPath 'opencode.json'
    $templatePath = Join-Path $Root 'templates\targets\opencode.json'
    if (Test-Path -LiteralPath $cfgPath) {
        $cfg = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json
    } else {
        $cfg = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Json
        Write-Utf8 $cfgPath ($cfg | ConvertTo-Json -Depth 10)
        return 'creado'
    }
    $changed = $false
    foreach ($entry in @(
        @{ Key = 'instructions'; Value = '.baseline/AGENTS.md' },
        @{ Key = 'skills'; Value = '.baseline/skills' }
    )) {
        if (-not $cfg.PSObject.Properties[$entry.Key]) {
            $cfg | Add-Member -NotePropertyName $entry.Key -NotePropertyValue @($entry.Value)
            $changed = $true
        } elseif (@($cfg.($entry.Key)) -notcontains $entry.Value) {
            $cfg.($entry.Key) = @(@($cfg.($entry.Key)) + $entry.Value)
            $changed = $true
        }
    }
    if (-not $cfg.PSObject.Properties['permissions']) {
        $tpl = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Json
        $cfg | Add-Member -NotePropertyName 'permissions' -NotePropertyValue $tpl.permissions
        $changed = $true
    }
    if ($changed) { Write-Utf8 $cfgPath ($cfg | ConvertTo-Json -Depth 10); return 'fusionado' }
    return 'sin cambios'
}

function Install-Project {
    param([string]$Path, [string[]]$SkillList)

    if (-not (Test-Path -LiteralPath $Path)) { Fail "No existe la ruta: $Path" }
    $payload = Join-Path $Path $PayloadDir
    $manifestPath = Join-Path $Path $ManifestName
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupDir = Join-Path (Join-Path $Path $BackupRoot) $stamp

    if ((Test-Path -LiteralPath $payload) -and -not $Update -and -not $Force) {
        Fail "Ya hay una instalacion en $payload. Usa -Update para refrescar o -Uninstall para quitarla."
    }

    $prev = $null
    if (Test-Path -LiteralPath $manifestPath) { $prev = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json }

    Write-Host ""
    Write-Host ("Proyecto : {0}" -f $Path)
    Write-Host ("Version  : {0}" -f $Version)
    Write-Host ("Skills   : {0}" -f ($SkillList -join ', '))
    Write-Host ("Target   : {0}" -f $Target)

    if ($WhatIf) {
        Write-Host ""
        Write-Host "Plan (no se escribe nada):" -ForegroundColor Yellow
        Write-Host ("  crear {0}\AGENTS.md y {0}\VERSION" -f $PayloadDir)
        foreach ($s in $SkillList) { Write-Host ("  copiar {0}\skills\{1}" -f $PayloadDir, $s) }
        Write-Host ("  escribir {0}" -f $ManifestName)
        Write-Host "  crear o fusionar AGENTS.md en la raiz"
        if ($Target -eq 'opencode') { Write-Host "  crear o fusionar opencode.json" }
        return
    }

    if (Test-Path -LiteralPath $payload) { Backup-File -Path $payload -BackupDir $backupDir }
    New-Item -ItemType Directory -Force -Path $payload | Out-Null
    Copy-Item -LiteralPath (Join-Path $Root 'AGENTS.md') -Destination (Join-Path $payload 'AGENTS.md') -Force
    Copy-Item -LiteralPath (Join-Path $Root 'VERSION') -Destination (Join-Path $payload 'VERSION') -Force

    $skillsDst = Join-Path $payload 'skills'
    New-Item -ItemType Directory -Force -Path $skillsDst | Out-Null
    foreach ($s in $SkillList) {
        $src = Join-Path (Join-Path (Join-Path $Root 'skills') $s) 'SKILL.md'
        if (-not (Test-Path -LiteralPath $src)) { Fail "Skill desconocida: $s" }
        $srcDir = Split-Path $src -Parent
        $dst = Join-Path $skillsDst $s
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        Copy-Item -Path (Join-Path $srcDir '*') -Destination $dst -Recurse -Force
        if (-not (Test-Path -LiteralPath (Join-Path $dst 'SKILL.md'))) { Fail "No se pudo copiar la skill: $s" }
    }

    $rootAgents = Join-Path $Path 'AGENTS.md'
    $existingPointer = ''
    if (Test-Path -LiteralPath $rootAgents) {
        Backup-File -Path $rootAgents -BackupDir $backupDir
        $existingPointer = [System.IO.File]::ReadAllText($rootAgents)
    }
    Write-Utf8 $rootAgents (Merge-Pointer $existingPointer)

    $targetState = 'none'
    $targetLabel = 'opencode.json'
    $targetCreated = $false
    $targetFiles = @()
    if ($prev -ne $null -and $prev.PSObject.Properties['targetFileCreated']) { $targetCreated = [bool]$prev.targetFileCreated }
    if ($Target -eq 'opencode') {
        $cfgPath = Join-Path $Path 'opencode.json'
        if (-not (Test-Path -LiteralPath $cfgPath)) { $targetCreated = $true }
        Backup-File -Path $cfgPath -BackupDir $backupDir
        $targetState = Merge-OpenCode -ProjectPath $Path
    }
    elseif ($Target -eq 'cline' -or $Target -eq 'kilo') {
        $rel = '.clinerules\agent-baseline.md'
        if ($Target -eq 'kilo') { $rel = '.kilocode\rules\agent-baseline.md' }
        $pointerPath = Join-Path $Path $rel
        Backup-File -Path $pointerPath -BackupDir $backupDir
        New-Item -ItemType Directory -Force -Path (Split-Path $pointerPath -Parent) | Out-Null
        Copy-Item -LiteralPath (Join-Path $Root ("templates\targets\$Target.md")) -Destination $pointerPath -Force
        $targetFiles += $rel
        $targetLabel = $rel
        $targetState = 'puntero'
    }
    elseif ($Target -ne 'none') {
        Fail "Target desconocido: $Target. Validos: opencode, cline, kilo, none."
    }

    $files = @{}
    $files['.baseline/AGENTS.md'] = Get-Sha (Join-Path $payload 'AGENTS.md')
    foreach ($s in $SkillList) {
        $files[".baseline/skills/$s/SKILL.md"] = Get-Sha (Join-Path (Join-Path $skillsDst $s) 'SKILL.md')
    }

    $manifest = [ordered]@{
        schemaVersion     = 1
        baselineVersion   = $Version
        mode              = 'local'
        installedAt       = (Get-Date).ToString('o')
        skills            = @($SkillList)
        targets           = @($Target)
        targetFileCreated = $targetCreated
        targetFiles       = @($targetFiles)
        files             = $files
    }
    Write-Utf8 $manifestPath ($manifest | ConvertTo-Json -Depth 6)

    Write-Host ""
    Write-Host "Instalado." -ForegroundColor Green
    Write-Host ("  {0}\AGENTS.md" -f $PayloadDir)
    Write-Host ("  {0}\skills\{1}" -f $PayloadDir, ($SkillList -join ','))
    Write-Host ("  {0}" -f $ManifestName)
    Write-Host ("  {0}: {1}" -f $targetLabel, $targetState)
    Write-Host "Abre el agente dentro del proyecto para que lea AGENTS.md."
}

function Install-Workspace {
    param([string]$Path)
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupDir = Join-Path (Join-Path $Path $BackupRoot) $stamp
    $agents = Join-Path $Path 'AGENTS.md'
    $dev = Join-Path $Path 'DEVELOPMENT.md'

    Write-Host ""
    Write-Host ("Workspace: {0}" -f $Path)
    if ($WhatIf) {
        Write-Host "Plan (no se escribe nada): AGENTS.md de ruteo + DEVELOPMENT.md de composicion." -ForegroundColor Yellow
        return
    }

    if (Test-Path -LiteralPath $agents) {
        Backup-File -Path $agents -BackupDir $backupDir
    } else {
        Copy-Item -LiteralPath (Join-Path $Root 'templates\AGENTS-workspace.md') -Destination $agents -Force
    }
    if (Test-Path -LiteralPath $dev) {
        Backup-File -Path $dev -BackupDir $backupDir
    } else {
        Copy-Item -LiteralPath (Join-Path $Root 'templates\DEVELOPMENT-workspace.md') -Destination $dev -Force
    }
    Write-Host "Workspace inicializado: AGENTS.md y DEVELOPMENT.md en la raiz." -ForegroundColor Green
}

function Remove-Project {
    param([string]$Path)
    $payload = Join-Path $Path $PayloadDir
    $manifestPath = Join-Path $Path $ManifestName
    if (-not (Test-Path -LiteralPath $payload)) { Fail "No hay instalacion en $Path" }

    $m = $null
    if (Test-Path -LiteralPath $manifestPath) { $m = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json }

    Write-Host ""
    Write-Host ("Quitar de: {0}" -f $Path)
    if ($WhatIf) {
        Write-Host "Plan (no se borra nada): quitar .baseline, el puntero y las entradas de opencode.json." -ForegroundColor Yellow
        return
    }

    Remove-Item -LiteralPath $payload -Recurse -Force
    if (Test-Path -LiteralPath $manifestPath) { Remove-Item -LiteralPath $manifestPath -Force }

    $rootAgents = Join-Path $Path 'AGENTS.md'
    if (Test-Path -LiteralPath $rootAgents) {
        $text = [System.IO.File]::ReadAllText($rootAgents)
        if ($text -match '(?s)<!-- agent-baseline:start -->.*?<!-- agent-baseline:end -->') {
            $rest = ($text -replace '(?s)<!-- agent-baseline:start -->.*?<!-- agent-baseline:end -->', '').Trim()
            if ([string]::IsNullOrWhiteSpace($rest)) {
                Remove-Item -LiteralPath $rootAgents -Force
                Write-Host "  puntero AGENTS.md eliminado"
            } else {
                Write-Utf8 $rootAgents $rest
                Write-Host "  bloque del puntero quitado; AGENTS.md conservado con tu contenido"
            }
        } elseif ($text -match 'agent-baseline') {
            Remove-Item -LiteralPath $rootAgents -Force
            Write-Host "  puntero AGENTS.md eliminado"
        } else {
            Write-Host "  AGENTS.md conservado (no lo genero el instalador)" -ForegroundColor Yellow
        }
    }

    $cfgPath = Join-Path $Path 'opencode.json'
    if (Test-Path -LiteralPath $cfgPath) {
        $created = ($m -ne $null -and $m.PSObject.Properties['targetFileCreated'] -and $m.targetFileCreated)
        if ($created) {
            Remove-Item -LiteralPath $cfgPath -Force
            Write-Host "  opencode.json eliminado (lo creo el instalador)"
        } else {
            $cfg = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json
            foreach ($key in @('instructions', 'skills')) {
                if ($cfg.PSObject.Properties[$key]) {
                    $cfg.$key = @(@($cfg.$key) | Where-Object { $_ -ne ".baseline/AGENTS.md" -and $_ -ne '.baseline/skills' })
                }
            }
            Write-Utf8 $cfgPath ($cfg | ConvertTo-Json -Depth 10)
            Write-Host "  entradas quitadas de opencode.json"
        }
    }

    if ($m -ne $null -and $m.PSObject.Properties['targetFiles']) {
        foreach ($rel in @($m.targetFiles)) {
            if ([string]::IsNullOrWhiteSpace($rel)) { continue }
            $pointerFile = Join-Path $Path ($rel -replace '/', '\')
            if (Test-Path -LiteralPath $pointerFile) {
                $pointerText = [System.IO.File]::ReadAllText($pointerFile)
                if ($pointerText -match 'agent-baseline') {
                    Remove-Item -LiteralPath $pointerFile -Force
                    Write-Host ("  puntero eliminado: {0}" -f $rel)
                    $parentDir = Split-Path $pointerFile -Parent
                    if ((Test-Path -LiteralPath $parentDir) -and @(Get-ChildItem -LiteralPath $parentDir -Force).Count -eq 0) {
                        Remove-Item -LiteralPath $parentDir -Force
                        $grandDir = Split-Path $parentDir -Parent
                        if ((Split-Path $grandDir -Leaf) -eq '.kilocode' -and (Test-Path -LiteralPath $grandDir) -and @(Get-ChildItem -LiteralPath $grandDir -Force).Count -eq 0) {
                            Remove-Item -LiteralPath $grandDir -Force
                        }
                    }
                }
            }
        }
    }

    Write-Host "Listo. La memoria del proyecto (DEVELOPMENT.md, README.md) no se toco." -ForegroundColor Green
    Write-Host ("Backups disponibles en {0}" -f $BackupRoot)
}

function Test-Doctor {
    param([string]$Path)
    $manifestPath = Join-Path $Path $ManifestName
    if (-not (Test-Path -LiteralPath $manifestPath)) { Fail "No hay manifiesto en $Path" }
    $m = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $bad = 0
    Write-Host ""
    Write-Host ("Manifiesto: v{0}, {1}, {2} skill(s)" -f $m.baselineVersion, $m.mode, @($m.skills).Count)
    foreach ($prop in $m.files.PSObject.Properties) {
        $rel = $prop.Name
        $full = Join-Path $Path ($rel -replace '/', '\')
        if (-not (Test-Path -LiteralPath $full)) {
            Write-Host ("FALLO  falta {0}" -f $rel) -ForegroundColor Red
            $bad++
            continue
        }
        if ((Get-Sha $full) -ne $prop.Value) {
            Write-Host ("AVISO  modificado a mano: {0}" -f $rel) -ForegroundColor Yellow
        } else {
            Write-Host ("OK     {0}" -f $rel) -ForegroundColor Green
        }
    }
    $installed = $m.baselineVersion
    if ($installed -ne $Version) {
        Write-Host ("AVISO  instalado v{0}, disponible v{1}. Corre -Update." -f $installed, $Version) -ForegroundColor Yellow
    }
    if ($bad -gt 0) { exit 1 }
}

# --- Flujo principal ---------------------------------------------------------
Write-Host ("agent-baseline {0}" -f $Version) -ForegroundColor Cyan

if ($Doctor) {
    $path = if ($Project) { $Project } else { (Get-Location).Path }
    Test-Doctor -Path $path
    exit 0
}

if ($Uninstall) {
    $path = if ($Project) { $Project } else { (Get-Location).Path }
    Remove-Project -Path $path
    exit 0
}

if ($Workspace) {
    Install-Workspace -Path $Workspace
    exit 0
}

$targetPath = if ($Project) { $Project } else { (Get-Location).Path }

if ($Update) {
    $prevManifest = Join-Path $targetPath $ManifestName
    if (-not (Test-Path -LiteralPath $prevManifest)) {
        Fail "No hay manifiesto en $targetPath. No hay nada que actualizar: instala primero."
    }
    $mPrev = Get-Content -LiteralPath $prevManifest -Raw | ConvertFrom-Json
    if (-not $Skills -or $Skills.Count -eq 0) { $Skills = @(@($mPrev.skills) | Where-Object { $_ }) }
    if (-not $PSBoundParameters.ContainsKey('Target') -and $mPrev.PSObject.Properties['targets']) {
        $Target = @(@($mPrev.targets) | Where-Object { $_ })[0]
    }
    Write-Host ("Manifiesto: v{0}, skills [{1}], target {2}" -f $mPrev.baselineVersion, (@($Skills) -join ','), $Target) -ForegroundColor Cyan
}

if (-not $Project -and -not $WhatIf) {
    $children = @(Get-ChildItem -LiteralPath $targetPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName '.git') })
    if ($children.Count -ge 2) {
        Write-Host ""
        Write-Host "Detecte varias subcarpetas con .git:" -ForegroundColor Yellow
        $children | ForEach-Object { Write-Host ("  - {0}" -f $_.Name) }
        $choice = Ask-Choice -Question "Que es esta carpeta?" -Options @('Workspace con varios proyectos', 'Un solo proyecto (aunque tenga subcarpetas)', 'Cancelar')
        if ($choice -eq 3) { Write-Host "Cancelado."; exit 0 }
        if ($choice -eq 1) { Install-Workspace -Path $targetPath; exit 0 }
    }
}

if (-not $Skills -or $Skills.Count -eq 0) {
    $detected = Detect-Skills -Path $targetPath
    if ($detected.Count -eq 0) {
        Write-Host "No detecte el stack. Skills disponibles:" -ForegroundColor Yellow
        Write-Host ("  " + ((Get-SkillNames) -join ', '))
        $answer = Read-Host "Escribe las skills separadas por coma (vacio = ninguna)"
        $Skills = @($answer -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    } else {
        Write-Host ("Skills detectadas: {0}" -f ($detected -join ', '))
        $ok = Read-Host "Instalar esas? (s/n)"
        if ($ok -match '^[sS]') { $Skills = $detected }
        else {
            $answer = Read-Host "Escribe las skills separadas por coma"
            $Skills = @($answer -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
    }
}

Install-Project -Path $targetPath -SkillList $Skills
