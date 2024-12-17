# function Get-ConfigurationFile {
#     $configPath = "D:\VM\Configs" # Adjust this path as needed
#     $configs = Get-ChildItem -Path $configPath -Filter "*.psd1" -ErrorAction SilentlyContinue
    
#     if ($configs.Count -eq 0) {
#         Write-EnhancedLog -Message "No configuration files found in $configPath" -Level "ERROR"
#         return $null
#     }
    
#     Write-Host "`n=== Available VM Configurations ===" -ForegroundColor Cyan
#     for ($i = 0; $i -lt $configs.Count; $i++) {
#         Write-Host "$($i + 1). $($configs[$i].BaseName)"
#     }
    
#     Write-Host "`nPlease select a configuration (1-$($configs.Count)):" -NoNewline
#     $selection = Read-Host
#     while ([int]$selection -lt 1 -or [int]$selection -gt $configs.Count) {
#         Write-Host "Invalid selection. Please enter a number between 1 and $($configs.Count):" -ForegroundColor Yellow -NoNewline
#         $selection = Read-Host
#     }
    
#     return $configs[$selection - 1].FullName
# }






function Get-VMConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath = "D:\VM\Configs",

        [Parameter()]
        [ValidateSet('VSCode', 'Notepad', 'None')]
        [string]$Editor = 'VSCode'
    )

    Begin {
        Write-EnhancedLog -Message "Starting configuration file selection process" -Level "INFO"
        
        # Get all PSD1 files
        $getPSD1Params = @{
            Path = $ConfigPath
            Filter = "*.psd1"
            ErrorAction = 'SilentlyContinue'
        }
        
        $configFiles = Get-ChildItem @getPSD1Params
        
        if ($configFiles.Count -eq 0) {
            Write-EnhancedLog -Message "No configuration files found in $ConfigPath" -Level "ERROR"
            return $null
        }
    }

    Process {
        try {
            # Display available configurations
            Write-Host "`n=== Available VM Configurations ===" -ForegroundColor Cyan
            Write-Host "----------------------------------------" -ForegroundColor Cyan
            
            $configFiles | ForEach-Object -Begin { $index = 1 } -Process {
                Write-Host ("{0,3}. {1}" -f $index++, $_.BaseName)
            }
            Write-Host "----------------------------------------" -ForegroundColor Cyan

            # Get and validate user selection
            do {
                $selection = Read-Host "`nSelect a configuration (1-$($configFiles.Count))"
                $validSelection = $selection -match "^[1-$($configFiles.Count)]$"
                
                if (-not $validSelection) {
                    Write-Host "Invalid selection. Please enter a number between 1 and $($configFiles.Count)" -ForegroundColor Yellow
                }
            } while (-not $validSelection)

            # Load selected configuration
            $selectedConfig = $configFiles[$selection - 1]
            $configPath = $selectedConfig.FullName
            
            $importParams = @{
                Path = $configPath
                ErrorAction = 'Stop'
            }
            
            $config = Import-PowerShellDataFile @importParams

            # Display configuration details
            Write-Host "`nConfiguration Details:" -ForegroundColor Cyan
            Write-Host "----------------------------------------" -ForegroundColor Cyan
            $config.GetEnumerator() | Sort-Object Key | ForEach-Object {
                Write-Host ("{0,-20} = {1}" -f $_.Key, $_.Value)
            }
            Write-Host "----------------------------------------" -ForegroundColor Cyan

            # Confirm or edit configuration
            do {
                $proceed = Read-Host "`nProceed with this configuration? (Y)es, (E)dit, or (C)ancel"
                
                switch -Regex ($proceed) {
                    '^[Yy]$' {
                        Write-EnhancedLog -Message "Configuration selected: $($selectedConfig.Name)" -Level "INFO"
                        return $config
                    }
                    '^[Ee]$' {
                        Write-EnhancedLog -Message "Opening configuration for editing" -Level "INFO"
                        
                        switch ($Editor) {
                            'VSCode' { Start-Process code -ArgumentList $configPath -Wait }
                            'Notepad' { Start-Process notepad -ArgumentList $configPath -Wait }
                        }
                        
                        # Reload configuration after editing
                        $config = Import-PowerShellDataFile @importParams
                        
                        Write-Host "`nUpdated Configuration:" -ForegroundColor Cyan
                        $config.GetEnumerator() | Sort-Object Key | ForEach-Object {
                            Write-Host ("{0,-20} = {1}" -f $_.Key, $_.Value)
                        }
                    }
                    '^[Cc]$' {
                        Write-EnhancedLog -Message "Configuration selection cancelled" -Level "INFO"
                        return $null
                    }
                    default {
                        Write-Host "Invalid input. Please enter Y, E, or C" -ForegroundColor Yellow
                    }
                }
            } while ($proceed -notmatch '^[Yy]$|^[Cc]$')
        }
        catch {
            Write-EnhancedLog -Message "Error processing configuration: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            return $null
        }
    }

    End {
        Write-EnhancedLog -Message "Configuration selection process completed" -Level "INFO"
    }
}