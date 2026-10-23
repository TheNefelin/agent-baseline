<#
.SYNOPSIS
    Mide el presupuesto de contexto del catalogo y falla si una skill se sale.

.DESCRIPTION
    Estima tokens como caracteres / 4. No llama a ningun modelo: sirve para detectar
    deriva silenciosa antes de que el contexto se ahogue.

    Metricas:
      - Cuerpo por skill    : lo que se carga al abrir la skill. Limite: -MaxSkillTokens.
      - Description         : lo que se paga en CADA request. Limite: -MaxDescriptionChars.
      - Peor caso por request: cuerpo mas grande + su description (cota superior real).
      - Catalogo en disco   : suma de cuerpos. Informativo; limite: -MaxCatalogTokens.

    Las references NO cuentan en el presupuesto: se leen bajo demanda.

.PARAMETER MaxSkillTokens
    Tokens maximos estimados del cuerpo de un SKILL.md.

.PARAMETER MaxDescriptionChars
    Caracteres maximos de la description (es lo que se paga en cada request).

.PARAMETER MaxCatalogTokens
    Tokens maximos estimados de la suma de cuerpos del catalogo.

.EXAMPLE
    .\tools\budget.ps1
    .\tools\budget.ps1 -MaxSkillTokens 6000 -MaxDescriptionChars 260
#>
param(
    [int]$MaxSkillTokens = 7000,
    [int]$MaxDescriptionChars = 300,
    [int]$MaxCatalogTokens = 60000
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SkillsDir = Join-Path $Root 'skills'

function Get-Estimate { param([int]$Chars) [int][math]::Ceiling($Chars / 4.0) }

$rows = @()
$totalBodyChars = 0
$descChars = 0
$fail = 0

foreach ($dir in (Get-ChildItem -LiteralPath $SkillsDir -Directory | Sort-Object Name)) {
    $f = Join-Path -Path $dir.FullName -ChildPath 'SKILL.md'
    if (-not (Test-Path -LiteralPath $f)) { continue }
    $text = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
    $descLen = 0
    if ($text -match '(?m)^description:\s*(.+)$') {
        $descLen = $Matches[1].Trim().Trim('"').Trim("'").Length
    }
    $totalBodyChars += $text.Length
    $descChars += $descLen
    $rows += [pscustomobject]@{
        Skill = $dir.Name
        Lines = ($text -split "`n").Count
        Tokens = Get-Estimate $text.Length
        DescChars = $descLen
    }
}

$rows | Sort-Object Tokens -Descending | Format-Table -AutoSize | Out-String | Write-Host

foreach ($r in $rows) {
    if ($r.Tokens -gt $MaxSkillTokens) {
        Write-Host ("FALLO  {0}: cuerpo {1} tokens > {2}" -f $r.Skill, $r.Tokens, $MaxSkillTokens) -ForegroundColor Red
        $fail++
    }
    if ($r.DescChars -gt $MaxDescriptionChars) {
        Write-Host ("FALLO  {0}: description {1} chars > {2}" -f $r.Skill, $r.DescChars, $MaxDescriptionChars) -ForegroundColor Red
        $fail++
    }
}

$catalogTok = Get-Estimate $totalBodyChars
$descTok = Get-Estimate $descChars
$worstRow = $rows | Sort-Object Tokens -Descending | Select-Object -First 1

Write-Host ""
Write-Host ("Descripciones: {0} chars (~{1} tokens en cada request)" -f $descChars, $descTok)
Write-Host ("Peor caso por request: ~{0} tokens ({1} + su description)" -f ($worstRow.Tokens + (Get-Estimate $worstRow.DescChars)), $worstRow.Skill)
Write-Host ("Catalogo en disco: ~{0} tokens (suma de cuerpos)" -f $catalogTok)

if ($catalogTok -gt $MaxCatalogTokens) {
    Write-Host ("FALLO  catalogo: ~{0} tokens > {1}" -f $catalogTok, $MaxCatalogTokens) -ForegroundColor Red
    $fail++
}

if ($fail -gt 0) {
    Write-Host ("RESULTADO: FALLO ({0} exceso(s))" -f $fail) -ForegroundColor Red
    exit 1
}

Write-Host "RESULTADO: OK (dentro del presupuesto)" -ForegroundColor Green
exit 0
