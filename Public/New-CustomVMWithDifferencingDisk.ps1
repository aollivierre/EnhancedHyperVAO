function New-CustomVMWithDifferencingDisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VMName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VMFullPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$VHDPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SwitchName,

        [Parameter(Mandatory = $true)]
        [ValidateRange(512MB, 1024GB)]
        [int64]$MemoryStartupBytes,

        [Parameter(Mandatory = $true)]
        [ValidateRange(512MB, 1024GB)]
        [int64]$MemoryMinimumBytes,

        [Parameter(Mandatory = $true)]
        [ValidateRange(512MB, 1024GB)]
        [int64]$MemoryMaximumBytes,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 2)]
        [int]$Generation,

        [Parameter()]
        [string]$ParentVHDPath,

        [Parameter()]
        [bool]$UseDifferencing = $false,

        [Parameter()]
        [int64]$NewVHDSizeBytes = 100GB
    )

    Begin {
        Write-EnhancedLog -Message "Starting New-CustomVMWithDifferencingDisk function" -Level "INFO"
        Log-Params -Params $PSBoundParameters
    }

    Process {
        try {
            # Check if VM already exists
            if (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
                throw "A VM with name '$VMName' already exists"
            }

            # Prepare VM parameters
            $newVMParams = @{
                Generation = $Generation
                Path = $VMFullPath
                Name = $VMName
                MemoryStartupBytes = $MemoryStartupBytes
                SwitchName = $SwitchName
            }

            if ($UseDifferencing) {
                $newVMParams['NoVHD'] = $true
            }
            else {
                $newVMParams['NewVHDPath'] = $VHDPath
                $newVMParams['NewVHDSizeBytes'] = $NewVHDSizeBytes
            }

            # Create the VM
            Write-EnhancedLog -Message "Creating new VM '$VMName'" -Level "INFO"
            $vm = New-VM @newVMParams
            
            # Configure VM Memory
            $memoryParams = @{
                VMName = $VMName
                DynamicMemoryEnabled = $true
                MinimumBytes = $MemoryMinimumBytes
                MaximumBytes = $MemoryMaximumBytes
                StartupBytes = $MemoryStartupBytes
            }
            
            Write-EnhancedLog -Message "Configuring VM memory settings" -Level "INFO"
            Set-VMMemory @memoryParams

            if ($UseDifferencing) {
                Write-EnhancedLog -Message "Creating differencing disk" -Level "INFO"
                $vhdParams = @{
                    Path = $VHDPath
                    ParentPath = $ParentVHDPath
                    Differencing = $true
                }
                New-VHD @vhdParams
                
                Write-EnhancedLog -Message "Attaching differencing disk to VM" -Level "INFO"
                Add-VMHardDiskDrive -VMName $VMName -Path $VHDPath
            }

            # Verify VM Configuration
            $vmCheck = Get-VM -Name $VMName -ErrorAction Stop
            if ($vmCheck.State -eq 'Off') {
                Write-EnhancedLog -Message "VM '$VMName' created successfully" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
                return $true
            }
            else {
                throw "VM is in unexpected state: $($vmCheck.State)"
            }
        }
        catch {
            Write-EnhancedLog -Message "Failed to create VM: $($_.Exception.Message)" -Level "ERROR"
            
            # Cleanup on failure
            try {
                if (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
                    Write-EnhancedLog -Message "Cleaning up failed VM" -Level "WARNING"
                    Remove-VM -Name $VMName -Force -ErrorAction Stop
                }
                
                if (Test-Path $VHDPath) {
                    Write-EnhancedLog -Message "Cleaning up VHD" -Level "WARNING"
                    Remove-Item -Path $VHDPath -Force -ErrorAction Stop
                }
            }
            catch {
                Write-EnhancedLog -Message "Cleanup after failure encountered additional errors: $($_.Exception.Message)" -Level "ERROR"
            }
            
            Handle-Error -ErrorRecord $_
            return $false
        }
    }

    End {
        Write-EnhancedLog -Message "Completed New-CustomVMWithDifferencingDisk function" -Level "INFO"
    }
}