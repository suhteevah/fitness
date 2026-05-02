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

# git is not on SYSTEM's PATH by default; ensure we can find it under either context.
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    foreach ($p in @('C:\Program Files\Git\cmd', 'C:\Program Files\Git\bin')) {
        if (Test-Path "$p\git.exe") { $env:PATH = "$p;$env:PATH"; break }
    }
}

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

# Fail-fast on any credential prompt — hidden scheduled runs cannot complete one.
$env:GCM_INTERACTIVE = 'Never'
$env:GIT_TERMINAL_PROMPT = '0'
$env:GIT_ASKPASS = 'echo'

# Inject PAT as a one-shot Authorization header so the token never lands in .git/config.
$patFile = 'J:\fitness\.gh-pat'
$authArgs = @()
if (Test-Path $patFile) {
    $tok = (Get-Content -Path $patFile -Raw -Encoding ascii).Trim()
    if ($tok) {
        $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("x-access-token:$tok"))
        $authArgs = @('-c', "http.https://github.com/.extraheader=Authorization: Basic $b64")
    }
}

Push-Location $repoDir
try {
    & git @authArgs fetch --quiet origin main 2>&1 | Tee-Object -FilePath $logFile -Append
    & git @authArgs reset --hard origin/main 2>&1 | Tee-Object -FilePath $logFile -Append
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
