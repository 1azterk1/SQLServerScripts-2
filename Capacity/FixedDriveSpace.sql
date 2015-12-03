set nocount on;
declare @tbl table(drive varchar(10), free bigint)
insert @tbl exec xp_fixeddrives
select cast(@@SERVERNAME as varchar(30)) as server_name
, cast(SERVERPROPERTY('ServerName') as varchar(30)) as instance_name
, getdate() as collection_date
, drive, free
from @tbl;
