<#
.SYNOPSIS
    Connect to a VM via PowerShell remoting inside of Windows Terminal.

.DESCRIPTION
    Establishes a PowerShell remote session to a VM in the specified domain.
    By default, uses stored credentials and opens in a new Windows Terminal tab.
    Can optionally prompt for credentials and connect in the current session.

.PARAMETER ComputerName
    The name of the computer to connect to (without domain).

.PARAMETER Cred
    OPTIONAL: The credential set to use for the connection. Valid values are "1" or "2". Defaults to "1". This is only used when not using -PromptCredential.
    
.PARAMETER Domain
    OPTIONAL: When specified it uses the domain from the prompt instead of the stored one.

.PARAMETER PromptCredential
    OPTIONAL: When specified, prompts for credentials instead of using stored ones. Connects in the current session instead of opening a new tab.

.EXAMPLE
    psh vm-app01
    psh vm-dc01 -Cred 2
    
    # Run this if you want to specify cred and domain instead of stored ones:
    psh vm-app02 -Domain "somethingelse.com" -PromptCredential 

.NOTES
    Run this first to set env variables: setup-envvariables.ps1
    Author: Beckaaaaaaaaa - https://github.com/BeckaNB
    #>
    
function Connect-VM {
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [ValidateSet("1", "2")]
        [string]$Cred = "1",

        [switch]$PromptCredential,

        [string]$Domain = $env:PSH_DOMAIN
    )

    # Secret code check using hash from environment variable
    $secretCodeHash = $env:SECRET_CODE_HASH
    
    if ([string]::IsNullOrEmpty($secretCodeHash)) {
        Write-Host "ERROR: SECRET_CODE_HASH not set." -ForegroundColor Red
        return
    }
    
    $inputCode = Read-Host "Enter code word" -AsSecureString
    $inputCodePlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($inputCode))
    
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $inputHash = [System.BitConverter]::ToString($hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($inputCodePlain))).Replace("-", "")
    
    if ($inputHash -ne $secretCodeHash) {
        Write-Host "Invalid secret code. Access denied." -ForegroundColor Red
        return
    }
    

    $full = "$ComputerName.$Domain"

    # Use stored credentials and open in new tab
    switch ($Cred) {
        "1" { $credential = "$env:USERPROFILE\cred-admin1.xml" }
        "2" { $credential = "$env:USERPROFILE\cred-admin2.xml" }
    }

    if (!(Test-Path $credential)) {
        Write-Host "ERROR: Credential file not found: $credential" -ForegroundColor Red
        Write-Host "Run: Get-Credential | Export-Clixml '$credential'" -ForegroundColor Yellow
        return
    }
    elseif ($PromptCredential) {
        Write-Host "Enter credentials for $full" -ForegroundColor Cyan
        $credential = Get-Credential
        if (-not $credential) {
            Write-Host "No credentials provided. Aborting." -ForegroundColor Red
            return
        }
    }
    $tabColor = if ($Cred -eq "1") { "#b464f5" } elseif ($Cred -eq "2") { "#62b4f7e5" } else { "#92ee67" }
    wt -w 0 new-tab --title "$ComputerName" --tabColor $tabColor pwsh -NoExit -Command `
        "Enter-PSSession -ComputerName $($full) -Credential (Import-Clixml $($credential))"
}

Set-Alias psh Connect-VM

