declare @c int;
select @c = 1;   /* Top 100% of queries */
select @c = 4;   /* Top 25% of queries */
select @c = 10;  /* Top 10% of queries */
select @c = 100; /* Top 1% of queries*/

with  cross_tile as (
select 
ntile(@c) over(order by execution_count desc) as frequency_rank
, ntile(@c) over(order by total_elapsed_time desc) as elapsed_time_rank
, ntile(@c) over(order by total_worker_time desc) as worker_time_rank
, ntile(@c) over(order by total_rows desc) as rows_rank
, sql_handle
, plan_handle
, statement_start_offset
, statement_end_offset
, execution_count
, total_elapsed_time
, total_worker_time
, total_rows
from sys.dm_exec_query_stats
)
, tops as (
select db_name(t.dbid) as database_name
, object_name(t.objectid, t.dbid) as obj
, execution_count
, (total_elapsed_time / execution_count ) / 1000 as avg_elapsed_ms
, (total_worker_time / execution_count	) / 1000 as avg_worker_ms
, (total_rows / execution_count			) as avg_rows
, CASE WHEN r.statement_start_offset > 0 THEN
	CASE WHEN r.statement_end_offset = -1 THEN substring(t.text, (r.statement_start_offset/2) + 1, 2147483647) 
	ELSE substring(t.text, (r.statement_start_offset/2) + 1, ((r.statement_end_offset - r.statement_start_offset)/2)) END
  ELSE
	CASE WHEN r.statement_end_offset = -1 THEN t.text
	ELSE LEFT(t.text, (r.statement_end_offset/2)+1 ) END
  END as executing_statement

from cross_tile r 
cross apply sys.dm_exec_sql_text(r.sql_handle) t
where 1=1
and frequency_rank = 1 
and elapsed_time_rank = 1 
and rows_rank = 1 
and worker_time_rank = 1
)

select * from tops 
where avg_worker_ms > 1000

