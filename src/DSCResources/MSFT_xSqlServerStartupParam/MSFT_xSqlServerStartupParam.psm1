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
        [System.String]
        $ParameterName
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    $parameters = Get-SqlStartupParams -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    
    $returnValue = @()

    foreach ($param in $parameters)
    {
        if ($param.Value -match "^$ParameterName")
        {
            $returnValue += [PSCustomObject]@{
                SQLServer = [System.String]$SQLServer
                SQLInstanceName = [System.String]$SQLInstanceName
                ParameterName = [System.String]$ParameterName
                ParameterValue = [System.String]$param.Value -replace $ParameterName,''
            }
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
        $ParameterName,

        [System.String]
        $ParameterValue
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1

    $result = [System.Boolean]

    $parameters = Get-SqlStartupParams -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    if ($ParameterName -eq '-T')
    {
        $param = $parameters | Where-Object Value -eq "$($ParameterName)$($ParameterValue)"
    }
    else
    {
        foreach ($p in $parameters)
        {
            if ($p.Value -match "^$ParameterName")
            {
                $param = $p
                break
            }
        }
    }

    if ($Ensure -eq 'Absent')
    {
        if ($param)
        {
            $result = Remove-SqlStartupParam -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -RegKeyProperty $param.Name
        }
    }
    else
    {
        if ($param)
        {
            $result = Set-SqlStartupParam -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -RegKeyProperty $param.Name -RegKeyValue "$($ParameterName)$($ParameterValue)"
        }
        else
        {
            # get the new arg number
            $regKeyPropNum = $parameters.Count
            $regKeyProp = "SQLArg$regKeyPropNum"
            $result = Set-SqlStartupParam -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -RegKeyProperty $regKeyProp -RegKeyValue "$($ParameterName)$($ParameterValue)"
        }
    }

    return $result
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
        $ParameterName,

        [System.String]
        $ParameterValue
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    
    $result = [System.Boolean]
    
    $parameters = Get-SqlStartupParams -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName

    $param = $parameters | Where-Object Value -eq "$($ParameterName)$($ParameterValue)"
       
    
    if ($Ensure -eq 'Absent')
    {
        if ($param)
        {
            $result = $false
        }
        else
        {
            $result = $true
        }
    }
    else
    {
        if (!($param))
        {
            $result = $false
        }
        else
        {
            $result = $true
        }
    }


    $result
    
}


Export-ModuleMember -Function *-TargetResource





function Get-SqlStartupParams
{
    [CmdLetBinding()]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
    )

    # get the instance id
    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName

    $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\MSSQLServer\Parameters"
    $property = Get-ItemProperty $regKey
    
    # get the start up parameters
    $startupParameters = $property.psobject.properties | ?{$_.Name -like 'SQLArg*'}
    
    # return the start up parameters
    return $startupParameters | Select-Object Name, Value

}


function Set-SqlStartupParam
{
    [CmdLetBinding()]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
        ,
        [parameter(Mandatory = $true)]
        [System.String]
        $RegKeyProperty
        ,
        [parameter(Mandatory = $true)]
        [System.String]
        $RegKeyValue
    )

    # get the instance id
    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName

    $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\MSSQLServer\Parameters"
    
    # set the 
    try
    {
        Set-ItemProperty -Path $regKey -Name $RegKeyProperty -Value $RegKeyValue
        $success = $true;
    }
    catch
    {
        Write-Error $_;
        $success = $false;
    }
        
    # return if we were successful
    return $success

}


function Remove-SqlStartupParam
{
    [CmdLetBinding()]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [parameter(Mandatory = $true)]
        [System.String]
        $SQLInstanceName
        ,
        [parameter(Mandatory = $true)]
        [System.String]
        $RegKeyProperty
    )

    # get the instance id
    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$SQLInstanceName

    $regKey = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\MSSQLServer\Parameters"
    
    # set the 
    try
    {
        Remove-ItemProperty -Path $regKey -Name $RegKeyProperty
        $success = $true;
    }
    catch
    {
        Write-Error $_;
        $success = $false;
    }
        
    # return if we were successful
    return $success

}




