/* Statistical analysis of missing indexes */
declare @dbname nvarchar(255) = NULL;

/* IQR Factors */
declare @if decimal(18,2) = 1.5;
declare @unique_compiles_if decimal(18,2) = @if;
declare @user_seeks_if decimal(18,2) = @if;
declare @user_scans_if decimal(18,2) = @if;
declare @avg_total_user_cost_if decimal(18,2) = @if;
declare @avg_user_impact_if decimal(18,2) = .25;

declare 
	  @high varchar(10) 
	, @normal varchar(10)
	, @low varchar(10)
	, @ignore varchar(10);
select @high = 'HIGH', @normal = 'NORMAL', @low = 'LOW', @ignore = NULL;

declare  
  @unique_compiles varchar(10)
, @user_seeks varchar(10)
, @user_scans varchar(10)
, @avg_total_user_cost varchar(10)
, @avg_user_impact varchar(10)

/* Definitions */
select 
  @unique_compiles = @high
, @user_seeks = @high
, @user_scans = @ignore
, @avg_total_user_cost = @ignore
, @avg_user_impact = @high
;

with base as (
	select 
	  unique_compiles
	, user_seeks
	, user_scans
	, avg_total_user_cost
	, avg_user_impact
	, group_handle
	from sys.dm_db_missing_index_group_stats s

	where exists (select 1 
	from sys.dm_db_missing_index_groups g 
	join sys.dm_db_missing_index_details d on g.index_handle = d.index_handle
	where s.group_handle = g.index_group_handle
	and d.database_id = db_id(@dbname)
	union 
	select 1 from (select @dbname as dbname) x where x.dbname is null
	)

)

, q as (
	select 
	  NTILE(4) OVER (ORDER BY unique_compiles) AS ntile_unique_compiles
	, NTILE(4) OVER (ORDER BY user_seeks) AS ntile_user_seeks
	, NTILE(4) OVER (ORDER BY user_scans) AS ntile_user_scans
	, NTILE(4) OVER (ORDER BY avg_total_user_cost) AS ntile_avg_total_user_cost
	, NTILE(4) OVER (ORDER BY avg_user_impact) AS ntile_avg_user_impact
	, unique_compiles
	, user_seeks
	, user_scans
	, avg_total_user_cost
	, avg_user_impact
	, group_handle
	from base
)

, ranges as (
	select 
	  (select max(unique_compiles) from q where ntile_unique_compiles = 2) as med_unique_compiles
	, (select max(unique_compiles) from q where ntile_unique_compiles = 3) as q3_unique_compiles
	, (select min(unique_compiles) from q where ntile_unique_compiles = 2) as q1_unique_compiles
	, (select min(unique_compiles) from q) as min_unique_compiles
	, (select max(unique_compiles) from q) as max_unique_compiles

	, (select max(user_seeks) from q where ntile_user_seeks = 2) as med_user_seeks
	, (select max(user_seeks) from q where ntile_user_seeks = 3) as q3_user_seeks
	, (select min(user_seeks) from q where ntile_user_seeks = 2) as q1_user_seeks
	, (select min(user_seeks) from q) as min_user_seeks
	, (select max(user_seeks) from q) as max_user_seeks

	, (select max(user_scans) from q where ntile_user_scans = 2) as med_user_scans
	, (select max(user_scans) from q where ntile_user_scans = 3) as q3_user_scans
	, (select min(user_scans) from q where ntile_user_scans = 2) as q1_user_scans
	, (select min(user_scans) from q) as min_user_scans
	, (select max(user_scans) from q) as max_user_scans

	, (select max(avg_total_user_cost) from q where ntile_avg_total_user_cost = 2) as med_avg_total_user_cost
	, (select max(avg_total_user_cost) from q where ntile_avg_total_user_cost = 3) as q3_avg_total_user_cost
	, (select min(avg_total_user_cost) from q where ntile_avg_total_user_cost = 2) as q1_avg_total_user_cost
	, (select min(avg_total_user_cost) from q) as min_avg_total_user_cost
	, (select max(avg_total_user_cost) from q) as max_avg_total_user_cost

	, (select max(avg_user_impact) from q where ntile_avg_user_impact = 2) as med_avg_user_impact
	, (select max(avg_user_impact) from q where ntile_avg_user_impact = 3) as q3_avg_user_impact
	, (select min(avg_user_impact) from q where ntile_avg_user_impact = 2) as q1_avg_user_impact
	, (select min(avg_user_impact) from q) as min_avg_user_impact
	, (select max(avg_user_impact) from q) as max_avg_user_impact
)
, iqr as (
	select 
	  (q3_unique_compiles - q1_unique_compiles) * @unique_compiles_if as iqr_unique_compiles
	, (q3_user_seeks - q1_user_seeks) * @user_seeks_if as iqr_user_seeks
	, (q3_user_scans - q1_user_scans) * @user_scans_if as iqr_user_scans
	, (q3_avg_total_user_cost - q1_avg_total_user_cost) * @avg_total_user_cost_if as iqr_avg_total_user_cost
	, (q3_avg_user_impact - q1_avg_user_impact) * @avg_user_impact_if as iqr_avg_user_impact
	, *
	from ranges
)

