/*
 * This is a work in progress
 */

--use procount
--exec sp_changedbowner 'sa'

--with n as (
--select name, type_desc, type, principal_id
--, case 
--when type = 'U' then 'DROP USER ' + QUOTENAME(name,'[') 
--when type = 'G' then 'DROP USER ' + QUOTENAME(name,'[') 
--when type = 'S' then 'DROP USER ' + QUOTENAME(name,'[') 
--when type = 'R' then 'DROP ROLE ' + QUOTENAME(name,'[') 
--else null
--end as stmt
--, case 
--when type = 'U' then 1
--when type = 'G' then 2
--when type = 'S' then 3
--when type = 'R' then 4
--else null
--end as ord


--from sys.database_principals
--where principal_id between 5 and 16383


--)

--select stmt from n order by ord


--select s.name as sch_name
--, p.name as own
-- from sys.schemas s
-- join sys.database_principals p on s.principal_id = p.principal_id
-- where p.principal_id between 5 and 16383


