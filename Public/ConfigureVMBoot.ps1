function ConfigureVMBoot {
    <#
    .SYNOPSIS
    Configures the boot order of the specified VM. Can configure boot from either DVD drive or differencing disk.

    .DESCRIPTION
    Configures the boot settings for a VM. If DifferencingDiskPath is provided, sets the VM to boot from that disk.
    Otherwise, configures the VM to boot from DVD drive.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VMName,

        [Parameter(Mandatory = $false)]
        [string]$DifferencingDiskPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Configure-VMBoot function" -Level "INFO"
        $logParams = @{
            VMName = $VMName
        }
        if ($DifferencingDiskPath) {
            $logParams['DifferencingDiskPath'] = $DifferencingDiskPath
        }
        Log-Params -Params $logParams
    }

    Process {
        try {
            if ($DifferencingDiskPath) {
                # Differencing disk boot configuration
                Write-EnhancedLog -Message "Retrieving hard disk drive for VM: $VMName with path: $DifferencingDiskPath" -Level "INFO"
                $VHD = Get-VMHardDiskDrive -VMName $VMName | Where-Object { $_.Path -eq $DifferencingDiskPath }

                if ($null -eq $VHD) {
                    Write-EnhancedLog -Message "No hard disk drive found for VM: $VMName with the specified path: $DifferencingDiskPath" -Level "ERROR"
                    throw "Hard disk drive not found."
                }

                Write-EnhancedLog -Message "Setting VM firmware for VM: $VMName to boot from the specified disk" -Level "INFO"
                Set-VMFirmware -VMName $VMName -FirstBootDevice $VHD
            }
            else {
                # DVD drive boot configuration
                Write-EnhancedLog -Message "Retrieving DVD drive for VM: $VMName" -Level "INFO"
                $DVDDrive = Get-VMDvdDrive -VMName $VMName

                if ($null -eq $DVDDrive) {
                    Write-EnhancedLog -Message "No DVD drive found for VM: $VMName" -Level "ERROR"
                    throw "DVD drive not found."
                }

                Write-EnhancedLog -Message "Setting VM firmware for VM: $VMName to boot from DVD" -Level "INFO"
                Set-VMFirmware -VMName $VMName -FirstBootDevice $DVDDrive
            }

            Write-EnhancedLog -Message "VM boot configured for $VMName" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while configuring VM boot for $VMName $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Configure-VMBoot function" -Level "INFO"
    }
}