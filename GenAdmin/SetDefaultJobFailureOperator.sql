:setvar operator "DBA"

USE [msdb]
GO

declare @jobid uniqueidentifier

declare acursor cursor for 
select job_id from sysjobs
where notify_level_email = 0
open acursor
fetch acursor into @jobid
while @@fetch_status = 0
begin

	EXEC msdb.dbo.sp_update_job @job_id=@jobid, 
			@notify_level_email=2, 
			@notify_level_netsend=2, 
			@notify_level_page=2, 
			@notify_email_operator_name=N'$(operator)'

	fetch acursor into @jobid


end
close acursor
deallocate acursor

GO



