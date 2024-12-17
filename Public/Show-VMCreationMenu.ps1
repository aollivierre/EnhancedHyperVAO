function Show-VMCreationMenu {
    Write-Host "`n=== VM Creation Options ===" -ForegroundColor Cyan
    Write-Host "1. Create VM with new VHDX disk"
    Write-Host "2. Create VM with differencing VHDX disk"
    Write-Host "`nPlease select an option (1 or 2):" -NoNewline
    
    $choice = Read-Host
    while ($choice -notin '1', '2') {
        Write-Host "Invalid selection. Please enter 1 or 2:" -ForegroundColor Yellow -NoNewline
        $choice = Read-Host
    }
    
    return $choice
}