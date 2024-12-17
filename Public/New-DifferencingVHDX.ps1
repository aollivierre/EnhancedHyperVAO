function New-DifferencingVHDX {
    param(
        [string]$ParentPath,
        [string]$ChildPath
    )
    
    Write-EnhancedLog -Message "Creating differencing VHDX at $ChildPath" -Level "INFO"
    try {
        New-VHD -Path $ChildPath -ParentPath $ParentPath -Differencing
        Write-EnhancedLog -Message "Differencing VHDX created successfully" -Level "INFO"
        return $true
    }
    catch {
        Write-EnhancedLog -Message "Failed to create differencing VHDX: $_" -Level "ERROR"
        return $false
    }
}