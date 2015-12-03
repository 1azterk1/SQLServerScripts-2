set nocount on;
declare @dbid int;
select @dbid = DB_ID() ;
select cast(@@SERVERNAME as varchar(30)) as server_name
, cast(SERVERPROPERTY('ServerName') as varchar(30)) as instance_name
, DB_NAME() collate database_default as database_name
, OBJECT_NAME(ps.object_id) as TableName
, i.name as IndexName
, ps.index_type_desc
, ps.page_count
, ps.avg_fragmentation_in_percent
, ps.forwarded_record_count
FROM sys.dm_db_index_physical_stats (@dbid, NULL, NULL, NULL, 'DETAILED') AS ps
INNER JOIN sys.indexes AS i
    ON ps.OBJECT_ID = i.OBJECT_ID  AND ps.index_id = i.index_id
where ps.forwarded_record_count is not null;
