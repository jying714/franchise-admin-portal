# scripts\get-lib-raw-urls.ps1
# Run:  .\scripts\get-lib-raw-urls.ps1

# ---- Get repo info -------------------------------------------------
$remoteUrl = git remote get-url origin
if (-not $remoteUrl) {
    Write-Error "No git remote 'origin' found. Are you in a git repo?"
    exit 1
}

$repo   = $remoteUrl -replace '\.git$', '' -replace '^git@github\.com:', 'https://github.com/'
$branch = git rev-parse --abbrev-ref HEAD
if (-not $branch -or $branch -eq 'HEAD') {
    Write-Warning "Could not detect branch - using 'main' as fallback."
    $branch = 'main'
}

# ---- Repo root -----------------------------------------------------
$rootPath = (git rev-parse --show-toplevel).Trim()

# ---- Folders to scan ------------------------------------------------
$folders = @(
    Join-Path $rootPath "mobile_app\lib"
    Join-Path $rootPath "web-app\lib"
    Join-Path $rootPath ".\packages\shared_core\lib"
)

# ---- Verify folders exist -------------------------------------------
$missing = $folders | Where-Object { -not (Test-Path $_) }
if ($missing) {
    Write-Error "Missing lib folder(s):`n$($missing -join "`n")"
    exit 1
}

# ---- Build URLs -----------------------------------------------------
$urls = foreach ($folder in $folders) {
    Get-ChildItem -Path $folder -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($rootPath.Length + 1) -replace '\\', '/'
        "https://raw.githubusercontent.com/$($repo.Substring(19))/$branch/$rel"
    }
}

# ---- Save to scripts/lib-raw-urls.txt -------------------------------
$outputDir  = Join-Path $rootPath "scripts"
$outputFile = Join-Path $outputDir "lib-raw-urls.txt"

# Create scripts folder if missing
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$urls | Sort-Object | Set-Content -Path $outputFile -Encoding UTF8

# ---- Success message ------------------------------------------------
Write-Host "Success! $($urls.Count) raw URLs saved to:" -ForegroundColor Green
Write-Host "   $outputFile" -ForegroundColor Cyan
Write-Host "`nFirst 5 URLs:" -ForegroundColor Yellow
$urls | Select-Object -First 5 | ForEach-Object { Write-Host "   $_" }