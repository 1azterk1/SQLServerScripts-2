select 
  r.session_id
, r.blocking_session_id
, DATEDIFF(hh, r.start_time, GETDATE()) AS duration_hours
, DATEDIFF(mi, r.start_time, GETDATE())%60 AS duration_minutes
, DATEDIFF(ss, r.start_time, GETDATE())%60 AS duration_seconds
, r.reads 
, r.writes
, r.logical_reads
, r.granted_query_memory
, DB_NAME(r.database_id) AS [database_name]
, s.host_name
, s.login_name
, s.program_name
, OBJECT_NAME(t.objectid, t.dbid) AS [object_name]
, r.status
, r.command
, r.wait_type
, CASE WHEN r.statement_start_offset > 0 THEN
	CASE WHEN r.statement_end_offset = -1 THEN (r.statement_start_offset/2) + 1
	ELSE (r.statement_start_offset/2) + 1 END
  ELSE 0
  END as statement_start
, CASE WHEN r.statement_start_offset > 0 THEN
	CASE WHEN r.statement_end_offset = -1 THEN substring(t.text, (r.statement_start_offset/2) + 1, 2147483647) 
	ELSE substring(t.text, (r.statement_start_offset/2) + 1, ((r.statement_end_offset - r.statement_start_offset)/2)) END
  ELSE
	CASE WHEN r.statement_end_offset = -1 THEN t.text
	ELSE LEFT(t.text, (r.statement_end_offset/2)+1 ) END
  END as executing_statement
from sys.dm_exec_requests r
join sys.dm_exec_sessions s on r.session_id = s.session_id
cross apply sys.dm_exec_sql_text(sql_handle) t
ORDER BY duration_seconds DESC	