, data as (
select * from base cross apply iqr
)
, normal as (
	select group_handle 
	, case 
		when unique_compiles > med_unique_compiles + iqr_unique_compiles then 'HIGH'
		when unique_compiles < med_unique_compiles - iqr_unique_compiles then 'LOW'
		else 'NORMAL' end as unique_compiles_n
	, case 
		when user_seeks > med_user_seeks + iqr_user_seeks then 'HIGH'
		when user_seeks < med_user_seeks - iqr_user_seeks then 'LOW'
		else 'NORMAL' end as user_seeks_n
	, case 
		when user_scans > med_user_scans + iqr_user_scans then 'HIGH'
		when user_scans < med_user_scans - iqr_user_scans then 'LOW'
		else 'NORMAL' end as user_scans_n
	, case 
		when avg_total_user_cost > med_avg_total_user_cost + iqr_avg_total_user_cost then 'HIGH'
		when avg_total_user_cost < med_avg_total_user_cost - iqr_avg_total_user_cost then 'LOW'
		else 'NORMAL' end as avg_total_user_cost_n
	, case 
		when avg_user_impact > med_avg_user_impact + iqr_avg_user_impact then 'HIGH'
		when avg_user_impact < med_avg_user_impact - iqr_avg_user_impact then 'LOW'
		else 'NORMAL' end as avg_user_impact_n


	from data 
)
, filter as (
	select * 
	from normal
	where 1 = 1
	AND unique_compiles_n = coalesce(@unique_compiles, unique_compiles_n)
	AND user_seeks_n = coalesce(@user_seeks, user_seeks_n)
	AND user_scans_n = coalesce(@user_scans, user_scans_n)
	AND avg_total_user_cost_n = coalesce(@avg_total_user_cost, avg_total_user_cost_n)
	AND avg_user_impact_n = coalesce(@avg_user_impact, avg_user_impact_n)
)

select b.group_handle, g.index_handle
, db_name(d.database_id) as database_name
, OBJECT_NAME(d.object_id, d.database_id) as object_name
, d.equality_columns
, d.inequality_columns
, d.included_columns
, d.statement
, f.unique_compiles_n
, f.user_seeks_n
, f.user_scans_n
, f.avg_total_user_cost_n
, f.avg_user_impact_n
, b.unique_compiles
, b.user_seeks
, b.user_scans
, b.avg_total_user_cost
, b.avg_user_impact
from filter f
join sys.dm_db_missing_index_groups g on f.group_handle = g.index_group_handle
join sys.dm_db_missing_index_details d on g.index_handle = d.index_handle
join base b on f.group_handle = b.group_handle;

--select * from sys.dm_db_missing_index_columns(@handle int)
