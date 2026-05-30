# scripts\dump_schema.ps1
# Run from: C:\Users\jying\franchise_platform\scripts\
# Output:   project_schema.txt (in project root)

$root = Split-Path -Parent $PSScriptRoot

$outputFile = Join-Path $root "project_schema.txt"

# Clear previous output
"" | Out-File -FilePath $outputFile -Encoding UTF8 -Force

$foldersToScan = @(
    "mobile_app",
    "web-app",
    "packages/shared_core"
)

$skipFolders = @(
    ".dart_tool", "build", "android", "ios", "web", "linux", "macos", "windows",
    "node_modules", ".git", ".github", "coverage", "test", "__pycache__",
    ".vscode", ".idea", "artifacts"
)

function Write-Tree {
    param(
        [string]$Path,
        [string]$Prefix = "",
        [bool]$IsLast = $false
    )

    $items = Get-ChildItem -Path $Path -Force | 
             Where-Object { $_.Name -notin $skipFolders } |
             Sort-Object @{Expression={$_.PSIsContainer}; Descending=$true}, Name

    $count = $items.Count
    for ($i = 0; $i -lt $count; $i++) {
        $item = $items[$i]
        $isLastItem = ($i -eq $count - 1)

        $connector = if ($IsLast) { "    " } else { "|   " }
        $line = "$Prefix" + $(if ($isLastItem) {"-- "} else {"|-- "}) + $item.Name

        $line | Out-File -FilePath $outputFile -Append -Encoding UTF8

        if ($item.PSIsContainer) {
            $newPrefix = $Prefix + $(if ($isLastItem) {"    "} else {"|   "})
            Write-Tree -Path $item.FullName -Prefix $newPrefix -IsLast $isLastItem
        }
        elseif ($item.Extension -match '^\.(ya?ml|dart|js|ts|html|css|json|md|ps1)$') {
            $relPath = $item.FullName.Replace($root, "").TrimStart("\")
            "      -- $relPath" | Out-File -FilePath $outputFile -Append -Encoding UTF8
        }
    }
}

# Header
"=================================================================================" | Out-File -FilePath $outputFile -Append -Encoding UTF8
"DOUGHBOYS PIZZERIA - PROJECT SCHEMA DUMP" | Out-File -FilePath $outputFile -Append -Encoding UTF8
"Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $outputFile -Append -Encoding UTF8
"=================================================================================" | Out-File -FilePath $outputFile -Append -Encoding UTF8
"" | Out-File -FilePath $outputFile -Append -Encoding UTF8

foreach ($folder in $foldersToScan) {
    $fullPath = Join-Path $root $folder
    if (Test-Path $fullPath) {
        "`n=== $folder ===" | Out-File -FilePath $outputFile -Append -Encoding UTF8
        Write-Tree -Path $fullPath -IsLast $true
    } else {
        "`nWARNING: Folder not found -> $folder" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    }
}

"`nSchema dump completed successfully." | Out-File -FilePath $outputFile -Append -Encoding UTF8

Write-Host "✅ Project schema generated successfully!" -ForegroundColor Green
Write-Host "   Saved to: $outputFile" -ForegroundColor Cyan