declare @dbname varchar(255)

use msdb;

with fulls as (
	select backup_set_id
	, media_set_id
	, first_lsn
	, last_lsn
	, database_backup_lsn
	, backup_start_date
	, backup_finish_date
	, type
	, database_name
	, row_number() over (partition by database_name, type order by backup_finish_date desc) as rn
	from backupset
	where type = 'D'
)
, last_full as (
	select 
	  backup_set_id
	, media_set_id
	, first_lsn
	, last_lsn
	, database_backup_lsn
	, backup_start_date
	, backup_finish_date
	, type
	, database_name
	, rn - 1 as rn
	from fulls where type = 'D' and rn = 1 and database_name = @dbname
)

, diffs as (
	select b.backup_set_id
	, b.media_set_id
	, b.first_lsn
	, b.last_lsn
	, b.database_backup_lsn
	, b.backup_start_date
	, b.backup_finish_date
	, b.type
	, b.database_name
	, row_number() over (partition by b.database_name, b.type order by b.backup_finish_date desc) 
	as rn
	from backupset b
	join last_full x on b.database_name = x.database_name and b.type = 'I' and b.backup_finish_date > x.backup_finish_date
)

, last_diff as (
	select 
	  backup_set_id
	, media_set_id
	, first_lsn
	, last_lsn
	, database_backup_lsn
	, backup_start_date
	, backup_finish_date
	, type
	, database_name
	, rn + (select min(rn) from last_full) as rn
	from diffs where rn = 1 and 1=1
)

, logs as (
	select 
	  b.backup_set_id
	, b.media_set_id
	, b.first_lsn
	, b.last_lsn
	, b.database_backup_lsn
	, b.backup_start_date
	, b.backup_finish_date
	, b.type
	, b.database_name
	, row_number() over (partition by b.database_name, b.type order by b.backup_finish_date) 
	+ coalesce ((select min(rn) from last_diff),(select min(rn) from last_full))
	as rn
	from backupset b
	join last_full y on b.database_name = y.database_name and b.type = 'L' and b.backup_finish_date > y.backup_finish_date
)
, p as (
	select * from last_full union all 
	select * from last_diff union all 
	select * from logs
)
select
p.rn, p.type, f.physical_device_name
, first_lsn, last_lsn
from p join backupmediafamily f on p.media_set_id = f.media_set_id
order by p.last_lsn;
GO

