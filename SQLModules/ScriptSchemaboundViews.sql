
select distinct 'DROP ' + o.type_desc collate database_default
+ ' ' + quotename(s.name,'[') 
+ '.' + quotename(o.name,'[') as [/*Drops Views*/]
from sys.sql_expression_dependencies d
join sys.sql_modules m on d.referencing_id = m.object_id
join sys.objects o on m.object_id = o.object_id
join sys.schemas s on o.schema_id = s.schema_id
where is_schema_bound_reference = 1
and referenced_id = object_id(N'[dbo].[tbl]')
order by 1

set nocount on;
select 
distinct definition + char(13) + char(10) + 'GO'
--, object_name(referencing_id), * 
from sys.sql_expression_dependencies d
join sys.sql_modules m on d.referencing_id = m.object_id
where is_schema_bound_reference = 1
and referenced_id = object_id(N'[dbo].[tbl]')
and len(definition + char(13) + char(10) + 'GO') < 8000
order by 1

/*Script manually because they are longer than 8000 characters */
select distinct s.name, o.name
from sys.sql_expression_dependencies d
join sys.sql_modules m on d.referencing_id = m.object_id
join sys.objects o on m.object_id = o.object_id
join sys.schemas s on o.schema_id = s.schema_id
where is_schema_bound_reference = 1
and referenced_id = object_id(N'[dbo].[tbl]')
and len(definition + char(13) + char(10) + 'GO') >= 8000
