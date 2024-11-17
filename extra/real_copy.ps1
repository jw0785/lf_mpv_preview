param([string]$inputFile)

Add-Type -AssemblyName System.Windows.Forms

try {
    $files = New-Object System.Collections.Specialized.StringCollection
    $files.Add($inputFile)

    [System.Windows.Forms.Clipboard]::SetFileDropList($files)
	exit 0
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
	exit 1
}

exit 0