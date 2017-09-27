# set the working directory
Set-Location 'C:\github';

[String]$moduleName = 'mlSqlServerDSC';

# used to create the initial resource
New-xDscResource -Name MSFT_xSqlServerStartupParam -FriendlyName xSqlServerStartupParam -ModuleName $moduleName -Path . -Force -Property @(
    New-xDscResourceProperty -Name SQLServer             -Type String           -Attribute Key -Description 'Hostname of the SQL Server to be configured'
    New-xDscResourceProperty -Name SQLInstanceName       -Type String           -Attribute Key -Description 'Name of the SQL Instance to be configured'
    New-xDscResourceProperty -Name Ensure                -Type String           -Attribute WRite -ValueMap 'Present','Absent' -Values 'Present','Absent'
    New-xDscResourceProperty -Name ParameterName         -Type String           -Attribute Required -Description 'The parameter to configure (e.g. -t, -d)'
    New-xDscResourceProperty -Name ParameterValue        -Type String           -Attribute Write -Description 'The value to set the parameter to'
)

# if you need to update the resource
Update-xDscResource -Name MSFT_cSPN -FriendlyName cSPN -Force -Property @(
    New-xDscResourceProperty -Name ServiceAccount        -Type String           -Attribute Key
    New-xDscResourceProperty -Name Service               -Type String           -Attribute Required
    New-xDscResourceProperty -Name HostName              -Type String           -Attribute Required
    New-xDscResourceProperty -Name Port                  -Type Uint32           -Attribute Required
    New-xDscResourceProperty -Name DomainController      -Type String           -Attribute Write
    New-xDscResourceProperty -Name DomainCredential      -Type PSCredential     -Attribute Write
    New-xDscResourceProperty -Name Ensure                -Type String           -Attribute Required -ValueMap 'Present','Absent' -Values 'Present','Absent'
)



# used to create the initial resource
New-xDscResource -Name MSFT_xSqlServerDefaultDir -FriendlyName xSqlServerDefaultDir -ModuleName $moduleName -Path . -Force -Property @(
    New-xDscResourceProperty -Name SQLServer             -Type String           -Attribute Key -Description 'Hostname of the SQL Server to be configured'
    New-xDscResourceProperty -Name SQLInstanceName       -Type String           -Attribute Key -Description 'Name of the SQL Instance to be configured'
    New-xDscResourceProperty -Name Ensure                -Type String           -Attribute WRite -ValueMap 'Present','Absent' -Values 'Present','Absent'
    New-xDscResourceProperty -Name Name                  -Type String           -Attribute Key -Description 'The default setting to change' -ValueMap 'BackupDirectory','DefaultData','DefaultLog' -Values 'BackupDirectory','DefaultData','DefaultLog'
    New-xDscResourceProperty -Name Path                  -Type String           -Attribute Write -Description 'The path to set as default'
    New-xDscResourceProperty -Name RestartService        -Type Boolean           -Attribute Write -Description 'If set to true then the instance will be restarted after making the change'
)


# used to create the initial resource
New-xDscResource -Name MSFT_xSqlServerDefaultDataRoot -FriendlyName xSqlServerDefaultDataRoot -ModuleName $moduleName -Path . -Force -Property @(
    New-xDscResourceProperty -Name SQLServer             -Type String           -Attribute Key -Description 'Hostname of the SQL Server to be configured'
    New-xDscResourceProperty -Name SQLInstanceName       -Type String           -Attribute Key -Description 'Name of the SQL Instance to be configured'
    New-xDscResourceProperty -Name Ensure                -Type String           -Attribute WRite -ValueMap 'Present','Absent' -Values 'Present','Absent'
    New-xDscResourceProperty -Name Path                  -Type String           -Attribute Write -Description 'The path to set as default'
    New-xDscResourceProperty -Name RestartService        -Type Boolean           -Attribute Write -Description 'If set to true then the instance will be restarted after making the change'
)

# used to create the initial resource
New-xDscResource -Name MSFT_xSqlServerMoveDatabaseFiles -FriendlyName xSqlServerMoveDatabaseFiles -ModuleName $moduleName -Path . -Force -Property @(
    New-xDscResourceProperty -Name SQLServer             -Type String           -Attribute Key -Description 'Hostname of the SQL Server to be configured'
    New-xDscResourceProperty -Name SQLInstanceName       -Type String           -Attribute Key -Description 'Name of the SQL Instance to be configured'
    New-xDscResourceProperty -Name Ensure                -Type String           -Attribute WRite -ValueMap 'Present','Absent' -Values 'Present','Absent'
    New-xDscResourceProperty -Name Database              -Type String           -Attribute Key -Description 'The database(s) to move files for'
    New-xDscResourceProperty -Name DataPath              -Type String           -Attribute Write -Description 'The path to move data files'
    New-xDscResourceProperty -Name LogPath               -Type String           -Attribute Write -Description 'The path to move trans log files'
)

