with c (blocking_session_id, session_id) as (
	select blocking_session_id, session_id 
	from sys.dm_exec_requests
)
, tails as (
	select blocking_session_id, session_id
	from c blockers 
	where blocking_session_id <> 0
	and not exists(
		select 1 
		from c 
		where c.blocking_session_id = blockers.session_id
	)
)
, recurse (l, t, session_id, blocking_session_id) as (
	select 0, session_id, session_id, blocking_session_id  
	from tails
	union all
	select recurse.l+1,recurse.t, c.session_id, c.blocking_session_id from c
	join recurse on c.session_id = recurse.blocking_session_id
)
select replace(replace(replace((
select (
	select session_id as [c]
	from recurse 
	where t = tails.session_id
	order by l desc
	for xml path(''))
),'</c><c>',','),'</c>',''),'<c>','') as blocking_chain
from tails 
order by blocking_chain

