Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'mlSQLServerDSCHelper.psm1') -Force

# This resource allows the user to set the SQLDataRoot after moving the Master database
# https://docs.microsoft.com/en-us/sql/relational-databases/databases/move-system-databases
# At this point SQL Server should run normally. However Microsoft recommends also adjusting the registry entry at HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\instance_ID\Setup, where instance_ID is like MSSQL13.MSSQLSERVER. In that hive, change the SQLDataRoot value to the new path. Failure to update the registry can cause patching and upgrading to fail.
# C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL

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
        $SQLInstanceName
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    # get the instance id
    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName
    
    $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\Setup"
    
    # set the 
    try
    {
        $value = (Get-ItemProperty -Path $regKey -Name 'SQLDataRoot').SQLDataRoot
    }
    catch
    {
        Write-Error $_;
        $value = $null;
    }
         
    
    $returnValue = @{
    SQLServer = [System.String]$SQLServer
    SQLInstanceName = [System.String]$SQLInstanceName
    Path = [System.String]$value
    }

    $returnValue
    


    <#
    $returnValue = @{
    SQLServer = [System.String]
    SQLInstanceName = [System.String]
    Ensure = [System.String]
    Path = [System.String]
    RestartService = [System.Boolean]
    }

    $returnValue
    #>
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

        [System.String]
        $Path,

        [System.Boolean]
        $RestartService
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1

    # get the instance id
    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName
    
    $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\Setup"
    
    # set the 
    try
    {
        Set-ItemProperty -Path $regKey -Name 'SQLDataRoot' -Value $Path
        $success = $true

        if ($RestartService)
        {
            Restart-SqlService -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
        }
    }
    catch
    {
        Write-Error $_;
        $success = $false;
    }
         
    $success
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

        [System.String]
        $Path,

        [System.Boolean]
        $RestartService
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName
    
    $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\Setup"
    
    # set the 
    try
    {
        $regPropValue = (Get-ItemProperty -Path $regKey -Name 'SQLDataRoot').SQLDataRoot
    }
    catch
    {
        Write-Error $_;
        $regPropValue = $null;
    }
    
    Write-Verbose "$Path -eq $regPropValue"
    [System.Boolean]$result = ($Path -eq $regPropValue)
    
    $result

}


Export-ModuleMember -Function *-TargetResource

