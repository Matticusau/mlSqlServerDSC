# 
# Example of moving the System Databases with xSqlServerMoveDatabaseFiles
# 

configuration SampleMoveDbFiles
{

    Param(
		[Parameter(Mandatory=$false)]
		[string]$SqlInstanceName='MSSQLSERVER'
	)

    
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName xSqlServer
	Import-DscResource -ModuleName mlSqlServerDSC



    xSqlServerMoveDatabaseFiles moveSystemDbs
    {
        SQLServer = $ENV:COMPUTERNAME
        SQLInstanceName = $SqlInstanceName
        Ensure = 'Present'
        Database = 'Model,msdb'
        DataPath = 'F:\MSSQL\Data'
        LogPath = 'F:\MSSQL\Log'
        #DataPath = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA'
        #LogPath = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA'
    }

}



Set-Location C:\Users\mattl\Documents

SampleMoveDbFiles -SqlInstanceName 'MSSQLSERVER' -OutputPath . -Verbose

Start-DscConfiguration -Path .\SampleMoveDbFiles -Wait -Verbose -Force


