# mlSQLServerDSC

The **mlSQLServerDSC** module is a complimentary DSC Module to add resources and functionality missing from **xSqlServer**. Over time I will try and move these resources into the official **xSqlServer** but this gives me a way of supporting these until such time.

## Installation

To manually install the module, download the source code and unzip the contents directory to the
'$env:ProgramFiles\WindowsPowerShell\Modules\mlSqlServerDSC' folder.

To install from the PowerShell gallery using PowerShellGet (in PowerShell 5.0) run
the following command:

```powershell
Find-Module -Name mlSqlServerDSC -Repository PSGallery | Install-Module
```

To confirm installation, run the below command and ensure you see the SQL Server
DSC resources available:

```powershell
Get-DscResource -Module mlSqlServerDSC
```

## Requirements

The minimum Windows Management Framework (PowerShell) version required is 5.0 or
higher, which ships with Windows 10 or Windows Server 2016, but can also be
installed on Windows 7 SP1, Windows 8.1, Windows Server 2008 R2 SP1,
Windows Server 2012 and Windows Server 2012 R2.

Unless otherwise stated the resources are supported on SQL 2016 and higher. Refer to the individual resources for specifics regarding SQL Server version support.

## Examples

You can review the [Examples](/Examples) directory in the mlSQLServerDSC module for
some general use scenarios for all of the resources that are in the module.

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Resources

* [**xSQLServerDefaultDir**](#xsqlserverdefaultdir) resource to set the default directories.
* [**xSQLServerMoveDatabaseFiles**](#xsqlservermovedatabasefiles)
  resource to ensure a database has been moved from one location to another.
* [**xSQLServerSQLDataRoot**](#xsqlserversqldataroot)
  sets the data root which is critical if you move the master database location after installation.
* [**xSQLServerStartupParam**](#xsqlserverstartupparam)
  resource to manage the startup parameters for the SQL Server Data Engine.

### xSQLServerDefaultDir

Resource to set the default directories for data files, log files, or backup files

#### Requirements

* TBA

#### Parameters

* **`[String]` SQLServer** _(Key)_: The name of server hosting the sql instance to manage.
* **`[String]` SQLInstanceName** _(Key)_: The SQL Server instance to manage.
* **`[String]` Name** _(Key)_: The setting to manage {BackupDirectory | DefaultData | DefaultLog}.
* **`[String]` Ensure** _(Write)_: Included for consistency with other resources but esentially ignored.
* **`[String]` Path** _(Write)_: The path to set the setting to.
* **`[Boolean]` RestartService** _(Write)_: If $true will restart the server if the setting is changed. Allows you to minimise restarts.

#### Examples

* [Change the default data, log and backup directories](/Examples/SampleChangeDBDefaultDirs.ps1)


### xSQLServerMoveDatabaseFiles

Resource to move database files from one location to another. Designed with the purpose of relocating the databases from the default location to a custom location.

#### Requirements

* TBA

#### Parameters

* **`[String]` SQLServer** _(Key)_: The name of server hosting the sql instance to manage.
* **`[String]` SQLInstanceName** _(Key)_: The SQL Server instance to manage.
* **`[String[]]` Database** _(Key)_: The database(s) to move files for. Separate multiple databases with commas.
* **`[String]` Ensure** _(Write)_: Included for consistency with other resources but esentially ignored.
* **`[String]` DataPath** _(Write)_: The path to move data files.
* **`[String]` LogPath** _(Write)_: The path to move trans log files.

#### Examples

* [Move the Model and Msdb databases from the default location](/Examples/SampleMoveDbFiles.ps1)

### xSQLServerSQLDataRoot

 Resource to set the data root which is critical if you move the master database location after installation. 

 The importance of this setting is explained in https://docs.microsoft.com/en-us/sql/relational-databases/databases/move-system-databases
> At this point SQL Server should run normally. However Microsoft recommends also adjusting the registry entry at HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\instance_ID\Setup, where instance_ID is like MSSQL13.MSSQLSERVER. In that hive, change the SQLDataRoot value to the new path. Failure to update the registry can cause patching and upgrading to fail.

#### Requirements

* TBA

#### Parameters

* **`[String]` SQLServer** _(Key)_: The name of server hosting the sql instance to manage.
* **`[String]` SQLInstanceName** _(Key)_: The SQL Server instance to manage.
* **`[String]` Ensure** _(Write)_: Included for consistency with other resources but esentially ignored.
* **`[String]` Path** _(Write)_: The path to set as default.
* **`[Boolean]` RestartService** _(Write)_: If $true will restart the server if the setting is changed. Allows you to minimise 

#### Examples

* TBA


### xSQLServerStartUpParam

Resource to manage the start up parameters of a SQL Server Instance. This can include traceflags and also setting the location of the master data and log files or the error log fle.

#### Requirements

* TBA

#### Parameters

* **`[String]` SQLServer** _(Key)_: The name of server hosting the sql instance to manage.
* **`[String]` SQLInstanceName** _(Key)_: The SQL Server instance to manage.
* **`[String]` ParameterName** _(Key)_: The parameter to configure (e.g. -t, -d).
* **`[String]` Ensure** _(Write)_: Included for consistency with other resources but esentially ignored.
* **`[String]` ParameterValue** _(Write)_: The value to set the parameter to.

#### Examples

* TBA

