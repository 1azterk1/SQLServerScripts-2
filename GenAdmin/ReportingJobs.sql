:setvar cust "customer"
:setvar recipient "report_recipient"

USE [msdb]
GO

/****** Object:  Job [RDX Reporting]    Script Date: 10/7/2015 9:21:40 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 10/7/2015 9:21:40 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Reporting', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Backup]    Script Date: 10/7/2015 9:21:40 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Backup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
declare @cmd varchar(max) 
, @profile varchar(255)
, @sbj varchar(255)
, @rcp varchar(255)
, @fn varchar(255)
, @cust varchar(30)
, @bdy varchar(4000)

/* exec msdb..sysmail_help_profile_sp */
set @profile = ''DBA Alerts''
set @cust = ''$(cust)''
set @rcp = ''$(recipient)''
set @bdy = ''Here is your report!''

set @cmd = ''set nocount on;
with backups as (
select 
  bs.backup_finish_date
, bs.type as bs_type
, bs.database_name
, bs.recovery_model
, row_number() over(partition by bs.database_name, bs.type order by bs.backup_finish_date desc) as rn
 from msdb.dbo.backupset bs
)
select '' + quotename(@cust,'''''''') + '' as customer_name
, CAST(@@ServerName AS VARCHAR(30)) as server_name
, CAST(SERVERPROPERTY(''''ServerName'''') AS VARCHAR(30)) as instance_name
, CAST(d.name AS VARCHAR(30)) as database_name
, CAST(b.recovery_model AS VARCHAR(10)) AS recovery_model
, CASE WHEN b.bs_type = ''''L'''' THEN ''''LOG''''
	WHEN b.bs_type = ''''D'''' THEN ''''FULL''''
	WHEN b.bs_type = ''''I'''' THEN ''''DIFF''''
	ELSE ISNULL(CAST(b.bs_type AS VARCHAR(4)),''''NONE'''') END as bs_type
, getdate() as collection_date
, ISNULL(DATEDIFF(dd, b.backup_finish_date , GETDATE()), 9999) as days_out
from sys.databases d
left join backups b on d.name = b.database_name and rn = 1
order by recovery_model, database_name, backup_finish_date;
''

set @fn = ''backups_'' + @cust + ''_'' + cast(SERVERPROPERTY(''ServerName'') as varchar(30)) + ''_'' + CONVERT(varchar(8),getdate(),112) + ''.csv''
set @sbj = ''Backup Report for '' + @cust 
+ '' - '' + cast(SERVERPROPERTY(''ServerName'') as varchar(30)) 

exec msdb..sp_send_dbmail @profile_name = @profile
, @recipients = @rcp
, @subject = @sbj
, @query = @cmd
, @execute_query_database = ''msdb''
, @attach_query_result_as_file = 1
, @query_attachment_filename = @fn
, @query_result_header = 1
, @query_result_separator = '',''
, @query_result_no_padding = 1
, @query_result_width = 1000
, @body = @bdy

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Page]    Script Date: 10/7/2015 9:21:40 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Page', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @cmd varchar(max) 
, @profile varchar(255)
, @sbj varchar(255)
, @rcp varchar(255)
, @fn varchar(255)
, @cust varchar(30)
, @bdy varchar(4000)

/* exec msdb..sysmail_help_profile_sp */
set @profile = ''DBA Alerts''
set @cust = ''$(cust)''
set @rcp = ''$(recipient)''
set @bdy = ''Here is your report!''

set @cmd = ''set nocount on;
select cast('' + QUOTENAME(@cust,'''''''') + '' as varchar(30)) as cust_name
, cast(@@SERVERNAME as varchar(30)) as server_name
, cast(SERVERPROPERTY(''''ServerName'''') as varchar(30)) as instance_name
, cast(DB_NAME() as varchar(30)) as database_name
, cast(ds.name as varchar(30)) as file_group
, cast(s.name as varchar(30)) as schema_name
, cast(o.name as varchar(255)) as object_name
, cast(COALESCE(i.name, i.type_desc collate database_default) as varchar(255)) as index_name
, cast(au.type_desc as varchar(30)) as type_desc
, GETDATE() as collection_date
, cast(p.rows as bigint) as rows
, cast((au.total_pages * 8192.0)/POWER(1024.0,2.0) as decimal(18,2)) as total_pages_mb
, cast((au.used_pages * 8192.0)/POWER(1024.0,2.0) as decimal(18,2)) as used_pages_mb
, cast((au.data_pages * 8192.0)/POWER(1024.0,2.0) as decimal(18,2)) as data_pages_mb
from sys.schemas s
join sys.objects o on s.schema_id = o.schema_id
join sys.indexes i on o.object_id = i.object_id
join sys.partitions p on i.object_id = p.object_id and i.index_id = p.index_id
join sys.allocation_units au on (au.container_id = p.partition_id and au.type in (2)) or (au.container_id = p.hobt_id and au.type in (1,3))
join sys.data_spaces ds on au.data_space_id = ds.data_space_id''

declare @dbname varchar(255)

declare acursor cursor for select name from sys.databases
open acursor
fetch acursor into @dbname
while @@FETCH_STATUS = 0
begin 

	set @fn = ''page_'' + @cust + ''_'' + cast(SERVERPROPERTY(''ServerName'') as varchar(30)) + ''_'' + @dbname + ''_'' + CONVERT(varchar(8),getdate(),112) + ''.csv''
	set @sbj = ''Page Report for '' + @cust 
	+ '' - '' + cast(SERVERPROPERTY(''ServerName'') as varchar(30)) 
	+ '' - '' + @dbname

	exec msdb..sp_send_dbmail @profile_name = @profile
	, @recipients = @rcp
	, @subject = @sbj
	, @query = @cmd
	, @execute_query_database = @dbname
	, @attach_query_result_as_file = 1
	, @query_attachment_filename = @fn
	, @query_result_header = 1
	, @query_result_separator = '',''
	, @query_result_no_padding = 1
	, @query_result_width = 1000
	, @body = @bdy

	fetch acursor into @dbname
end 
close acursor
deallocate acursor
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [File]    Script Date: 10/7/2015 9:21:40 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'File', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @cmd varchar(max) 
, @profile varchar(255)
, @sbj varchar(255)
, @rcp varchar(255)
, @fn varchar(255)
, @cust varchar(30)
, @bdy varchar(4000)

/* exec msdb..sysmail_help_profile_sp */
set @profile = ''DBA Alerts''
set @cust = ''$(cust)''
set @rcp = ''$(recipient)''
set @bdy = ''Here is your report!''

set @cmd = ''set nocount on;
select cast('' + QUOTENAME(@cust,'''''''') + '' as varchar(30)) as cust_name
, cast(@@SERVERNAME as varchar(30)) as server_name
, cast(SERVERPROPERTY(''''ServerName'''') as varchar(30)) as instance_name
, DB_NAME() collate database_default as database_name
, df.type_desc collate database_default as file_type
, df.name collate database_default as logical_file_name
, physical_name collate database_default as physical_file_name
, coalesce(ds.name collate database_default, df.type_desc collate database_default) as file_group_name
, GETDATE() as collection_datetime
, CAST((size * 8192.0)/POWER(1024.0,2.0) as DECIMAL(18,2)) as size_mb
, CAST((FILEPROPERTY(df.name,''''SpaceUsed'''') * 8192.0)/POWER(1024.0,2.0) as DECIMAL(18,2)) as space_used_mb
, CAST((max_size * 8192.0)/POWER(1024.0,2.0) as DECIMAL(18,2)) as max_size_mb
from sys.database_files df
left join sys.data_spaces ds on df.data_space_id = ds.data_space_id''

declare @dbname varchar(255)

declare acursor cursor for select name from sys.databases
open acursor
fetch acursor into @dbname
while @@FETCH_STATUS = 0
begin 

	set @fn = ''file_'' + @cust + ''_'' + cast(SERVERPROPERTY(''ServerName'') as varchar(30)) + ''_'' + @dbname + ''_'' + CONVERT(varchar(8),getdate(),112) + ''.csv''
	set @sbj = ''File Report for '' + @cust 
	+ '' - '' + cast(SERVERPROPERTY(''ServerName'') as varchar(30)) 
	+ '' - '' + @dbname

	exec msdb..sp_send_dbmail @profile_name = @profile
	, @recipients = @rcp
	, @subject = @sbj
	, @query = @cmd
	, @execute_query_database = @dbname
	, @attach_query_result_as_file = 1
	, @query_attachment_filename = @fn
	, @query_result_header = 1
	, @query_result_separator = '',''
	, @query_result_no_padding = 1
	, @query_result_width = 1000
	, @body = @bdy

	fetch acursor into @dbname
end 
close acursor
deallocate acursor
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Drives]    Script Date: 10/7/2015 9:21:40 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Drives', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @cmd varchar(max) 
, @profile varchar(255)
, @sbj varchar(255)
, @rcp varchar(255)
, @fn varchar(255)
, @cust varchar(30)
, @bdy varchar(4000)

/* exec msdb..sysmail_help_profile_sp */
set @profile = ''DBA Alerts''
set @cust = ''$(cust)''
set @rcp = ''$(recipient)''
set @bdy = ''Here is your report!''

set @cmd = ''set nocount on;
declare @tbl table(drive varchar(10), free bigint)
insert @tbl exec xp_fixeddrives
select cast('' + QUOTENAME(@cust,'''''''') + '' as varchar(30)) as cust_name
, cast(@@SERVERNAME as varchar(30)) as server_name
, cast(SERVERPROPERTY(''''ServerName'''') as varchar(30)) as instance_name
, getdate() as collection_date
, drive, free
from @tbl''

set @fn = ''fixeddrives_'' + @cust + ''_'' + cast(SERVERPROPERTY(''ServerName'') as varchar(30)) + ''_'' + CONVERT(varchar(8),getdate(),112) + ''.csv''
set @sbj = ''Fixed Drives Report for '' + @cust 
+ '' - '' + cast(SERVERPROPERTY(''ServerName'') as varchar(30)) 

exec msdb..sp_send_dbmail @profile_name = @profile
, @recipients = @rcp
, @subject = @sbj
, @query = @cmd
, @execute_query_database = ''master''
, @attach_query_result_as_file = 1
, @query_attachment_filename = @fn
, @query_result_header = 1
, @query_result_separator = '',''
, @query_result_no_padding = 1
, @query_result_width = 1000
, @body = @bdy

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


