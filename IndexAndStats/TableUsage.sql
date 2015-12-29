

with objs as (
	select 
	  DB_ID() as database_id
	, o.object_id
	, s.name as sch
	, o.name as obj
	, i.index_id
	, o.type_desc
	, o.type
	from sys.schemas s 
	join sys.objects o on s.schema_id = o.schema_id and s.name <> 'sys' and o.type = 'U'
	join sys.indexes i on i.object_id = o.object_id
)
, obj_usage as (
	select 
	  o.database_id
	, o.object_id
	, o.sch
	, o.obj
	, o.index_id
	, o.type_desc
	, o.type

	, isnull(u.user_seeks,0)
	+ isnull(u.user_scans,0)
	+ isnull(u.user_lookups,0)
	+ isnull(u.user_updates,0) as access


	, (select max(last_access) from (
	select u1.last_user_seek as last_access from sys.dm_db_index_usage_stats u1 where u1.database_id = u.database_id and u.object_id = u1.object_id and u.index_id = u1.index_id union all
	select u1.last_user_scan from sys.dm_db_index_usage_stats u1 where u1.database_id = u.database_id and u.object_id = u1.object_id and u.index_id = u1.index_id union all
	select u1.last_user_lookup from sys.dm_db_index_usage_stats u1 where u1.database_id = u.database_id and u.object_id = u1.object_id and u.index_id = u1.index_id union all
	select u1.last_user_update from sys.dm_db_index_usage_stats u1 where u1.database_id = u.database_id and u.object_id = u1.object_id and u.index_id = u1.index_id 
	) as last_access ) as last_access

	from objs o
	left join sys.dm_db_index_usage_stats u on o.database_id = u.database_id and u.object_id = o.object_id and u.index_id = o.index_id
)
select sch, obj, SUM(access) as access_count, MAX(last_access) as last_access
from obj_usage 
group by sch, obj
order by MAX(last_access)
