Import-Module dbatools

#Script Parameters-------------------------------------------------------------------------------------------------------------------------
$Backup = @{

    FULL_DIFF     = '\\VLOPVRSTOAPP01\SQL_Backups_Traveller\TRAVELLERSQLCL\FusionWebToolkitPub'

}
$SQL = @{

    Instance      = 'WERCOVRUATSQLD1,2533'
    Database      = 'FusionWebToolkitPub_PreProd'
    DataDirectory = 'F:\SQLData'
    LogDirectory  = 'F:\SQLTLog'
    FileSuffix    = '_PreProd'

}
$UserAccounts     = @(

    'VRUKL\WebTeamReadOnly','VRUKL\SDLCUat'
)

#------------------------------------------------------------------------------------------------------------------------------------------
#   Restore FULL and DIFF backups
$RestoreParameters = @{
    SqlInstance                 = $SQL.Instance
    DatabaseName                = $SQL.Database
    Path                        = $Backup.FULL_DIFF
    WithReplace                 = $true
    DestinationDataDirectory    = $SQL.DataDirectory
    DestinationLogDirectory     = $SQL.LogDirectory
    DestinationFileSuffix       = $SQL.FileSuffix
    }
Restore-DbaDatabase @RestoreParameters

#------------------------------------------------------------------------------------------------------------------------------------------

#   Set Recovery Model to SIMPLE
Set-DbaDbRecoveryModel -SqlInstance $SQL.Instance -Database $SQL.Database -RecoveryModel Simple -Confirm:$false

#------------------------------------------------------------------------------------------------------------------------------------------

#   Shrink Log file
Invoke-DbaQuery -SqlInstance $SQL.Instance -Database $SQL.Database -Query 'DBCC SHRINKFILE (N'FusionWebToolkit_log' , 0, TRUNCATEONLY)'

#   Drop all users from the FusionWebToolkitPub_PreProd
Get-DbaDbUser -SqlInstance $SQL.Instance -Database $SQL.Database -ExcludeSystemUser | Remove-DbaDbUser

#------------------------------------------------------------------------------------------------------------------------------------------

#   Add the Users and grant DBA permissions
foreach ($User in $UserAccounts) {
    
    New-DbaDbUser -SqlInstance $SQL.Instance -Database $SQL.Database -Login $User  -Username $User
    Add-DbaDbRoleMember -SqlInstance $SQL.Instance -Database $SQL.Database -Role db_owner -User $User -Confirm:$false
}

