

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


<#
    .SYNOPSIS
        Connect to a SQL Server Database Engine and return the server object. Modified from helper function in xSqlServer

    .PARAMETER SQLServer
        String containing the host name of the SQL Server to connect to.

    .PARAMETER SQLInstanceName
        String containing the SQL Server Database Engine instance to connect to.

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when connecting.
        If this is not provided then the current user will be used to connect to the SQL Server Database Engine instance.
#>
function Connect-SQL
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNull()]
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [ValidateNotNull()]
        [System.String]
        $SQLInstanceName = 'MSSQLSERVER',

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )

    Import-SQLPSModule

    if ($SQLInstanceName -eq 'MSSQLSERVER')
    {
        $databaseEngineInstance = $SQLServer
    }
    else
    {
        $databaseEngineInstance = "$SQLServer\$SQLInstanceName"
    }

    if ($SetupCredential)
    {
        $sql = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
        $sql.ConnectionContext.ConnectAsUser = $true
        $sql.ConnectionContext.ConnectAsUserPassword = $SetupCredential.GetNetworkCredential().Password
        $sql.ConnectionContext.ConnectAsUserName = $SetupCredential.GetNetworkCredential().UserName
        $sql.ConnectionContext.ServerInstance = $databaseEngineInstance
        $sql.ConnectionContext.Connect()
    }
    else
    {
        $sql = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $databaseEngineInstance
    }

    if ( $sql.Status -match '^Online$' )
    {
        Write-Verbose -Message ($script:localizedData.ConnectedToDatabaseEngineInstance -f $databaseEngineInstance) -Verbose
        return $sql
    }
    else
    {
        $errorMessage = $script:localizedData.FailedToConnectToDatabaseEngineInstance -f $databaseEngineInstance
        New-InvalidOperationException -Message $errorMessage
    }
}


<#
    .SYNOPSIS
        Imports the module SQLPS in a standardized way. Modified from helper function in xSqlServer
#>
function Import-SQLPSModule
{
    [CmdletBinding()]
    param()

    $module = (Get-Module -FullyQualifiedName 'SqlServer' -ListAvailable).Name
    if ($module)
    {
        Write-Verbose -Message ($script:localizedData.PreferredModuleFound) -Verbose
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.PreferredModuleNotFound) -Verbose

        <#
            After installing SQL Server the current PowerShell session doesn't know about the new path
            that was added for the SQLPS module.
            This reloads PowerShell session environment variable PSModulePath to make sure it contains
            all paths.
        #>
        $env:PSModulePath = [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')

        $module = (Get-Module -FullyQualifiedName 'SQLPS' -ListAvailable).Name
    }

    if ($module)
    {
        try
        {
            Write-Debug -Message ($script:localizedData.DebugMessagePushingLocation)
            Push-Location

            Write-Verbose -Message ($script:localizedData.ImportingPowerShellModule -f $module) -Verbose

            <#
                SQLPS has unapproved verbs, disable checking to ignore Warnings.
                Suppressing verbose so all cmdlet is not listed.
            #>
            Import-Module -Name $module -DisableNameChecking -Verbose:$False -ErrorAction Stop

            Write-Debug -Message ($script:localizedData.DebugMessageImportedPowerShellModule -f $module)
        }
        catch
        {
            $errorMessage = $script:localizedData.FailedToImportPowerShellSqlModule -f $module
            New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
        }
        finally
        {
            Write-Debug -Message ($script:localizedData.DebugMessagePoppingLocation)
            Pop-Location
        }
    }
    else
    {
        $errorMessage = $script:localizedData.PowerShellSqlModuleNotFound
        New-InvalidOperationException -Message $errorMessage
    }
}
