$ErrorActionPreference = "SilentlyContinue"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$out = "$env:USERPROFILE\Desktop\hardware-check-$stamp.txt"

function Add-Section {
  param(
    [string]$Title,
    [scriptblock]$Block
  )

  "`r`n==================== $Title ====================`r`n" | Tee-Object -FilePath $out -Append
  try {
    & $Block | Out-String -Width 240 | Tee-Object -FilePath $out -Append
  } catch {
    "ERROR: $($_.Exception.Message)" | Tee-Object -FilePath $out -Append
  }
}

"Hardware check created: $(Get-Date)" | Tee-Object -FilePath $out

Add-Section "COMPUTER / MODEL" {
  Get-CimInstance Win32_ComputerSystem |
    Select-Object Manufacturer, Model, SystemType,
      @{Name="RAM_GB";Expression={[math]::Round($_.TotalPhysicalMemory / 1GB, 2)}}
}

Add-Section "OS" {
  Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, BuildNumber, OSArchitecture, LastBootUpTime
}

Add-Section "CPU" {
  Get-CimInstance Win32_Processor |
    Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
}

Add-Section "RAM MODULES" {
  Get-CimInstance Win32_PhysicalMemory |
    Select-Object BankLabel, Manufacturer, PartNumber,
      @{Name="Capacity_GB";Expression={[math]::Round($_.Capacity / 1GB, 2)}},
      Speed, ConfiguredClockSpeed
}

Add-Section "GPU / DISPLAY ADAPTERS" {
  Get-CimInstance Win32_VideoController |
    Select-Object Name, DriverVersion, Status,
      @{Name="AdapterRAM_GB";Expression={
        if ($_.AdapterRAM) {[math]::Round($_.AdapterRAM / 1GB, 2)} else {"unknown"}
      }}
}

Add-Section "DISKS" {
  Get-CimInstance Win32_DiskDrive |
    Select-Object Model, MediaType, InterfaceType,
      @{Name="Size_GB";Expression={[math]::Round($_.Size / 1GB, 2)}}
}

Add-Section "VIRTUALIZATION" {
  Get-CimInstance Win32_ComputerSystem |
    Select-Object HypervisorPresent
}

Add-Section "WSL" {
  wsl --status
  wsl -l -v
}

Add-Section "NVIDIA CHECK" {
  $paths = @(
    "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe",
    "$env:WinDir\System32\nvidia-smi.exe"
  )

  $nvsmi = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1

  if (-not $nvsmi) {
    $nvsmi = Get-ChildItem "C:\Windows\System32\DriverStore\FileRepository" -Filter nvidia-smi.exe -Recurse |
      Select-Object -First 1 -ExpandProperty FullName
  }

  if ($nvsmi) {
    "nvidia-smi found at: $nvsmi"
    & $nvsmi
  } else {
    "nvidia-smi not found"
  }
}

Add-Section "DOCKER VERSION" {
  docker version
}

Add-Section "DOCKER INFO SUMMARY" {
  docker info
}

Add-Section "DOCKER CONTEXTS" {
  docker context ls
}

Add-Section "DOCKER MODEL RUNNER" {
  docker model version
  docker model status
  docker model ls
}

Add-Section "MODEL RUNNER API" {
  try {
    Invoke-RestMethod "http://localhost:12434/v1/models" | ConvertTo-Json -Depth 20
  } catch {
    try {
      Invoke-RestMethod "http://localhost:12434/engines/v1/models" | ConvertTo-Json -Depth 20
    } catch {
      "Model Runner API not reachable on localhost:12434"
    }
  }
}

Write-Host ""
Write-Host "Saved hardware report to:"
Write-Host $out
Write-Host ""
notepad $out
