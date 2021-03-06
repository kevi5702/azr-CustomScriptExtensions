﻿[cmdletbinding()]
param(
  [string[]]$ServiceName,
  [string[]]$ProcessName,
  [string]$vmid
)
$Message = @()

if ($ServiceName) {
  ForEach ( $Service in $ServiceName.split(',').trim() ) {
    Try {
      $Svc = Get-Service -Name $Service -ErrorAction Stop
      #Format OMS Report Object
      $Message += New-Object PSObject -Property ([ordered]@{
          Computer     = $env:COMPUTERNAME
          SvcDisplay   = $Svc.DisplayName
          SvcName      = $Svc.Name
          SvcState     = ($Svc.Status).tostring()
          SvcStartType = ($Svc.StartType).tostring()
          ResourceId   = $vmid
        })
    }
    Catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
      Write-Error -Exception $_.Exception -Message "$($_.TargetObject) Service Not Found"
      #Format OMS Report Object
      $Message += New-Object PSObject ([ordered]@{
          Computer     = $env:COMPUTERNAME
          SvcDisplay   = $Service
          SvcName      = $Service 
          SvcState     = "Service Not Found"
          SvcStartType = "Service Not Found"
          ResourceId   = $vmid
        })
      Continue
    }
  }
  Remove-Variable -Name Svc -ErrorAction SilentlyContinue -Force | Out-Null
}
if ($ProcessName) {
  ForEach ( $Process in $ProcessName.split(',').trim() ) {
    Try {
      $Proc = @(Get-Process -Name $Process -ErrorAction Stop)[0]
      #Format OMS Report Object
      $Message += New-Object PSObject -Property ([ordered]@{
          Computer   = $env:COMPUTERNAME
          ProcName   = $Proc.Name
          ProcState  = Switch ( $Proc.Responding ){
            $true  { "Running"; break }
            $false { "Halted" ; break }
          }
          ResourceId = $vmid
        })
    }
    Catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
      Write-Error -Exception $_.Exception -Message "$($_.TargetObject) Process Not Found"
      $Message += New-Object PSObject ([ordered]@{
          Computer   = $env:COMPUTERNAME
          ProcName   = $Process
          ProcState  = "Not Found"
          ResourceId = $vmid
        })
      Continue
    }
  }
  Remove-Variable -Name Proc -ErrorAction SilentlyContinue -Force | Out-Null
}
# Convert the $Message Object to JSON for better parsing when received by the Invoke-AzureRMVMRunCommand
$MessageJSONString = [string]($Message | ConvertTo-JSON) 
Write-Output -InputObject $MessageJSONString
Remove-Variable -Name MessageJSONString, Message, vmid, ProcessName, ServiceName -Force -ErrorAction SilentlyContinue | Out-Null