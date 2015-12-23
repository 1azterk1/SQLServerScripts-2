
declare @cmd varchar(max) 
, @profile varchar(255)
, @sbj varchar(255)
, @rcp varchar(255)
, @fn varchar(255)
, @cust varchar(30)
, @bdy varchar(4000)

/* exec msdb..sysmail_help_profile_sp */
set @profile = 'SQLExec'
set @cust = 'EQT'
set @rcp = 'gklundt@rdx.com'
set @bdy = 'Here is your report!'

set @cmd = 'set nocount on;
select ' + quotename(@cust,'''') + ' as customer_name
, CAST(@@ServerName AS VARCHAR(30)) as server_name
, CAST(SERVERPROPERTY(''ServerName'') AS VARCHAR(30)) as instance_name
, p.name as server_login_name
, p.type_desc as server_login_type
, perm.class_desc
, perm.permission_name
, perm.state_desc
, perm.major_id
, coalesce(o.name,e.name, db.word) as securable
from sys.server_principals p
join sys.server_permissions perm on p.principal_id = perm.grantee_principal_id
left join sys.endpoints e on perm.major_id = e.endpoint_id and perm.class_desc = ''ENDPOINT''
left join sys.all_objects o on perm.major_id = o.object_id AND perm.class_desc = ''OBJECT_OR_COLUMN''
left join (select ''SERVER'' as word) db on perm.class_desc = ''SERVER''
'

set @fn = 'server_perms_' + @cust + '_' + cast(SERVERPROPERTY('ServerName') as varchar(30)) + '_' + CONVERT(varchar(8),getdate(),112) + '.csv'
set @sbj = 'Server Permission Report for ' + @cust 
+ ' - ' + cast(SERVERPROPERTY('ServerName') as varchar(30)) 

exec msdb..sp_send_dbmail @profile_name = @profile
, @recipients = @rcp
, @subject = @sbj
, @query = @cmd
, @execute_query_database = 'msdb'
, @attach_query_result_as_file = 1
, @query_attachment_filename = @fn
, @query_result_header = 1
, @query_result_separator = ','
, @query_result_no_padding = 1
, @query_result_width = 1000
, @body = @bdy


