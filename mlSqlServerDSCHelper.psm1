

<#
    .SYNOPSIS
        Returns the major SQL version for the specific instance.
    .PARAMETER SQLInstanceName
        String containing the name of the SQL instance to be configured. Default value is 'MSSQLSERVER'.
    .OUTPUTS
        System.UInt16. Returns the SQL Server major version number.
#>
function Get-SqlInstanceMajorVersion
{
    [CmdletBinding()]
    [OutputType([System.UInt16])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER'
    )

    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName
    $sqlVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\Setup").Version

    if (-not $sqlVersion)
    {
        $errorMessage = $script:localizedData.SqlServerVersionIsInvalid -f $SQLInstanceName
        New-InvalidResultException -Message $errorMessage
    }

    [System.UInt16] $sqlMajorVersionNumber = $sqlVersion.Split('.')[0]

    return $sqlMajorVersionNumber
}









<#
    .SYNOPSIS
    Restarts a SQL Server instance and associated services.  Modified from helper function in xSqlServer
    .PARAMETER SQLServer
    Hostname of the SQL Server to be configured
    .PARAMETER SQLInstanceName
    Name of the SQL instance to be configured. Default is 'MSSQLSERVER'
    .PARAMETER Timeout
    Timeout value for restarting the SQL services. The default value is 120 seconds.
    .EXAMPLE
    Restart-SqlService -SQLServer localhost
    .EXAMPLE
    Restart-SqlService -SQLServer localhost -SQLInstanceName 'NamedInstance'
    .EXAMPLE
    Restart-SqlService -SQLServer CLU01 -Timeout 300
#>
function Restart-SqlService
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [Int32]
        $Timeout = 120
    )

    $sqlService = Get-Service -DisplayName "SQL Server ($SQLInstanceName)"

    <#
        Get all dependent services that are running.
        There are scenarios where an automatic service is stopped and should not be restarted automatically.
    #>
    $agentService = $sqlService.DependentServices | Where-Object -FilterScript { $_.Status -eq 'Running' }

    # Restart the SQL Server service
    Write-Verbose -Message 'Restarting the service'
    $sqlService | Restart-Service -Force

    # Start dependent services
    $agentService | ForEach-Object {
        Write-Verbose -Message "Starting $_.DisplayName"
        $_ | Start-Service
    }
    
}



