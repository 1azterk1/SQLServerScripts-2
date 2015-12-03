/* 
  Query generates script for users, roles, role membership, database object grants and database grants
  Set query text mode to 8192 
  Execute in database with existing permissions
  Use script users' logins if new database is on a separate server to create associated logins.
*/

set nocount on ;
declare @dbname sysname = '<New_DB>';

select 'use ' + quotename(@dbname, '[')
+ replicate(char(13) + char(10),1) + 'GO' + replicate(char(13) + char(10),2)
 as [/* Use Database */];

select 'if not exists (select 1 
from sys.database_principals dp join sys.server_principals sp on dp.sid = sp.sid 
where dp.name = ' + quotename(dp.name,'''') + ' or sp.name = ' + quotename(sp.name,'''') +')
create user ' + quotename(dp.name,'[')+' for login ' + quotename(sp.name,'[')
+ replicate(char(13) + char(10),1) + 'GO' + replicate(char(13) + char(10),2)
as [/* Create Users */]
from sys.database_principals dp join sys.server_principals sp on dp.sid = sp.sid
where dp.type in ('S', 'U', 'G');

select 
'if not exists (select 1 from sys.database_principals where name = '+ quotename(name, '''') + ' and type = ''R'')
create role ' + quotename(name,'[')
 + replicate(char(13) + char(10),1) + 'GO' + replicate(char(13) + char(10),2)
as [/* Create Roles */]
from sys.database_principals dp where dp.type ='R'

select 'print ''Adding ' + quotename(m.name,'[') + ' to ' + quotename(r.name,'[') + '''
exec sp_addrolemember ' + quotename(r.name,'''') + ', ' + quotename(m.name,'''')
+ replicate(char(13) + char(10),1) + 'GO' + replicate(char(13) + char(10),2)
as [/* Role Membership */]
from sys.database_principals r
join sys.database_role_members rm on r.principal_id = rm.role_principal_id
join sys.database_principals m on rm.member_principal_id = m.principal_id
join sys.server_principals sp on m.sid = sp.sid
where m.name <> 'dbo'

select 'if exists (select 1 from sys.objects where name = ' + quotename(o.name collate database_default, '''') + ')' + char(13) + char(10)
+ 'if exists (select 1 from sys.database_principals where name = ' + quotename(p.name collate database_default, '''') + ')' + char(13) + char(10)
+ per.state_desc 
+ ' ' + per.permission_name
+ ' ON ' + quotename(s.name collate database_default, '[') + '.' + quotename(o.name collate database_default, '[')
+ ' TO ' + quotename(p.name collate database_default, '[')
+ replicate(char(13) + char(10),1) + 'GO' + replicate(char(13) + char(10),2)
as [/* Object Grants */]
from sys.database_permissions per
join sys.objects o on per.major_id = o.object_id
join sys.schemas s on o.schema_id = s.schema_id
join sys.database_principals p on per.grantee_principal_id = p.principal_id
where class_desc = 'OBJECT_OR_COLUMN'

select 'if exists (select 1 from sys.database_principals where name = ' + quotename(p.name collate database_default, '''') + ')' + char(13) + char(10)
+ per.state_desc 
+ ' ' + per.permission_name
+ ' TO ' + quotename(p.name collate database_default, '[')
+ replicate(char(13) + char(10),1) + 'GO' + replicate(char(13) + char(10),2)
as [/* Database Grants*/]
from sys.database_permissions per
join sys.database_principals p on per.grantee_principal_id = p.principal_id
where class_desc = 'DATABASE'
and p.name <> 'dbo'
