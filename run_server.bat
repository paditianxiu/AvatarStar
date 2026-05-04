@echo off
setlocal

set "ROOT=%~dp0"
set "DOTNET=C:\Program Files\dotnet\dotnet.exe"
set "AS_LOG_DIR=%ROOT%logs"

title AvatarStar Server

echo [AvatarStar] Project: %ROOT%
echo [AvatarStar] Logs: %AS_LOG_DIR%
echo [AvatarStar] Stopping existing server processes...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-CimInstance Win32_Process | Where-Object { $_.Name -in @('dotnet.exe','AvatarStar.Server.Game.exe','AvatarStar.Server.Login.exe') -and ($_.CommandLine -like '*AvatarStar.Server.Game*' -or $_.CommandLine -like '*AvatarStar.Server.Login*') } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
timeout /t 1 /nobreak > nul
echo [AvatarStar] Building server...
"%DOTNET%" build "%ROOT%src\AvatarStar.sln"
if errorlevel 1 (
    echo [AvatarStar] Build failed.
    pause
    exit /b 1
)

echo [AvatarStar] Starting Login and Game servers in this window.
echo [AvatarStar] Close this window to stop the attached server processes.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference='Stop';" ^
    "$dotnet = '%DOTNET%';" ^
    "$root = '%ROOT%';" ^
    "$env:AS_LOG_DIR = '%AS_LOG_DIR%';" ^
    "$loginArgs = @('run','--project', (Join-Path $root 'src\AvatarStar.Server.Login\AvatarStar.Server.Login.csproj'), '--no-build');" ^
    "$gameArgs = @('run','--project', (Join-Path $root 'src\AvatarStar.Server.Game\AvatarStar.Server.Game.csproj'), '--no-build');" ^
    "$procs = @();" ^
    "try {" ^
    "  $procs += Start-Process -FilePath $dotnet -ArgumentList $loginArgs -WorkingDirectory $root -NoNewWindow -PassThru;" ^
    "  $procs += Start-Process -FilePath $dotnet -ArgumentList $gameArgs -WorkingDirectory $root -NoNewWindow -PassThru;" ^
    "  Write-Host '[AvatarStar] Server processes started. Press Ctrl+C or close this window to stop them.';" ^
    "  while ($true) { Start-Sleep -Seconds 1; if (($procs | Where-Object { $_.HasExited }).Count -gt 0) { break } }" ^
    "} finally {" ^
    "  foreach ($p in $procs) { if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } }" ^
    "}"

endlocal
