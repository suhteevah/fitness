# PerformanceTracker data-repo puller.
#
# Pulls suhteevah/performancetracker-data and syncs the latest JSONs into
# J:\fitness\data\. Idempotent — runs every 15 min via Task Scheduler.
#
# First-time setup:
#   git clone https://github.com/suhteevah/performancetracker-data.git J:\fitness\data-repo
#
# Re-register the scheduled task (replaces PT-Daily-Harvest):
#   schtasks /Delete /TN "PT-Daily-Harvest" /F
#   schtasks /Create /SC MINUTE /MO 15 /TN "PT-Data-Pull" /TR "powershell -ExecutionPolicy Bypass -File J:\fitness\scripts\pull-data-repo.ps1" /F

$ErrorActionPreference = "Continue"
$repoDir = "J:\fitness\data-repo"
$dataDir = "J:\fitness\data"
$logDir  = "$dataDir\harvest-logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$stamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$logFile = "$logDir\pull-$stamp.log"

"=== data-repo pull started $(Get-Date -Format o) ===" | Tee-Object -FilePath $logFile

if (-not (Test-Path "$repoDir\.git")) {
    "ERROR: repo not cloned at $repoDir. Run first-time setup:" | Tee-Object -FilePath $logFile -Append
    "  git clone https://github.com/suhteevah/performancetracker-data.git $repoDir" | Tee-Object -FilePath $logFile -Append
    exit 1
}

Push-Location $repoDir
try {
    git fetch --quiet origin main 2>&1 | Tee-Object -FilePath $logFile -Append
    git reset --hard origin/main 2>&1 | Tee-Object -FilePath $logFile -Append
} finally {
    Pop-Location
}

# Sync health-daily and project-status into the app-readable location.
foreach ($sub in @("health-daily", "project-status")) {
    $src = "$repoDir\$sub"
    $dst = "$dataDir\$sub"
    if (Test-Path $src) {
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        Copy-Item "$src\*.json" $dst -Force -ErrorAction SilentlyContinue
        $count = (Get-ChildItem "$dst\*.json" -ErrorAction SilentlyContinue).Count
        "Synced ${sub}: $count files in $dst" | Tee-Object -FilePath $logFile -Append
    }
}

"=== done $(Get-Date -Format o) ===" | Tee-Object -FilePath $logFile -Append
