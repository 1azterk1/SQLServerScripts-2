create function fn_split(@delim varchar(1), @s varchar(max))
returns @tbl table (id int, val varchar(max))
as
begin
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
	insert @tbl
	select ROW_NUMBER() over(order by a.p) as id
	, SUBSTRING (@s,a.p+1,(b.p-a.p)-1) as val
	from delims a join delims b on a.rn = b.rn - 1
	option(maxrecursion 0);

	return;
end
go

