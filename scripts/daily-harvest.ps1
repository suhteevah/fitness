# PerformanceTracker daily harvest - Windows Task Scheduler entry point.
# Runs nightly at 22:53 local. Pipes the harvest prompt into Claude Code CLI
# in non-interactive mode (--print) and logs the run.
#
# Re-registration: schtasks /Create /SC DAILY /TN "PT-Daily-Harvest" /TR "powershell -ExecutionPolicy Bypass -File J:\fitness\scripts\daily-harvest.ps1" /ST 22:53 /F

$ErrorActionPreference = "Continue"
$logDir = "J:\fitness\data\harvest-logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$stamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$logFile = "$logDir\harvest-$stamp.log"

"=== PerformanceTracker daily harvest started $(Get-Date -Format o) ===" | Tee-Object -FilePath $logFile

$promptFile = "J:\fitness\scripts\daily-harvest-prompt.txt"
if (-not (Test-Path $promptFile)) {
    "ERROR: prompt file missing at $promptFile" | Tee-Object -FilePath $logFile -Append
    exit 1
}

$prompt = Get-Content -Raw -Path $promptFile

# Pipe into Claude Code CLI. --print runs non-interactive, exits when Claude finishes.
# --dangerously-skip-permissions because this is unattended; the prompt only writes
# inside J:\fitness\data\ and posts a Telegram message.
$claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $claude) {
    "ERROR: claude CLI not on PATH - install Claude Code or add to PATH" | Tee-Object -FilePath $logFile -Append
    exit 1
}

"Using claude at: $claude" | Tee-Object -FilePath $logFile -Append

try {
    $prompt | & $claude --print --dangerously-skip-permissions 2>&1 | Tee-Object -FilePath $logFile -Append
    $code = $LASTEXITCODE
    "=== Exit code: $code ===" | Tee-Object -FilePath $logFile -Append
    exit $code
} catch {
    "ERROR: $_" | Tee-Object -FilePath $logFile -Append
    exit 1
}
