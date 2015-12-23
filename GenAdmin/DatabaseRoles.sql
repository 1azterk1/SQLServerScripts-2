declare @cmd varchar(max) 
, @profile varchar(255)
, @sbj varchar(255)
, @rcp varchar(255)
, @fn varchar(255)
, @cust varchar(30)
, @bdy varchar(4000)

/* exec msdb..sysmail_help_profile_sp */
set @profile = 'SQLExec'
set @cust = '<cust>'
set @rcp = '<recpt>'
set @bdy = 'Here is your report!'

set @cmd = 'set nocount on;
select cast(' + QUOTENAME(@cust,'''') + ' as varchar(30)) as cust_name
, cast(@@SERVERNAME as varchar(30)) as server_name
, cast(SERVERPROPERTY(''ServerName'') as varchar(30)) as instance_name
, DB_NAME() collate database_default as database_name
, sp.name as server_login
, sp.type_desc as server_login_type
, p.name as db_role_or_user
, p.type_desc as db_role_or_user_type
, perm.class_desc
, perm.major_id
, perm.minor_id
, perm.permission_name
, perm.state_desc
, coalesce(o.name, s.name, db.word) as securable
from sys.server_principals sp
right join (
	sys.database_principals p 
	join sys.database_permissions perm on p.principal_id = perm.grantee_principal_id
) on sp.sid = p.sid
left join sys.all_objects o on perm.major_id = o.object_id and perm.class_desc = ''OBJECT_OR_COLUMN''
left join sys.schemas s on perm.major_id = s.schema_id and perm.class_desc = ''SCHEMA''
left join (select ''DATABASE'' as word) db on perm.class_desc = ''DATABASE''
'

declare @dbname varchar(255)

declare acursor cursor for select name from sys.databases
open acursor
fetch acursor into @dbname
while @@FETCH_STATUS = 0
begin 

	set @fn = 'database_perms_' + @cust + '_' + cast(SERVERPROPERTY('ServerName') as varchar(30)) + '_' + @dbname + '_' + CONVERT(varchar(8),getdate(),112) + '.csv'
	set @sbj = 'Database Permissions Report for ' + @cust 
	+ ' - ' + cast(SERVERPROPERTY('ServerName') as varchar(30)) 
	+ ' - ' + @dbname

	exec msdb..sp_send_dbmail @profile_name = @profile
	, @recipients = @rcp
	, @subject = @sbj
	, @query = @cmd
	, @execute_query_database = @dbname
	, @attach_query_result_as_file = 1
	, @query_attachment_filename = @fn
	, @query_result_header = 1
	, @query_result_separator = ','
	, @query_result_no_padding = 1
	, @query_result_width = 1000
	, @body = @bdy

	fetch acursor into @dbname
end 
close acursor
deallocate acursor

