Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) `
-ChildPath 'xmlSQLServerDSCHelper.psm1') `
-Force
<#
.SYNOPSIS
This function gets the TempDB data file count.

.PARAMETER SQLServer
The host name of the SQL Server to be configured.

.PARAMETER SQLInstanceName
The name of the SQL instance to be configured.
#>
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


    $sqlServerObject = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    
    if ($sqlServerObject)
    {
        Write-Verbose -Message 'Getting the max degree of parallelism server configuration option'
        $currentMaxDop = $sqlServerObject.Configuration.MaxDegreeOfParallelism.ConfigValue
    }

    $returnValue = @{
        SQLInstanceName = $SQLInstanceName
        SQLServer       = $SQLServer
        MaxDop          = $currentMaxDop
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

        [System.Boolean]
        $DynamicAlloc,

        [System.UInt32]
        $DataFileCount
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1


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

        [System.Boolean]
        $DynamicAlloc,

        [System.UInt32]
        $DataFileCount
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $result = [System.Boolean]
    
    $result
    #>
}


<#
    .SYNOPSIS
    This cmdlet is used to return the dynamic TempDb file count
#>
function Get-SqlDscDynamicTempDb
{
    $cimInstanceProc = Get-CimInstance -ClassName Win32_Processor

    # init variables
    $numProcs = 0
    $numCores = 0

    # Loop through returned objects
    foreach ($processor in $cimInstanceProc)
    {
        # increment number of processors
        $numProcs += $processor.NumberOfLogicalProcessors

        # increment number of cores
        $numCores += $processor.NumberOfCores
    }


    if ($numProcs -eq 1)
    {
        $dynamicTempDb = [Math]::Round($numCores / 2, [System.MidpointRounding]::AwayFromZero)
    }
    elseif ($numCores -ge 8)
    {
        $dynamicTempDb = 8
    }
    else
    {
        $dynamicTempDb = $numCores
    }

    $dynamicTempDb
}



Export-ModuleMember -Function *-TargetResource

