:setvar operator "DBA"
:setvar old_date "2015-09-10T11:45:45"
USE [msdb]
GO
EXEC master.dbo.sp_MSsetalertinfo @failsafeoperator=N'$(operator)', 
		@notificationmethod=1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1, 
		@databasemail_profile=N'DBA Alerts', 
		@use_databasemail=1
GO
EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date='$(old_date)'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=100000, 
		@jobhistory_max_rows_per_job=10000, 
		@email_save_in_sent_folder=1, 
		@databasemail_profile=N'DBA Alerts', 
		@use_databasemail=1
GO
