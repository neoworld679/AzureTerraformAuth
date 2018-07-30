Function PrereqChecks {

    $checkModule = get-command -Name connect-azurermaccount -ErrorAction SilentlyContinue
    
        if ($? -eq $false) {
            Write-Warning "Module not installed or not imported"
            Write-Output "Head to https://docs.microsoft.com/en-us/powershell/azure/install-azurerm-ps?view=azurermps-6.4.0"
         }

        else {

            Write-host "Module is Already Installed" -ForegroundColor Green
        login

        }
}

Function Login {

    Write-host "Enter Login Details" -ForegroundColor Cyan 
    
    $creds = Get-credential 

    try {
    Connect-AzureRmAccount -Credential $creds -ErrorAction Stop
    CreateAZCredentials
    }

    Catch [Microsoft.Azure.Commands.Common.Authentication.AadAuthenticationFailedException] {
        Write-Warning "Cannot login Non interactively with ID Live Accounts" 
        LiveIDaccountFail
    }
    
}

Function LiveIDAccountFail {
    
    Write-host "Attempting to login Interactively" -ForegroundColor Cyan
    
    Connect-AzureRmAccount 

    if ($? -eq $true) {
        Write-host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" -ForegroundColor Cyan
        Write-host "Success" -ForegroundColor Green
        CreateAZCredentials
    }
   

}

Function Create-AesManagedObject($key, $IV) {

    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
        
    if ($IV) {
                if ($IV.getType().Name -eq "String") {
                    $aesManaged.IV = [System.Convert]::FromBase64String($IV)
                }
                else {
                    $aesManaged.IV = $IV
                }
            }
        
            if ($key) {
                if ($key.getType().Name -eq "String") {
                    $aesManaged.Key = [System.Convert]::FromBase64String($key)
                }
                else {
                    $aesManaged.Key = $key
                }
            }
        
            $aesManaged
        }
        
        
Function Create-AesKey() {
            $aesManaged = Create-AesManagedObject 
            $aesManaged.GenerateKey()
            [System.Convert]::ToBase64String($aesManaged.Key)
        }

Function CreateAZCredentials {

    $displayname = Read-host "Enter Display Name, E.g (Name-Env-terraform)"
    
    Set-Variable -Name $displayname -Value $displayname -Scope global

    $homepage = "http://terraform.io"
    $IdentifierURL = [GUID]::NewGuid()
    $IdentifierURLSTR = $IdentifierURL.ToString("N")

    
    $KeyValue = Create-AesKey
    $psadCredential = New-Object Microsoft.Azure.Graph.RBAC.Version1_6.ActiveDirectory.PSADPasswordCredential
            $startDate = Get-Date
            $psadCredential.StartDate = $startDate
            $psadCredential.EndDate = $startDate.AddYears(20)
            $psadCredential.KeyId = [guid]::NewGuid()
            $psadCredential.Password = $KeyValue

    Write-host "Generated Key, Save this value" -ForegroundColor Green
    Write-host "$KeyValue" 
    Set-Variable -Name $KeyValue -Value $KeyValue -Scope Global

    Write-host "Attempting to Generate APP registration" -ForegroundColor Cyan

    $newAzureRMApp = New-AzureRmADApplication -HomePage $homepage -DisplayName $displayname -IdentifierUris $IdentifierURLSTR -PasswordCredentials $psadCredential
    Set-Variable $newAzureRMApp -Value $newAzureRMApp -Scope Global


    if ($? -eq $True) {
        Write-host "Successfully Created App Registration $displayname " -ForegroundColor Green
        OutTF
    }
    
    else {
    Write-Warning "There was an error somewhere"
    }

    }

Function OutTF {
    
    Write-host "Outing Referrencable TF File" -ForegroundColor Cyan
    
    $outputpath = $env:HOMEDRIVE + $env:HOMEPATH + "\Desktop\" + $displayname + ".tf"

    $TenantSubDetails = Get-AzureRmSubscription
    
    $subscription = $TenantSubDetails.Id
    $tenantid = $TenantSubDetails.TenantId
    $clientid = $newazurermApp.ApplicationId

    Add-Content -Path $outputpath -Value "Subscription_id = $subscription"
    Add-Content -Path $outputpath -Value "Tenant_ID = $tenantid"
    Add-Content -Path $outputpath -Value "Client_id = $clientid" 
    Add-Content -Path $outputpath -value "Client_secret = $keyvalue"

    if ($? -eq $true) {
    Write-host "Outputted TF File" -ForegroundColor Green
    }


}

PrereqChecks