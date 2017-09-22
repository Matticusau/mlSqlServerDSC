# 
# Example of changing the default paths for databases in SQL Server
# 

configuration SampleChangeDBDefaultDirs
{

    Param(
		[Parameter(Mandatory=$false)]
		[string]$SqlInstanceName='MSSQLSERVER'
	)

    
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName xSqlServer
	Import-DscResource -ModuleName mlSqlServerDSC


    xSqlServerDefaultDir DefaultDataDir
    {
        SQLServer = $ENV:COMPUTERNAME
        SQLInstanceName = $SqlInstanceName
        Ensure = 'Present'
        Name = 'DefaultData'
        Path = 'F:\MSSQL\Data'
    }

    
    xSqlServerDefaultDir DefaultLogDir
    {
        SQLServer = $ENV:COMPUTERNAME
        SQLInstanceName = $SqlInstanceName
        Ensure = 'Present'
        Name = 'DefaultLog'
        Path = 'F:\MSSQL\Log'
    }
    xSqlServerDefaultDir DefaultBackupDir
    {
        SQLServer = $ENV:COMPUTERNAME
        SQLInstanceName = $SqlInstanceName
        Ensure = 'Present'
        Name = 'BackupDirectory'
        Path = 'F:\MSSQL\Backup' #C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup
        RestartService = $true
    }
    xSqlServerSQLDataRoot sqlDataroot
    {
        SQLServer = $ENV:COMPUTERNAME
        SQLInstanceName = $SqlInstanceName
        Ensure = 'Present'
        Path = 'F:\MSSQL\Data'
        RestartService = $false
    }


}



Set-Location C:\Users\mattl\Documents

SampleChangeDBDefaultDirs -SqlInstanceName 'MSSQLSERVER' -OutputPath . -Verbose

Start-DscConfiguration -Path .\SampleChangeDBDefaultDirs -Wait -Verbose -Force


