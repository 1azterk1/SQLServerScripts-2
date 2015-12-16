set nocount on

declare @info table ([Level] nvarchar(255), [Property] nvarchar(4000), [Value] sql_variant);


/* Database Properties */
declare @dbname sysname;
declare acursor cursor for select name from sys.databases
open acursor
fetch acursor into @dbname
while @@FETCH_STATUS = 0
begin
insert @info
select @dbname as [Level], 'Collation' as [Property], DATABASEPROPERTYEX(@dbname,'Collation') as [Value] union all
select @dbname, 'Status', DATABASEPROPERTYEX(@dbname,'Status') union all
select @dbname, 'Updateability', DATABASEPROPERTYEX(@dbname,'Updateability') union all
select @dbname, 'UserAccess', DATABASEPROPERTYEX(@dbname,'UserAccess') union all
select @dbname, 'IsAutoClose', DATABASEPROPERTYEX(@dbname,'IsAutoClose') union all
select @dbname, 'IsAutoCreateStatistics', DATABASEPROPERTYEX(@dbname,'IsAutoCreateStatistics') union all
select @dbname, 'IsAutoUpdateStatistics', DATABASEPROPERTYEX(@dbname,'IsAutoUpdateStatistics') union all
select @dbname, 'IsAutoCreateStatisticsIncremental', DATABASEPROPERTYEX(@dbname,'IsAutoCreateStatisticsIncremental') union all
select @dbname, 'IsAutoShrink', DATABASEPROPERTYEX(@dbname,'IsAutoShrink') union all
select @dbname, 'Recovery', DATABASEPROPERTYEX(@dbname,'Recovery') union all
select @dbname, 'SQLSortOrder', DATABASEPROPERTYEX(@dbname,'SQLSortOrder') union all
select @dbname, 'IsInStandBy', DATABASEPROPERTYEX(@dbname,'IsInStandBy') union all
select @dbname, 'IsMergePublished', DATABASEPROPERTYEX(@dbname,'IsMergePublished') union all
select @dbname, 'IsPublished', DATABASEPROPERTYEX(@dbname,'IsPublished') union all
select @dbname, 'IsSubscribed', DATABASEPROPERTYEX(@dbname,'IsSubscribed') union all
select @dbname, 'IsSyncWithBackup', DATABASEPROPERTYEX(@dbname,'IsSyncWithBackup') union all
select @dbname, 'IsTornPageDetectionEnabled', DATABASEPROPERTYEX(@dbname,'IsTornPageDetectionEnabled') union all

--select @dbname, 'ComparisonStyle', DATABASEPROPERTYEX(@dbname,'ComparisonStyle') union all
--select @dbname, 'Edition', DATABASEPROPERTYEX(@dbname,'Edition') union all
--select @dbname, 'IsAnsiNullDefault', DATABASEPROPERTYEX(@dbname,'IsAnsiNullDefault') union all
--select @dbname, 'IsAnsiNullsEnabled', DATABASEPROPERTYEX(@dbname,'IsAnsiNullsEnabled') union all
--select @dbname, 'IsAnsiPaddingEnabled', DATABASEPROPERTYEX(@dbname,'IsAnsiPaddingEnabled') union all
--select @dbname, 'IsAnsiWarningsEnabled', DATABASEPROPERTYEX(@dbname,'IsAnsiWarningsEnabled') union all
--select @dbname, 'IsArithmeticAbortEnabled', DATABASEPROPERTYEX(@dbname,'IsArithmeticAbortEnabled') union all
--select @dbname, 'IsCloseCursorsOnCommitEnabled', DATABASEPROPERTYEX(@dbname,'IsCloseCursorsOnCommitEnabled') union all
--select @dbname, 'IsFulltextEnabled', DATABASEPROPERTYEX(@dbname,'IsFulltextEnabled') union all
--select @dbname, 'IsLocalCursorsDefault', DATABASEPROPERTYEX(@dbname,'IsLocalCursorsDefault') union all
--select @dbname, 'IsMemoryOptimizedElevateToSnapshotEnabled', DATABASEPROPERTYEX(@dbname,'IsMemoryOptimizedElevateToSnapshotEnabled') union all
--select @dbname, 'IsNullConcat', DATABASEPROPERTYEX(@dbname,'IsNullConcat') union all
--select @dbname, 'IsNumericRoundAbortEnabled', DATABASEPROPERTYEX(@dbname,'IsNumericRoundAbortEnabled') union all
--select @dbname, 'IsParameterizationForced', DATABASEPROPERTYEX(@dbname,'IsParameterizationForced') union all
--select @dbname, 'IsQuotedIdentifiersEnabled', DATABASEPROPERTYEX(@dbname,'IsQuotedIdentifiersEnabled') union all
--select @dbname, 'IsRecursiveTriggersEnabled', DATABASEPROPERTYEX(@dbname,'IsRecursiveTriggersEnabled') union all
--select @dbname, 'LCID', DATABASEPROPERTYEX(@dbname,'LCID') union all
--select @dbname, 'ServiceObjective', DATABASEPROPERTYEX(@dbname,'ServiceObjective') union all
--select @dbname, 'ServiceObjectiveId', DATABASEPROPERTYEX(@dbname,'ServiceObjectiveId') union all
--select @dbname, 'Version', DATABASEPROPERTYEX(@dbname,'Version') union all


