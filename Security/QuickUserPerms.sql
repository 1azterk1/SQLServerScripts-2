/*  Change to login needed to check
 *  Must have impersonate permissions in order to execute 
 *  as a different login.
 */
execute as login = SUSER_NAME();

with general_permissions (scope, principal_name, permission_name, state_desc, name, object_type, principal_id) as (
select 'DATABASE'
	, dp.name 
	, p.permission_name
	, p.state_desc
	, db_name() 
	, 'Database'
	, dp.principal_id
from sys.database_principals dp
join sys.database_permissions p on dp.principal_id = p.grantee_principal_id
where p.class_desc = 'DATABASE'
union all 
select 'OBJECT_OR_COLUMN'
	, dp.name
	, p.permission_name
	, p.state_desc
	, o.name
	, o.type_desc
	, dp.principal_id
from sys.database_principals dp
join sys.database_permissions p on dp.principal_id = p.grantee_principal_id
join sys.objects o on p.major_id = o.object_id
where p.class_desc = 'OBJECT_OR_COLUMN'
union all 
select 'SCHEMA'
	, dp.name
	, p.permission_name
	, p.state_desc
	, s.name
	, 'Schema'
	, dp.principal_id
from sys.database_principals dp
join sys.database_permissions p on dp.principal_id = p.grantee_principal_id
join sys.schemas s on p.major_id = s.schema_id
where p.class_desc = 'SCHEMA')
select * from general_permissions 
where principal_id in (select principal_id from sys.user_token);

revert
