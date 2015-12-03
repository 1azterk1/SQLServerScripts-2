declare @s varchar(max);
declare @delim varchar(1);

set @s = 'Thing1, Thing2,Thing3    ,         ,thing4,,';
set @delim = ','
set @s = @s + @delim;

with chars(p,c) as(
	select 0,cast(@delim as varchar(1))
	union all
	select p+1, cast(SUBSTRING(@s,p+1,1) as varchar(1))
	from chars
	where p < LEN(@s)
)
, delims (p,rn) as (
	  select p
	, ROW_NUMBER() over(order by p) 
	from chars 
	where c = @delim 
)
select ROW_NUMBER() over(order by a.p) as id
, SUBSTRING (@s,a.p+1,(b.p-a.p)-1) as val
from delims a join delims b on a.rn = b.rn - 1
option(maxrecursion 0);
