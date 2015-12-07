:setvar db ""
:setvar pub ""
:setvar sub ""
:setvar sub_db ""
:on error exit
:setvar article ""
:setvar snapshot_agent ""
:setvar cmd ""

exec sp_helppublication '$(pub)'
GO
exec sp_changepublication  @publication = N'$(pub)', @property = N'allow_anonymous', @value = 'false'
GO
exec sp_changepublication  @publication = N'$(pub)', @property = N'immediate_sync', @value = 'false'
GO

use [etalk_Live]
exec sp_dropsubscription 
@publication = N'$(pub)', 
@article = N'$(article)', 
@subscriber = N'all', 
@destination_db = N'all'
GO

use [etalk_Live]
exec sp_droparticle 
@publication = N'$(pub)', 
@article = N'$(article)', 
@force_invalidate_snapshot = 1
GO


exec sp_changepublication  @publication = N'$(pub)', @property = N'immediate_sync', @value = 'true'
GO
exec sp_changepublication  @publication = N'$(pub)', @property = N'allow_anonymous', @value = 'true'
GO

exec msdb..sp_start_job @job_name = '$(snapshot_agent)'
GO
