##AD and UKG ID sync
## Created by Eric Schroeder and Jarred Hall
##9/8/2022


## Encrypt SQL Login User Password and set variables
$password = Get-Content "C:\scripts\Password\Password.txt" | ConvertTo-SecureString 
$credential = New-Object System.Management.Automation.PsCredential("DWSQLsvc",$password)

##SQL Export of UKG ID's to CSV
Invoke-Sqlcmd -Query "select *  from dbo.ADUserSync" -ServerInstance "DW-PROD-SQL.truebeck.com" -Database "DW_UKG" -Credential $credential |
Export-Csv -Path "c:\Temp\EmployeeUpload.csv" -NoTypeInformation

##Attache To Active Directory and add new user information
import-module activedirectory
$users = import-csv "c:\Temp\EmployeeUpload.csv"
ForEach ($user in $users) {
    try {
        Get-aduser -identity $user.userName | set-aduser -EmployeeID $user.timeclockID -EmployeeNumber $user.employeeNumber
    }
    catch { "$user.userName Not Found Empid $user.employeeNumber "  | Out-File -Append -FilePath "C:\scripts\errorlog.txt"
    }
}

