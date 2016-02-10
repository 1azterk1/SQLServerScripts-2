
declare @dbname varchar(255) = 'name'

declare @cmd varchar(255)
declare acursor cursor for 
	select 'kill ' + cast(s.session_id as varchar(20))
	from sys.dm_tran_locks l
	join sys.dm_exec_sessions s on s.session_id = l.request_session_id
	where resource_database_id = db_id(@dbname)
open acursor
fetch acursor into @cmd
while @@fetch_status = 0
begin
  print (@cmd);
	exec (@cmd);
	fetch acursor into @cmd
end
close acursor
deallocate acursor
