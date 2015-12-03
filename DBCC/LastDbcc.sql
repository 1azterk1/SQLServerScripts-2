declare @tbl table ([ParentObect] varchar(255), [Object] varchar(255), [Field] varchar(255), [VALUE] varchar(255))
declare @infotbl table ([database_name] varchar(255), [ParentObect] varchar(255), [Object] varchar(255), [Field] varchar(255), [VALUE] varchar(255))
declare @dbname varchar(255);
declare acursor cursor for select name from sys.databases
open acursor
fetch acursor into @dbname
while @@FETCH_STATUS = 0
begin

	declare @cmd varchar(255) = 'dbcc dbinfo(' + quotename(@dbname,'[') + ') with tableresults;'
	insert @tbl exec (@cmd);
	insert @infotbl select @dbname, * from @tbl where ISDATE(VALUE) = 1 and Field like '%dbcc%';;
	delete from @tbl;

fetch acursor into @dbname
end
close acursor
deallocate acursor


select distinct [database_name]
, GETDATE() as collection_date
, datediff(dd, cast(VALUE as datetime)
, GETDATE()) as days_since_last_dbcc 
from @infotbl order by 3

