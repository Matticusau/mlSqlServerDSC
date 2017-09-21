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

    # get the current paths
    $files = Invoke-Sqlcmd -ServerInstance $serverInstance -Database 'master' -Query "SELECT db_name(database_id) [dbname], name, physical_name AS CurrentLocation, state_desc, type FROM sys.master_files WHERE database_id = DB_ID(N'$Database');"
    
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

    $returnValue = [PSCustomObject]@{
        SQLServer = [System.String]$SQLServer
        SQLInstanceName = [System.String]$SQLInstanceName
        Database = [System.String]$Database
        DataPath = [System.String]$currentDataPath
        LogPath = [System.String]$currentLogPath
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

    $tsql = "SELECT db_name(database_id) [dbname], name, physical_name AS CurrentLocation, state_desc, type FROM sys.master_files WHERE database_id = DB_ID(N'$Database');";
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
        $tsql = "ALTER DATABASE [$Database] MODIFY FILE ( NAME = '$($file.Name)' , FILENAME = '$($newPath)' )"
        Invoke-Sqlcmd -ServerInstance $serverInstance -Database 'master' -Query $tsql;

        $filesToProcess += [PSCustomObject]@{
            FileName = $fileName;
            CurrentPath = $file.CurrentLocation;
            NewPath = $newPath;
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
        Write-Verbose "Moving '$($file.CurrentPath)' to '$($file.NewPath)'";
        Move-Item -Path $file.CurrentPath -Destination $file.NewPath -Force;
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

    $files = Invoke-Sqlcmd -ServerInstance $serverInstance -Database 'master' -Query "SELECT db_name(database_id) [dbname], name, physical_name AS CurrentLocation, state_desc, type FROM sys.master_files WHERE database_id = DB_ID(N'$Database');"
    
    foreach ($file in $files)
    {
        if ($file.Type -eq 0)
        {
            if ($null -eq $currentDataPath) {$currentDataPath = Split-Path -Path $file.CurrentLocation -Parent}
        }
        else {
            if ($null -eq $currentLogPath) {$currentLogPath = Split-Path -Path $file.CurrentLocation -Parent}
        }
    }

    return ($DataPath -eq $currentDataPath -and $LogPath -eq $currentLogPath)
    
    <#
    $result = [System.Boolean]
    
    $result
    #>
}


Export-ModuleMember -Function *-TargetResource

