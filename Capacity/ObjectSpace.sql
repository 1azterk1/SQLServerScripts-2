set nocount on;
select cast(@@SERVERNAME as varchar(30)) as server_name
, cast(SERVERPROPERTY('ServerName') as varchar(30)) as instance_name
, cast(DB_NAME() as varchar(30)) as database_name
, cast(ds.name as varchar(30)) as file_group
, cast(s.name as varchar(30)) as schema_name
, cast(o.name as varchar(255)) as object_name
, cast(COALESCE(i.name, i.type_desc collate database_default) as varchar(255)) as index_name
, i.type_desc collate database_default as index_type
, cast(au.type_desc as varchar(30)) as allocation_type_desc
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
join sys.data_spaces ds on au.data_space_id = ds.data_space_id
