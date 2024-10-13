# Extract the directory of the current script
$scriptFullPath = $MyInvocation.MyCommand.Definition
$psScriptDir = Split-Path -Parent $scriptFullPath
Write-Output "Script Directory: $psScriptDir"

function Get-MimeType {
    <#
    Determines the MIME type based on the file extension.
    Args:
      FilePath (string): The full path to the file.
    Returns:
      string: The MIME type as a string, or 'none' if not recognized.
    #>
    param(
        [string]$FilePath
    )
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    switch ($extension) {
        '.txt' { return 'text/plain' }
        '.jpg' { return 'image/jpeg' }
        '.avif' { return 'image/avif' }
        '.webp' { return 'image/webp' }
        '.tif' { return 'image/tiff' }
        '.tiff' { return 'image/tiff' }
        '.jpeg' { return 'image/jpeg' }
        '.png' { return 'image/png' }
        '.gif' { return 'image/gif' }
        '.pdf' { return 'application/pdf' }
        '.mp4' { return 'video/mp4' }
        '.mkv' { return 'video/x-matroska' }
        Default { return 'none' }
    }
}

function Show-Text {
    <#
    Displays the content of a text file in the console.
    Args:
      FilePath (string): The full path to the file.
    #>
    param(
        [string]$FilePath
    )
    $content = Get-Content -Path $FilePath
    Write-Output $content
}

function Write-Divider {
    <#
    Writes a divider line in the console.
    #>
    Write-Output ('-' * 20)
}

function Show-ImageOrVideo {
    <#
    Displays an image or video using mpv with a named pipe for communication.
    Args:
      FilePath (string): The full path to the file.
	  Width (int)
	  
	Returns:
      None
    #>
    param(
        [string]$FilePath,
        [int]$Width = 1440
    )
    $mpvSocket = "\\.\pipe\mpv-socket"
    if (-not (Test-Path $mpvSocket)) {
        Write-Output "Starting MPV with socket server..."
        $quotedFilePath = "`"$FilePath`"" #so it will be passed as a single argument to mpv
        $base_arguments = @("--input-ipc-server=\\.\pipe\mpv-socket", 
               "--no-terminal", 
               "--quiet", 
               "--script-opts=autoload-disabled=yes", 
               "--no-input-default-bindings", 
               "--image-display-duration=inf", 
               "--geometry=$Width",
               "--load-scripts=no",
               "--osd-level=1",
               "--osc=no",
               $quotedFilePath)
        $luaScriptPath = Join-Path $psScriptDir "lua\sleep_timer.lua"
        #Write-Output "Lua Script Path: $luaScriptPath"
        $quotedLuaScriptPath = "`"$luaScriptPath`"" #so it will be passed as a single argument to mpv
        if (Test-Path $luaScriptPath <#so it won't be treated as a literal quote#>) {
                $base_arguments += "--script=$quotedLuaScriptPath"
            } else {
                Write-Warning "Lua script not found, continuing without sleep timer"
            }
        Start-Process -FilePath "mpv" -ArgumentList $base_arguments -WindowStyle Hidden
        Start-Sleep -Milliseconds 10
        $retryCount = 0
        $maxRetries = 10
        while (-not (Test-Path $mpvSocket) -and $retryCount -lt $maxRetries) {
            Start-Sleep -Milliseconds 10
            $retryCount++
        }
        if (-not (Test-Path $mpvSocket)) {
            Write-Output "Failed to start MPV or socket not created after retries."
            return
        }
    }
    $json = '{"command": ["loadfile", "' + ($FilePath -replace '\\', '\\\\') + '", "replace"]}'
    try {
        $pipeStream = New-Object System.IO.Pipes.NamedPipeClientStream(".", "mpv-socket", [System.IO.Pipes.PipeDirection]::InOut)
        $pipeStream.Connect(50)
        if ($pipeStream.IsConnected) {
            $streamWriter = New-Object System.IO.StreamWriter($pipeStream)
            $streamWriter.AutoFlush = $true
            $streamWriter.WriteLine($json)
            Write-Output "Successfully wrote to mpv socket."
            $streamWriter.Dispose()
        } else {
            Write-Output "Failed to connect to mpv socket."
        }
        $pipeStream.Dispose()
    } catch {
        Write-Output "Failed to write to mpv socket: $($_.Exception.Message)"
    }
}

function Format-FileSize {
    <#
    Formats the size of a file from bytes to a human-readable format.
    Args:
      size_in_bytes (int64): The file size in bytes.
    Returns:
      string: The formatted file size.
    #>
    param(
        [int64]$size_in_bytes
    )
    if ($size_in_bytes -lt 1KB) {
        return "${size_in_bytes} B"
    }
    elseif ($size_in_bytes -lt 1MB) {
        return "{0:F2} KB" -f ($size_in_bytes / 1KB)
    }
    elseif ($size_in_bytes -lt 1GB) {
        return "{0:F2} MB" -f ($size_in_bytes / 1MB)
    }
    else {
        return "{0:F2} GB" -f ($size_in_bytes / 1GB)
    }
}

function Format-Text {
    <#
    Formats a given text to fit within a specified width, breaking lines as necessary.
    Args:
      text (string): The text to be formatted.
      width (int): The maximum line width in characters.
    #>
    param(
        [string]$text,
        [int]$width = 80
    )
    $words = $text -split "\s+"
    $col = 0
    foreach ($word in $words) {
        $col += $word.Length + 1
        if ($col -gt $width) {
            Write-Host ""
            $col = $word.Length + 1
        }
        Write-Host -NoNewline "$word "
    }
    Write-Host ""
}
# Main previewer logic
$file_path = $args[1]
$previewer_width = $args[2]
$previewer_height = $args[3]
$mimeType = Get-MimeType $file_path
if (-not $mimeType) {
    $mimeType = 'none'
}

try {
    $fileInfo = Get-Item -LiteralPath $file_path
    $size = $fileInfo.Length
    Write-Output $(Format-Text "File Name: $($fileInfo.Name)" $previewer_width)
    Write-Output "File Size: $(Format-FileSize $size)"
    Write-Output "Modify Time: $($fileInfo.LastWriteTime)"

    if ($mimeType -eq 'none') {
        if ($size -lt 100KB) {
            Write-Divider
            Show-Text $file_path
        }
    }
    elseif ($mimeType -eq 'text/plain') {
        Write-Divider
        Show-Text $file_path
    }
    elseif ($mimeType -match 'image/' -or $mimeType -match 'video/') {
        Write-Divider
        Show-ImageOrVideo $file_path
    }
    elseif ($mimeType -eq 'application/pdf') {
        Write-Divider
		#TODO implement PDF preview
        Write-Output "PDF preview is not implemented yet."
    }
}
catch {
    Write-Output $_.Exception.Message
}