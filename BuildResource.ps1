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