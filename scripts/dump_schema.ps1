# scripts\dump_schema.ps1
# Save in: C:\Users\jying\franchise_platform\scripts\dump_schema.ps1

$root      = Get-Location
$outputDir = Join-Path $root "scripts"
$outputFile = Join-Path $outputDir "project_schema.txt"

# Ensure output folder
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$folders = @(
    "web-app\lib",
    ".\packages\shared_core\lib",
    "mobile_app\lib"
)

# Clear file
"" | Out-File -FilePath $outputFile -Encoding UTF8

function Write-TreeNode {
    param(
        [string]$Path,
        [string]$Prefix = "",
        [bool]  $IsRoot = $false
    )

    $items = Get-ChildItem -Path $Path -Force |
             Sort-Object @{Expression = {$_.PSIsContainer}; Descending = $true}, Name

    $count = $items.Count
    for ($i = 0; $i -lt $count; $i++) {
        $item     = $items[$i]
        $isLast   = ($i -eq $count - 1)

        # Build connector
        $connector = if ($IsRoot) { "" } else {
            if ($isLast) { "`--- " } else { "|-- " }
        }

        # Build line
        $line = "$Prefix$connector$(if ($item.PSIsContainer) {'+-- '} else {'|-- '})$($item.Name)"
        $line | Out-File -FilePath $outputFile -Append -Encoding UTF8

        # Recurse into folders
        if ($item.PSIsContainer) {
            $childPrefix = $Prefix + $(if ($isLast) { "    " } else { "|   " })
            Write-TreeNode -Path $item.FullName -Prefix $childPrefix
        }
    }
}

foreach ($folder in $folders) {
    $fullPath = Join-Path $root $folder
    if (Test-Path $fullPath) {
        "`n=== $folder ===" | Out-File -FilePath $outputFile -Append -Encoding UTF8
        Write-TreeNode -Path $fullPath -IsRoot $true
    } else {
        "WARNING: Path not found: $fullPath" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    }
}

"Schema generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" |
    Out-File -FilePath $outputFile -Append -Encoding UTF8

"Output saved to: $outputFile" |
    Out-File -FilePath $outputFile -Append -Encoding UTF8

Write-Host "Schema generated: $outputFile" -ForegroundColor Green