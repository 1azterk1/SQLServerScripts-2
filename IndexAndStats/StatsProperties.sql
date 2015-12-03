with st as (
select object_name(p.object_id) as obj, p.*
from sys.stats s
cross apply sys.dm_db_stats_properties(s.object_id, s.stats_id) p
)

select * from st
order by st.last_updated desc
