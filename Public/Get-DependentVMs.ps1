function Get-DependentVMs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$VHDXPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Get-DependentVMs function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            Write-EnhancedLog -Message "Retrieving all VMs" -Level "INFO"
            $allVMs = Get-VM
            Write-EnhancedLog -Message "Total VMs found: $($allVMs.Count)" -Level "INFO"

            $dependentVMs = [System.Collections.Generic.List[PSObject]]::new()

            foreach ($vm in $allVMs) {
                $hardDrives = $vm.HardDrives
                foreach ($hd in $hardDrives) {
                    try {
                        # Check if the VHD file exists before trying to access it
                        if (Test-Path $hd.Path) {
                            # Attempt to get the parent path of the VHD
                            $parentPath = (Get-VHD -Path $hd.Path).ParentPath

                            if ($parentPath -eq $VHDXPath) {
                                $dependentVMs.Add($vm)
                                Write-EnhancedLog -Message "Dependent VM: $($vm.Name)" -Level "INFO"
                                break
                            }
                        } else {
                            # Log a warning if the VHDX file does not exist
                            Write-EnhancedLog -Message "Warning: VHDX file not found: $($hd.Path). Skipping VM: $($vm.Name)" -Level "WARNING"
                        }
                    } catch {
                        # Log a warning if there was an error accessing the VHDX file
                        Write-EnhancedLog -Message "Warning: An error occurred while accessing VHDX file: $($hd.Path). Skipping VM: $($vm.Name)" -Level "WARNING"
                    }
                }
            }

            Write-EnhancedLog -Message "Total dependent VMs using VHDX $VHDXPath $($dependentVMs.Count)" -Level "INFO"
            return $dependentVMs
        } catch {
            Write-EnhancedLog -Message "An error occurred while retrieving dependent VMs: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            return [System.Collections.Generic.List[PSObject]]::new()
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Get-DependentVMs function" -Level "INFO"
    }
}