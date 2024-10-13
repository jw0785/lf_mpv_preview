@echo off
REM Get supported formats from ffmpeg

set scriptDir=%~dp0

powershell -Command ^
    "$psScriptDir = '%scriptDir%';" ^
    "$output = ffmpeg -formats;" ^
    "if (-not $output) { Write-Host 'No output captured from FFmpeg'; exit; }" ^
    "$formats = @();" ^
    "$output -split '`r?`n' | ForEach-Object { " ^
        "$line = $_.Trim();" ^
        "if ($line -match '^\s*([D]+[E]*\s+)(\S+)\s+(.+)') { " ^
            "$format = @{};" ^
            "$format['Description'] = $matches[3].Trim();" ^
            "$format['Ext'] = $matches[2];" ^
            "$format['Support'] = $matches[1].Trim();" ^
            "$formats += $format;" ^
        "}" ^
    "};" ^
    "if ($formats.Count -eq 0) { Write-Host 'No formats parsed'; exit; }" ^
    "$formats | ConvertTo-Json | Set-Content (Join-Path $psScriptDir 'supported_formats.json');" ^
    "Write-Host 'Supported formats have been saved to supported_formats.json';" ^
    "Invoke-Item (Join-Path $psScriptDir 'supported_formats.json');"

pause
