use master
go
select 
  j.name as job_name
, j.enabled as is_job_enabled
, ISNULL(s.schedule_id, 0) as schedule_id
, s.name as schedule_name 
, s.enabled as is_schedule_enabled
, msdb.dbo.fn_get_schedule_description(s.schedule_id)
from msdb.dbo.sysschedules s
join msdb.dbo.sysjobschedules js on s.schedule_id = js.schedule_id
right join msdb.dbo.sysjobs j on js.job_id = j.job_id
order by j.name, s.name


