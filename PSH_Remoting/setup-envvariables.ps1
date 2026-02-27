# SCRIPT CAN STILL BE RUN WITHOUT THIS WITH -PromptCredential and -Domain
# RUN THIS ONCE TO SET ENVIRONMENT VARIABLES WANTED

# 1: Set environment variables for credentials used to connect to the vms (this is used if not specified in the prompt):
Get-Credential | Export-Clixml "$env:USERPROFILE\cred-admin1.xml"
Get-Credential | Export-Clixml "$env:USERPROFILE\cred-admin2.xml"

# 2: Set secret code word/number - for an extra layer of security 
$code = Read-Host "Enter a new secret code to use with psh" -AsSecureString
$codePlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($code))
$hasher = [System.Security.Cryptography.SHA256]::Create()
$hash = [System.BitConverter]::ToString($hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($codePlain))).Replace("-", "")
# This is to store the hash in an environment variable called SECRET_CODE_HASH.
[System.Environment]::SetEnvironmentVariable("SECRET_CODE_HASH", $hash, "User") 

# 3: Set domain name in an environment variable (this is used if not specified in the prompt):
$vmdomain = "yourdomain.com"
[System.Environment]::SetEnvironmentVariable("PSH_DOMAIN", "$vmdomain", "User")

# 4: Set trusted hosts for PowerShell remoting for the domain (needs administrator):
Set-Item "WSMan:\localhost\Client\TrustedHosts" -Value "*.$vmdomain"

# 5: This pastes the script in $profile$ so that its available in new pwsh sessions - *you might need to restart pwsh session after this*
get-content ./invoke-psh_remoting.ps1 | Out-File -Append -FilePath $PROFILE -Encoding utf8