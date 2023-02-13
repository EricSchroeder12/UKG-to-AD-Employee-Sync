##AD and UKG ID sync
## Created by Eric Schroeder and Jarred Hall
##9/8/2022
##updated 1.20.2023
##updated by Eric Schroeder 2.13.2023 **Added new secure string password call for SQL DB login portion


## Encrypt SQL Login User Password and set variables
Function Get-SavedCredential([string]$UserName,[string]$KeyPath)
{
    If(Test-Path "$($KeyPath)\$($Username).cred") {
        $SecureString = Get-Content "$($KeyPath)\$($Username).cred" | ConvertTo-SecureString
        $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecureString
    }
    Else {
        Throw "Unable to locate a credential for $($Username)"
    }
    Return $Credential
}

$password =  Get-SavedCredential -UserName "DWSQLsvc" -KeyPath "C:\scripts\Password"
##$credential = New-Object System.Management.Automation.PsCredential("DWSQLsvc",$password)

##SQL Export of UKG ID's to CSV
Invoke-Sqlcmd -Query "select *  from dbo.ADUserSync" -ServerInstance "DW-PROD-SQL.truebeck.com" -Database "DW_UKG" -Credential $password |
Export-Csv -Path "c:\Temp\EmployeeUpload.csv" -NoTypeInformation

##Attache To Active Directory and add new user information
import-module activedirectory
$users = import-csv "c:\Temp\EmployeeUpload.csv"
ForEach ($user in $users) {
    try {
        Get-aduser -identity $user.userName | set-aduser -EmployeeID $user.timeclockID -EmployeeNumber $user.employeeNumber -department $user.department
    }
    catch { "{0}|{1}|{2}" -f $user.userName, $user.employeeNumber, (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")  | Out-File -Append -FilePath "C:\scripts\UKG_Sync_Logs\errorlog.txt"
    }
}

robocopy C:\scripts\UKG_Sync_Logs \\dw-prod-sql.truebeck.com\UKG_AD_Sync_Logs /MIR /COPY:DAaT /DCOPY:DAT /Z /J /SL /MT:[10] /R:1 /W:10