select @dbname, 'Owner', SUSER_NAME(owner_sid) from sys.databases where name = @dbname union all
select @dbname, 'Created', create_date from sys.databases where name = @dbname union all
select @dbname, 'CompatibilityLevel', compatibility_level from sys.databases where name = @dbname union all
select @dbname, 'snapshot_isolation_state_desc', snapshot_isolation_state_desc from sys.databases where name = @dbname union all
select @dbname, 'is_read_committed_snapshot_on', is_read_committed_snapshot_on from sys.databases where name = @dbname union all
select @dbname, 'is_db_chaining_on', is_db_chaining_on from sys.databases where name = @dbname union all
select @dbname, 'is_trustworthy_on', is_trustworthy_on from sys.databases where name = @dbname union all
select @dbname, 'page_verify_option_desc', page_verify_option_desc from sys.databases where name = @dbname --union all




fetch acursor into @dbname
end
close acursor
deallocate acursor

/* Server Properties */
insert @info

select 'Server' as [Level], 'CollectionDate'  as [Property],  getdate() as [Value] union all

select 'Server' AS [Level], 'MachineName' as [Property],  SERVERPROPERTY('MachineName') as [Value] union all
select 'Server' AS [Level], 'ComputerNamePhysicalNetBIOS' as [Property],  SERVERPROPERTY('ComputerNamePhysicalNetBIOS') as [Value] union all
select 'Server' AS [Level], 'ServerName' as [Property],  SERVERPROPERTY('ServerName') as [Value] union all
select 'Server' AS [Level], 'Edition' as [Property],  SERVERPROPERTY('Edition') as [Value] union all
select 'Server' AS [Level], 'ProductLevel' as [Property],  SERVERPROPERTY('ProductLevel') as [Value] union all
select 'Server' AS [Level], 'ProductVersion' as [Property],  SERVERPROPERTY('ProductVersion') as [Value] union all
select 'Server' AS [Level], 'ResourceVersion' as [Property],  SERVERPROPERTY('ResourceVersion') as [Value] union all
select 'Server' AS [Level], 'ResourceLastUpdateDateTime' as [Property],  SERVERPROPERTY('ResourceLastUpdateDateTime') as [Value] union all
select 'Server' AS [Level], 'BuildClrVersion' as [Property],  SERVERPROPERTY('BuildClrVersion') as [Value] union all
select 'Server' AS [Level], 'Collation' as [Property],  SERVERPROPERTY('Collation') as [Value] union all
select 'Server' AS [Level], 'IsClustered' as [Property],  SERVERPROPERTY('IsClustered') as [Value] union all
select 'Server' AS [Level], 'IsFullTextInstalled' as [Property],  SERVERPROPERTY('IsFullTextInstalled') as [Value] union all
select 'Server' AS [Level], 'IsHadrEnabled' as [Property],  SERVERPROPERTY('IsHadrEnabled') as [Value] union all
select 'Server' AS [Level], 'IsIntegratedSecurityOnly' as [Property],  SERVERPROPERTY('IsIntegratedSecurityOnly') as [Value] union all
select 'Server' AS [Level], 'IsLocalDB' as [Property],  SERVERPROPERTY('IsLocalDB') as [Value] union all
select 'Server' AS [Level], 'IsSingleUser' as [Property],  SERVERPROPERTY('IsSingleUser') as [Value] union all
select 'Server' AS [Level], 'IsAdvancedAnalyticsInstalled' as [Property],  SERVERPROPERTY('IsAdvancedAnalyticsInstalled') as [Value] union all
select 'Server' AS [Level], 'IsPolybaseInstalled' as [Property],  SERVERPROPERTY('IsPolybaseInstalled') as [Value] union all
select 'Server' AS [Level], 'CollationID' as [Property],  SERVERPROPERTY('CollationID') as [Value] union all
select 'Server' AS [Level], 'ComparisonStyle' as [Property],  SERVERPROPERTY('ComparisonStyle') as [Value] union all
select 'Server' AS [Level], 'EditionID' as [Property],  SERVERPROPERTY('EditionID') as [Value] union all
select 'Server' AS [Level], 'EngineEdition' as [Property],  SERVERPROPERTY('EngineEdition') as [Value] union all
select 'Server' AS [Level], 'HadrManagerStatus' as [Property],  SERVERPROPERTY('HadrManagerStatus') as [Value] union all
select 'Server' AS [Level], 'InstanceName' as [Property],  SERVERPROPERTY('InstanceName') as [Value] union all
select 'Server' AS [Level], 'IsXTPSupported' as [Property],  SERVERPROPERTY('IsXTPSupported') as [Value] union all
select 'Server' AS [Level], 'LCID' as [Property],  SERVERPROPERTY('LCID') as [Value] union all
select 'Server' AS [Level], 'LicenseType' as [Property],  SERVERPROPERTY('LicenseType') as [Value] union all
select 'Server' AS [Level], 'NumLicenses' as [Property],  SERVERPROPERTY('NumLicenses') as [Value] union all
select 'Server' AS [Level], 'ProcessID' as [Property],  SERVERPROPERTY('ProcessID') as [Value] union all
select 'Server' AS [Level], 'ProductBuild' as [Property],  SERVERPROPERTY('ProductBuild') as [Value] union all
select 'Server' AS [Level], 'ProductBuildType' as [Property],  SERVERPROPERTY('ProductBuildType') as [Value] union all
select 'Server' AS [Level], 'ProductMajorVersion' as [Property],  SERVERPROPERTY('ProductMajorVersion') as [Value] union all
select 'Server' AS [Level], 'ProductMinorVersion' as [Property],  SERVERPROPERTY('ProductMinorVersion') as [Value] union all
select 'Server' AS [Level], 'ProductUpdateLevel' as [Property],  SERVERPROPERTY('ProductUpdateLevel') as [Value] union all
select 'Server' AS [Level], 'ProductUpdateReference' as [Property],  SERVERPROPERTY('ProductUpdateReference') as [Value] union all
select 'Server' AS [Level], 'SqlCharSet' as [Property],  SERVERPROPERTY('SqlCharSet') as [Value] union all
select 'Server' AS [Level], 'SqlCharSetName' as [Property],  SERVERPROPERTY('SqlCharSetName') as [Value] union all
select 'Server' AS [Level], 'SqlSortOrder' as [Property],  SERVERPROPERTY('SqlSortOrder') as [Value] union all
select 'Server' AS [Level], 'SqlSortOrderName' as [Property],  SERVERPROPERTY('SqlSortOrderName') as [Value] union all
select 'Server' AS [Level], 'FilestreamShareName' as [Property],  SERVERPROPERTY('FilestreamShareName') as [Value] union all
select 'Server' AS [Level], 'FilestreamConfiguredLevel' as [Property],  SERVERPROPERTY('FilestreamConfiguredLevel') as [Value] union all
select 'Server' AS [Level], 'FilestreamEffectiveLevel' as [Property],  SERVERPROPERTY('FilestreamEffectiveLevel') as [Value] --union all
;

select * from @info
