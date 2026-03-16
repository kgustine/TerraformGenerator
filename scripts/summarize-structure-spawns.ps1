param(
    [string]$CsvPath = "plugins/TerraformGenerator/structure-spawns.csv",
    [string]$World = "",
    [double]$Radius = -1,
    [int]$CenterX = 0,
    [int]$CenterZ = 0
)

if (-not (Test-Path -Path $CsvPath)) {
    Write-Host "Structure log not found: $CsvPath"
    Write-Host "Run pre-generation first, then re-run this script."
    exit 1
}

$rows = Import-Csv -Path $CsvPath

# Backward compatibility for old logs that didn't include block_y or structure_type.
$smallStructures = @(
    "SmallDungeonPopulator",
    "ShipwreckPopulator",
    "BuriedTreasurePopulator",
    "RuinedPortalPopulator",
    "IglooPopulator",
    "DesertWellPopulator",
    "WitchHutPopulator"
)

$rows = $rows | ForEach-Object {
    if (-not $_.PSObject.Properties['block_y']) {
        $_ | Add-Member -NotePropertyName block_y -NotePropertyValue 0
    }
    if (-not $_.PSObject.Properties['structure_type']) {
        $type = if ($smallStructures -contains $_.structure) { "small" } else { "large" }
        $_ | Add-Member -NotePropertyName structure_type -NotePropertyValue $type
    }
    elseif ([string]::IsNullOrWhiteSpace([string]$_.structure_type)) {
        $_.structure_type = if ($smallStructures -contains $_.structure) { "small" } else { "large" }
    }
    $_
}

if ($World -ne "") {
    $rows = $rows | Where-Object { $_.world -eq $World }
}

if ($Radius -ge 0) {
    $radiusSquared = $Radius * $Radius
    $rows = $rows | Where-Object {
        $dx = ([double]$_.block_x) - $CenterX
        $dz = ([double]$_.block_z) - $CenterZ
        (($dx * $dx) + ($dz * $dz)) -le $radiusSquared
    }
}

if (-not $rows -or $rows.Count -eq 0) {
    Write-Host "No rows matched your filters."
    exit 0
}

Write-Host ""
Write-Host "Total logged structures: $($rows.Count)"
if ($World -ne "") {
    Write-Host "World filter: $World"
}
if ($Radius -ge 0) {
    Write-Host "Radius filter: $Radius blocks around ($CenterX, $CenterZ) [XZ only]"
}
Write-Host ""

$grouped = $rows |
    Group-Object structure, structure_type |
    Sort-Object Count -Descending |
    Select-Object @{Name="Structure";Expression={$_.Group[0].structure}},
                  @{Name="Type";Expression={$_.Group[0].structure_type}},
                  @{Name="Count";Expression={$_.Count}}

$smallGrouped = $grouped | Where-Object { $_.Type -eq "small" }
$largeGrouped = $grouped | Where-Object { $_.Type -eq "large" }

Write-Host "Large structures"
if ($largeGrouped -and $largeGrouped.Count -gt 0) {
    $largeGrouped | Format-Table -AutoSize
}
else {
    Write-Host "(none)"
}

Write-Host ""
Write-Host "Small structures"
if ($smallGrouped -and $smallGrouped.Count -gt 0) {
    $smallGrouped | Format-Table -AutoSize
}
else {
    Write-Host "(none)"
}

$smallTotal = 0
$largeTotal = 0
foreach ($entry in $grouped) {
    if ($entry.Type -eq "small") {
        $smallTotal += [int]$entry.Count
    }
    else {
        $largeTotal += [int]$entry.Count
    }
}

Write-Host ""
Write-Host "Large structures total: $largeTotal"
Write-Host "Small structures total: $smallTotal"
Write-Host "Overall total: $($rows.Count)"
