set nocount on;
with backups as (
select 
  bs.backup_finish_date
, bs.type as bs_type
, bs.database_name
, bs.recovery_model
, row_number() over(partition by bs.database_name, bs.type order by bs.backup_finish_date desc) as rn
 from msdb.dbo.backupset bs
)
select CAST(@@ServerName AS VARCHAR(30)) as server_name
, CAST(SERVERPROPERTY('ServerName') AS VARCHAR(30)) as instance_name
, CAST(d.name AS VARCHAR(30)) as database_name
, CAST(b.recovery_model AS VARCHAR(10)) AS recovery_model
, CASE WHEN b.bs_type = 'L' THEN 'LOG'
	WHEN b.bs_type = 'D' THEN 'FULL'
	WHEN b.bs_type = 'I' THEN 'DIFF'
	ELSE ISNULL(CAST(b.bs_type AS VARCHAR(4)),'NONE') END as bs_type
, getdate() as collection_date
, ISNULL(DATEDIFF(dd, b.backup_finish_date , GETDATE()), 9999) as days_out
from sys.databases d
left join backups b on d.name = b.database_name and rn = 1
order by recovery_model, database_name, backup_finish_date;
