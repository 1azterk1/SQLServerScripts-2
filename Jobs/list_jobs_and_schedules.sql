/* Uses fn_get_schedule_description to create human readable schedule */
use master
go
with jobs as (
select 
  j.name as job_name
, j.enabled as is_job_enabled
, ISNULL(s.schedule_id, 0) as schedule_id
, s.name as schedule_name 
, s.enabled as is_schedule_enabled
, c.name as category_name
, msdb.dbo.fn_get_schedule_description(s.schedule_id) as schedule_desc
from msdb.dbo.sysschedules s
join msdb.dbo.sysjobschedules js on s.schedule_id = js.schedule_id
right join (
	msdb.dbo.sysjobs j left join msdb.dbo.syscategories c on j.category_id = c.category_id
	) on js.job_id = j.job_id

)
select * from jobs
order by job_name



