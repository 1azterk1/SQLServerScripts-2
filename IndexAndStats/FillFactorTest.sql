select s.name as sch
, o.name as obj
, i.name as idx
, i.index_id
, i.fill_factor
, i.is_padded
, cast(
	case when op.leaf_allocation_count > 0 
	then (1.0 * op.leaf_insert_count + op.leaf_update_count ) / (op.leaf_allocation_count * 1.0) 
	else null end 
	as decimal(18,2)) as leaf_iu_per_alloc
, cast(
	case when op.nonleaf_allocation_count > 0 
	then (1.0 * op.nonleaf_insert_count +  op.nonleaf_update_count ) / (op.nonleaf_allocation_count * 1.0) 
	else null end as decimal(18,2)) as non_leaf_iu_per_alloc
	
, op.leaf_insert_count 
, op.leaf_update_count 
, op.leaf_allocation_count

, op.nonleaf_insert_count
, op.nonleaf_update_count 
, op.nonleaf_allocation_count

from sys.dm_db_index_operational_stats(db_id(),default,default,default) op
join sys.indexes i on i.index_id = op.index_id and i.object_id = op.object_id
join sys.objects o on o.object_id = i.object_id
join sys.schemas s on s.schema_id = o.schema_id
where op.leaf_insert_count + op.leaf_update_count +  op.nonleaf_insert_count +  op.nonleaf_update_count > 0
order by sch, obj, i.index_id
