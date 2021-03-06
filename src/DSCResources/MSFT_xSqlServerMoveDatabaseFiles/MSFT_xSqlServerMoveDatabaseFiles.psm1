function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [System.String]
        $Database
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    if ($SQLInstanceName -eq 'MSSQLSERVER')
    {
        $serverInstance = $SQLServer;
    }
    else {    
        $serverInstance = Join-Path -Path $SQLServer -ChildPath $SQLInstanceName;
    }

    $returnValue = @()
    
    foreach ($db in ($Database -split ','))
    {

        # get the current paths
        $files = Invoke-Sqlcmd -ServerInstance $serverInstance -Database 'master' -Query "SELECT db_name(database_id) [dbname], name, physical_name AS CurrentLocation, state_desc, type FROM sys.master_files WHERE database_id = DB_ID(N'$db');"
        
        foreach ($file in $files)
        {
            if ($file.Type -eq 0)
            {
                $currentDataPath = Split-Path -Path $file.CurrentLocation -Parent
            }
            else {
                $currentLogPath = Split-Path -Path $file.CurrentLocation -Parent
            }
        }

        $returnValue += [PSCustomObject]@{
            SQLServer = [System.String]$SQLServer
            SQLInstanceName = [System.String]$SQLInstanceName
            Database = [System.String]$db
            DataPath = [System.String]$currentDataPath
            LogPath = [System.String]$currentLogPath
        }
    }

    $returnValue

}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [System.String]
        $DataPath,

        [System.String]
        $LogPath
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1

    if ($SQLInstanceName -eq 'MSSQLSERVER')
    {
        $serverInstance = $SQLServer;
    }
    else {    
        $serverInstance = Join-Path -Path $SQLServer -ChildPath $SQLInstanceName;
    }

    $filesToProcess = @()

    foreach ($db in ($Database -split ','))
    {
        Write-Verbose "Getting files for Database: $db";

        $tsql = "SELECT db_name(database_id) [dbname], name, physical_name AS CurrentLocation, state_desc, type FROM sys.master_files WHERE database_id = DB_ID(N'$db');";
        $files = Invoke-Sqlcmd -ServerInstance $serverInstance -Database 'master' -Query $tsql;
        
        foreach ($file in $files)
        {

            $fileName = Split-Path -Path $file.CurrentLocation -Leaf;

            if ($file.Type -eq 0)
            {
                $newPath = Join-Path -Path $DataPath -ChildPath $fileName;
            }
            else {
                $newPath = Join-Path -Path $LogPath -ChildPath $fileName;
            }
            $tsql = "ALTER DATABASE [$db] MODIFY FILE ( NAME = '$($file.Name)' , FILENAME = '$($newPath)' )"
            Invoke-Sqlcmd -ServerInstance $serverInstance -Database 'master' -Query $tsql;

            $filesToProcess += [PSCustomObject]@{
                FileName = $fileName;
                CurrentPath = $file.CurrentLocation;
                NewPath = $newPath;
            }
        }
    }

    # stop the service
    if ((Get-Service -Name $SqlInstanceName).Status -ne 'Stopped')
    {
        Stop-Service -Name $SqlInstanceName -Force
        (Get-Service -Name $SqlInstanceName).WaitForStatus('Stopped')
    }

    # move the files
    foreach ($file in $filesToProcess)
    {
        # make sure this file actually needs to be moved
        if ($file.CurrentPath -ne $file.NewPath)
        {
            Write-Verbose "Moving '$($file.CurrentPath)' to '$($file.NewPath)'";
            Move-Item -Path $file.CurrentPath -Destination $file.NewPath -Force;
        }
        else {
            Write-Verbose "Skipped moving '$($file.CurrentPath)' as desired path already used";
        }
    }

    # start the service
    if ((Get-Service -Name $SqlInstanceName).Status -ne 'Running')
    {
        Start-Service -Name $SqlInstanceName
        (Get-Service -Name $SqlInstanceName).WaitForStatus('Running')
    }


}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [System.String]
        $DataPath,

        [System.String]
        $LogPath
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."
    if ($SQLInstanceName -eq 'MSSQLSERVER')
    {
        $serverInstance = $SQLServer;
    }
    else {    
        $serverInstance = Join-Path -Path $SQLServer -ChildPath $SQLInstanceName;
    }

    # return value
    [System.Boolean]$success = $true;

    # process each of the databases
    foreach ($db in ($Database -split ','))
    {
        $files = Invoke-Sqlcmd -ServerInstance $serverInstance -Database 'master' -Query "SELECT db_name(database_id) [dbname], name, physical_name AS CurrentLocation, state_desc, type FROM sys.master_files WHERE database_id = DB_ID(N'$db');"
        
        foreach ($file in $files)
        {
            if ($file.Type -eq 0)
            {
                $currentDataPath = Split-Path -Path $file.CurrentLocation -Parent
                if ($currentDataPath -ne $DataPath) {$success = $false}
            }
            else {
                $currentLogPath = Split-Path -Path $file.CurrentLocation -Parent
                if ($currentLogPath -ne $LogPath) {$success = $false}
            }
        }
    }

    return $success
    
    <#
    $result = [System.Boolean]
    
    $result
    #>
}


Export-ModuleMember -Function *-TargetResource

