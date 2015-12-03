with execs as (
select top 10 'execution_count' as metric_name
, execution_count as metric
, execution_count / execution_count as avg_metric
, OBJECT_NAME(objectid, dbid) as obj
, d.text as stmt
from sys.dm_exec_query_stats s
cross apply sys.dm_exec_sql_text(s.sql_handle) d 
where dbid = DB_ID('OdgWebDb')
order by execution_count desc
)
, elapsed as (
select top 10 'total_elapsed_time' as metric_name
, total_elapsed_time as metric
, total_elapsed_time / execution_count as avg_metric
, OBJECT_NAME(objectid, dbid) as obj
, d.text as stmt
from sys.dm_exec_query_stats s
cross apply sys.dm_exec_sql_text(s.sql_handle) d 
where dbid = DB_ID('OdgWebDb')
order by total_elapsed_time desc
)
, worker as (
select top 10 'total_worker_time' as metric_name
, total_worker_time as metric
, total_worker_time / execution_count as avg_metric
, OBJECT_NAME(objectid, dbid) as obj
, d.text as stmt
from sys.dm_exec_query_stats s
cross apply sys.dm_exec_sql_text(s.sql_handle) d 
where dbid = DB_ID('OdgWebDb')
order by total_worker_time desc
)
, unions as (
select * from elapsed
union all 
select * from execs
union all 
select * from worker
)
, metrics as (
select *, COUNT(*) over (partition by obj) as group_count, row_number() over(partition by metric_name order by metric desc) as crit from unions 
)

select * from metrics order by group_count desc, obj;


