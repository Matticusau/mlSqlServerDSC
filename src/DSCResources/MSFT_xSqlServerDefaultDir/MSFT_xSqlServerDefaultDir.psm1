Import-Module -Name (Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'mlSQLServerDSCHelper.psm1') -Force


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
        [ValidateSet("BackupDirectory","DefaultData","DefaultLog")]
        [System.String]
        $Name
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    # get the instance id
    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName
    
    $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\MSSQLServer"
    
    # set the 
    try
    {
        $value = (Get-ItemProperty -Path $regKey -Name $Name).$Name
    }
    catch
    {
        Write-Error $_;
        $value = $null;
    }
         
    
    $returnValue = @{
    SQLServer = [System.String]$SQLServer
    SQLInstanceName = [System.String]$SQLInstanceName
    Name = [System.String]$Name
    Path = [System.String]$value
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
        [ValidateSet("BackupDirectory","DefaultData","DefaultLog")]
        [System.String]
        $Name,

        [System.String]
        $Path,

        [System.Boolean]
        $RestartService = $false
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1

    # get the instance id
    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName
    
    $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\MSSQLServer"
    
    # set the 
    try
    {
        Set-ItemProperty -Path $regKey -Name $Name -Value $Path
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

        [parameter(Mandatory = $true)]
        [ValidateSet("BackupDirectory","DefaultData","DefaultLog")]
        [System.String]
        $Name,

        [System.String]
        $Path,
        
        [System.Boolean]
        $RestartService = $false
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName
    
    $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\MSSQLServer"
    
    # set the 
    try
    {
        $regPropValue = (Get-ItemProperty -Path $regKey -Name $Name).$Name
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

