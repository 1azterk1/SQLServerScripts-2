set nocount on;
select cast(@@SERVERNAME as varchar(30)) as server_name
, cast(SERVERPROPERTY('ServerName') as varchar(30)) as instance_name
, DB_NAME() collate database_default as database_name
, df.type_desc collate database_default as file_type
, df.name collate database_default as logical_file_name
, physical_name collate database_default as physical_file_name
, coalesce(ds.name collate database_default, df.type_desc collate database_default) as file_group_name
, GETDATE() as collection_datetime
, CAST((size * 8192.0)/POWER(1024.0,2.0) as DECIMAL(18,2)) as size_mb
, CAST((FILEPROPERTY(df.name,'SpaceUsed') * 8192.0)/POWER(1024.0,2.0) as DECIMAL(18,2)) as space_used_mb
, CAST((max_size * 8192.0)/POWER(1024.0,2.0) as DECIMAL(18,2)) as max_size_mb
from sys.database_files df
left join sys.data_spaces ds on df.data_space_id = ds.data_space_id;
