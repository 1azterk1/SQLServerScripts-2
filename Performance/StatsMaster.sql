/* 
Only look for queries within a reasonable elapsed time frame (microseconds) 
h_size  * h_pos
*/
declare @min_avg_elapsed_time int, @max_avg_elapsed_time int;
select @min_avg_elapsed_time = 1 * 1000000, @max_avg_elapsed_time = null  

--declare @query_type varchar(20);
--select @query_type = 'iqr_all'
--select @query_type = 'filters'
--select @query_type = 'plans'
--select @query_type = 'statements'

/* Complex Statistical Values */
declare 
	  @high varchar(10) 
	, @normal varchar(10)
	, @low varchar(10)
	, @ignore varchar(10);
select @high = 'HIGH', @normal = 'NORMAL', @low = 'LOW', @ignore = NULL;

declare  
  @execution_count varchar(10)
, @avg_elapsed_time_ms varchar(10)
, @avg_worker_time_ms varchar(10)
, @avg_rows varchar(10)
, @avg_logical_reads varchar(10)
, @avg_clr_time_ms varchar(10)
, @avg_logical_writes varchar(10)
, @avg_physical_reads varchar(10)

declare  
  @execution_count_if decimal(18,2)
, @avg_elapsed_time_ms_if decimal(18,2)
, @avg_worker_time_ms_if decimal(18,2)
, @avg_rows_if decimal(18,2)
, @avg_logical_reads_if decimal(18,2)
, @avg_clr_time_ms_if decimal(18,2)
, @avg_logical_writes_if decimal(18,2)
, @avg_physical_reads_if decimal(18,2)


/* Definitions */
select 
  @execution_count = @high
, @avg_elapsed_time_ms = @high
, @avg_worker_time_ms = @ignore
, @avg_rows = @ignore
, @avg_logical_reads = @ignore
, @avg_clr_time_ms = @ignore
, @avg_logical_writes = @ignore
, @avg_physical_reads = @ignore
;

/* IQR Factors */
declare @common_if decimal(18,2)
set @common_if = 1.5
select 
  @execution_count_if = @common_if
, @avg_elapsed_time_ms_if = @common_if
, @avg_worker_time_ms_if = @common_if
, @avg_rows_if = @common_if
, @avg_logical_reads_if = @common_if
, @avg_clr_time_ms_if = @common_if
, @avg_logical_writes_if = @common_if
, @avg_physical_reads_if = @common_if
;

with base as (
	select  
	/* POST-2008 R2 query stats */
	  statement_start_offset
	, statement_end_offset
	, (total_rows / execution_count) as avg_rows 
	, (total_clr_time / execution_count) as avg_clr_time_ms
	
	/* PRE-2008 R2 query stats*/
	--  statement_start_offset
	--, statement_end_offset
	--, 0 as avg_rows 
	--, 0 as avg_clr_time_ms

	/* procedure stats*/
	--  0 as statement_start_offset
	--, 2147483647 as statement_end_offset
	--, 0 as avg_rows /* Less than 2012 */
	--, 0 as avg_clr_time_ms

	, sql_handle
	, plan_handle
	, execution_count
	, (total_elapsed_time / execution_count) as avg_elapsed_time_ms
	, (total_worker_time / execution_count) as avg_worker_time_ms
	, (total_logical_reads / execution_count) as avg_logical_reads
	, (total_logical_writes / execution_count) as avg_logical_writes
	, (total_physical_reads / execution_count) as avg_physical_reads

	/* query stats */
	from sys.dm_exec_query_stats
	where (total_elapsed_time / execution_count) between @min_avg_elapsed_time and coalesce(@max_avg_elapsed_time, (select max((total_elapsed_time / execution_count)) from sys.dm_exec_query_stats))

	/* procedure stats */
	--from sys.dm_exec_procedure_stats
)
select * into #base from base;

with ntiles as (
	select statement_start_offset
	, statement_end_offset
	, sql_handle
	, plan_handle
	, execution_count
	, ntile(20) over (order by execution_count) as execution_count_q
	, avg_elapsed_time_ms
	, ntile(20) over (order by avg_elapsed_time_ms) as avg_elapsed_time_ms_q
	, avg_worker_time_ms
	, ntile(20) over (order by avg_worker_time_ms) as avg_worker_time_ms_q
	, avg_rows
	, ntile(20) over (order by avg_rows) as avg_rows_q
	, avg_logical_reads
	, ntile(20) over (order by avg_logical_reads) as avg_logical_reads_q
	, avg_clr_time_ms
	, ntile(20) over (order by avg_clr_time_ms) as avg_clr_time_ms_q
	, avg_logical_writes
	, ntile(20) over (order by avg_logical_writes) as avg_logical_writes_q
	, avg_physical_reads
	, ntile(20) over (order by avg_physical_reads) as avg_physical_reads_q
	from #base
)
, iqr_execution_count as (
	select iqr.iqr, iqr.med, iqr.q1, iqr.q3, iqr.med - iqr.iqr as iqr_low, iqr.med + iqr.iqr as iqr_high, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select (q.q3 - q.q1) * @execution_count_if as iqr, q.med, q.q1, q.q3, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select 
	  (select max(execution_count) from ntiles where execution_count_q = 5) as q1
	, (select max(execution_count) from ntiles where execution_count_q = 10) as med
	, (select max(execution_count) from ntiles where execution_count_q = 15) as q3
	, (select min(execution_count) from ntiles) as mn
	, (select max(execution_count) from ntiles) as mx
	, (select avg(execution_count) from ntiles) as av
	--, (select min(execution_count) from ntiles where execution_count_q = 1) as n01
	--, (select min(execution_count) from ntiles where execution_count_q = 2) as n02
	--, (select min(execution_count) from ntiles where execution_count_q = 3) as n03
	--, (select min(execution_count) from ntiles where execution_count_q = 4) as n04
	--, (select min(execution_count) from ntiles where execution_count_q = 5) as n05
	--, (select min(execution_count) from ntiles where execution_count_q = 6) as n06
	--, (select min(execution_count) from ntiles where execution_count_q = 7) as n07
	--, (select min(execution_count) from ntiles where execution_count_q = 8) as n08
	--, (select min(execution_count) from ntiles where execution_count_q = 9) as n09
	--, (select min(execution_count) from ntiles where execution_count_q = 10) as n10
	--, (select min(execution_count) from ntiles where execution_count_q = 11) as n11
	--, (select min(execution_count) from ntiles where execution_count_q = 12) as n12
	--, (select min(execution_count) from ntiles where execution_count_q = 13) as n13
	--, (select min(execution_count) from ntiles where execution_count_q = 14) as n14
	--, (select min(execution_count) from ntiles where execution_count_q = 15) as n15
	--, (select min(execution_count) from ntiles where execution_count_q = 16) as n16
	--, (select min(execution_count) from ntiles where execution_count_q = 17) as n17
	--, (select min(execution_count) from ntiles where execution_count_q = 18) as n18
	--, (select min(execution_count) from ntiles where execution_count_q = 19) as n19
	--, (select min(execution_count) from ntiles where execution_count_q = 20) as n20
	) as q) as iqr
)
, iqr_avg_elapsed_time_ms as (
	select iqr.iqr, iqr.med, iqr.q1, iqr.q3, iqr.med - iqr.iqr as iqr_low, iqr.med + iqr.iqr as iqr_high, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select (q.q3 - q.q1) * @avg_elapsed_time_ms_if as iqr, q.med, q.q1, q.q3, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select 
	  (select max(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 5) as q1
	, (select max(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 10) as med
	, (select max(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 15) as q3
	, (select min(avg_elapsed_time_ms) from ntiles) as mn
	, (select max(avg_elapsed_time_ms) from ntiles) as mx
	, (select avg(avg_elapsed_time_ms) from ntiles) as av
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 1) as n01
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 2) as n02
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 3) as n03
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 4) as n04
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 5) as n05
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 6) as n06
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 7) as n07
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 8) as n08
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 9) as n09
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 10) as n10
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 11) as n11
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 12) as n12
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 13) as n13
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 14) as n14
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 15) as n15
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 16) as n16
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 17) as n17
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 18) as n18
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 19) as n19
	--, (select min(avg_elapsed_time_ms) from ntiles where avg_elapsed_time_ms_q = 20) as n20
	) as q) as iqr
)
, iqr_avg_worker_time_ms as (
	select iqr.iqr, iqr.med, iqr.q1, iqr.q3, iqr.med - iqr.iqr as iqr_low, iqr.med + iqr.iqr as iqr_high, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select (q.q3 - q.q1) * @avg_worker_time_ms_if as iqr, q.med, q.q1, q.q3, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select 
	  (select max(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 5) as q1
	, (select max(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 10) as med
	, (select max(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 15) as q3
	, (select min(avg_worker_time_ms) from ntiles) as mn
	, (select max(avg_worker_time_ms) from ntiles) as mx
	, (select avg(avg_worker_time_ms) from ntiles) as av
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 1) as n01
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 2) as n02
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 3) as n03
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 4) as n04
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 5) as n05
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 6) as n06
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 7) as n07
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 8) as n08
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 9) as n09
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 10) as n10
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 11) as n11
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 12) as n12
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 13) as n13
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 14) as n14
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 15) as n15
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 16) as n16
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 17) as n17
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 18) as n18
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 19) as n19
	--, (select min(avg_worker_time_ms) from ntiles where avg_worker_time_ms_q = 20) as n20
	) as q) as iqr
)
, iqr_avg_rows as (
	select iqr.iqr, iqr.med, iqr.q1, iqr.q3, iqr.med - iqr.iqr as iqr_low, iqr.med + iqr.iqr as iqr_high, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select (q.q3 - q.q1) * @avg_rows_if as iqr, q.med, q.q1, q.q3, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select 
	  (select max(avg_rows) from ntiles where avg_rows_q = 5) as q1
	, (select max(avg_rows) from ntiles where avg_rows_q = 10) as med
	, (select max(avg_rows) from ntiles where avg_rows_q = 15) as q3
	, (select min(avg_rows) from ntiles) as mn
	, (select max(avg_rows) from ntiles) as mx
	, (select avg(avg_rows) from ntiles) as av
	--, (select min(avg_rows) from ntiles where avg_rows_q = 1) as n01
	--, (select min(avg_rows) from ntiles where avg_rows_q = 2) as n02
	--, (select min(avg_rows) from ntiles where avg_rows_q = 3) as n03
	--, (select min(avg_rows) from ntiles where avg_rows_q = 4) as n04
	--, (select min(avg_rows) from ntiles where avg_rows_q = 5) as n05
	--, (select min(avg_rows) from ntiles where avg_rows_q = 6) as n06
	--, (select min(avg_rows) from ntiles where avg_rows_q = 7) as n07
	--, (select min(avg_rows) from ntiles where avg_rows_q = 8) as n08
	--, (select min(avg_rows) from ntiles where avg_rows_q = 9) as n09
	--, (select min(avg_rows) from ntiles where avg_rows_q = 10) as n10
	--, (select min(avg_rows) from ntiles where avg_rows_q = 11) as n11
	--, (select min(avg_rows) from ntiles where avg_rows_q = 12) as n12
	--, (select min(avg_rows) from ntiles where avg_rows_q = 13) as n13
	--, (select min(avg_rows) from ntiles where avg_rows_q = 14) as n14
	--, (select min(avg_rows) from ntiles where avg_rows_q = 15) as n15
	--, (select min(avg_rows) from ntiles where avg_rows_q = 16) as n16
	--, (select min(avg_rows) from ntiles where avg_rows_q = 17) as n17
	--, (select min(avg_rows) from ntiles where avg_rows_q = 18) as n18
	--, (select min(avg_rows) from ntiles where avg_rows_q = 19) as n19
	--, (select min(avg_rows) from ntiles where avg_rows_q = 20) as n20
	) as q) as iqr
)
, iqr_avg_logical_reads as (
	select iqr.iqr, iqr.med, iqr.q1, iqr.q3, iqr.med - iqr.iqr as iqr_low, iqr.med + iqr.iqr as iqr_high, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select (q.q3 - q.q1) * @avg_logical_reads_if as iqr, q.med, q.q1, q.q3, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select 
	  (select max(avg_logical_reads) from ntiles where avg_logical_reads_q = 5) as q1
	, (select max(avg_logical_reads) from ntiles where avg_logical_reads_q = 10) as med
	, (select max(avg_logical_reads) from ntiles where avg_logical_reads_q = 15) as q3
	, (select min(avg_logical_reads) from ntiles) as mn
	, (select max(avg_logical_reads) from ntiles) as mx
	, (select avg(avg_logical_reads) from ntiles) as av
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 1) as n01
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 2) as n02
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 3) as n03
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 4) as n04
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 5) as n05
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 6) as n06
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 7) as n07
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 8) as n08
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 9) as n09
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 10) as n10
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 11) as n11
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 12) as n12
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 13) as n13
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 14) as n14
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 15) as n15
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 16) as n16
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 17) as n17
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 18) as n18
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 19) as n19
	--, (select min(avg_logical_reads) from ntiles where avg_logical_reads_q = 20) as n20
	) as q) as iqr
)
, iqr_avg_clr_time_ms as (
	select iqr.iqr, iqr.med, iqr.q1, iqr.q3, iqr.med - iqr.iqr as iqr_low, iqr.med + iqr.iqr as iqr_high, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select (q.q3 - q.q1) * @avg_clr_time_ms_if as iqr, q.med, q.q1, q.q3, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select 
	  (select max(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 5) as q1
	, (select max(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 10) as med
	, (select max(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 15) as q3
	, (select min(avg_clr_time_ms) from ntiles) as mn
	, (select max(avg_clr_time_ms) from ntiles) as mx
	, (select avg(avg_clr_time_ms) from ntiles) as av
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 1) as n01
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 2) as n02
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 3) as n03
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 4) as n04
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 5) as n05
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 6) as n06
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 7) as n07
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 8) as n08
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 9) as n09
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 10) as n10
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 11) as n11
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 12) as n12
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 13) as n13
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 14) as n14
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 15) as n15
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 16) as n16
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 17) as n17
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 18) as n18
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 19) as n19
	--, (select min(avg_clr_time_ms) from ntiles where avg_clr_time_ms_q = 20) as n20
	) as q) as iqr
)
, iqr_avg_logical_writes as (
	select iqr.iqr, iqr.med, iqr.q1, iqr.q3, iqr.med - iqr.iqr as iqr_low, iqr.med + iqr.iqr as iqr_high, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select (q.q3 - q.q1) * @avg_logical_writes_if as iqr, q.med, q.q1, q.q3, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select 
	  (select max(avg_logical_writes) from ntiles where avg_logical_writes_q = 5) as q1
	, (select max(avg_logical_writes) from ntiles where avg_logical_writes_q = 10) as med
	, (select max(avg_logical_writes) from ntiles where avg_logical_writes_q = 15) as q3
	, (select min(avg_logical_writes) from ntiles) as mn
	, (select max(avg_logical_writes) from ntiles) as mx
	, (select avg(avg_logical_writes) from ntiles) as av
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 1) as n01
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 2) as n02
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 3) as n03
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 4) as n04
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 5) as n05
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 6) as n06
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 7) as n07
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 8) as n08
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 9) as n09
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 10) as n10
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 11) as n11
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 12) as n12
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 13) as n13
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 14) as n14
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 15) as n15
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 16) as n16
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 17) as n17
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 18) as n18
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 19) as n19
	--, (select min(avg_logical_writes) from ntiles where avg_logical_writes_q = 20) as n20
	) as q) as iqr
)
, iqr_avg_physical_reads as (
	select iqr.iqr, iqr.med, iqr.q1, iqr.q3, iqr.med - iqr.iqr as iqr_low, iqr.med + iqr.iqr as iqr_high, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select (q.q3 - q.q1) * @avg_physical_reads_if as iqr, q.med, q.q1, q.q3, mn, mx, av
	--, n01, n02, n03, n04, n05, n06, n07, n08, n09, n10, n11, n12, n13, n14, n15, n16, n17, n18, n19, n20
	from (select 
	  (select max(avg_physical_reads) from ntiles where avg_physical_reads_q = 5) as q1
	, (select max(avg_physical_reads) from ntiles where avg_physical_reads_q = 10) as med
	, (select max(avg_physical_reads) from ntiles where avg_physical_reads_q = 15) as q3
	, (select min(avg_physical_reads) from ntiles) as mn
	, (select max(avg_physical_reads) from ntiles) as mx
	, (select avg(avg_physical_reads) from ntiles) as av
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 1) as n01
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 2) as n02
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 3) as n03
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 4) as n04
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 5) as n05
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 6) as n06
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 7) as n07
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 8) as n08
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 9) as n09
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 10) as n10
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 11) as n11
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 12) as n12
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 13) as n13
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 14) as n14
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 15) as n15
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 16) as n16
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 17) as n17
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 18) as n18
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 19) as n19
	--, (select min(avg_physical_reads) from ntiles where avg_physical_reads_q = 20) as n20
	) as q) as iqr
)
, normal as (
	select 
	  case 
		when base.execution_count < iqr_execution_count.iqr_low then 'LOW' 
		when base.execution_count > iqr_execution_count.iqr_HIGH then 'HIGH' 
		else 'NORMAL' end as execution_count_n
	, case 
		when base.avg_elapsed_time_ms < iqr_avg_elapsed_time_ms.iqr_low then 'LOW' 
		when base.avg_elapsed_time_ms > iqr_avg_elapsed_time_ms.iqr_HIGH then 'HIGH' 
		else 'NORMAL' end as avg_elapsed_time_ms_n
	, case 
		when base.avg_worker_time_ms < iqr_avg_worker_time_ms.iqr_low then 'LOW' 
		when base.avg_worker_time_ms > iqr_avg_worker_time_ms.iqr_HIGH then 'HIGH' 
		else 'NORMAL' end as avg_worker_time_ms_n
	, case 
		when base.avg_rows < iqr_avg_rows.iqr_low then 'LOW' 
		when base.avg_rows > iqr_avg_rows.iqr_HIGH then 'HIGH' 
		else 'NORMAL' end as avg_rows_n
	, case 
		when base.avg_logical_reads < iqr_avg_logical_reads.iqr_low then 'LOW' 
		when base.avg_logical_reads > iqr_avg_logical_reads.iqr_HIGH then 'HIGH' 
		else 'NORMAL' end as avg_logical_reads_n
	, case 
		when base.avg_clr_time_ms < iqr_avg_clr_time_ms.iqr_low then 'LOW' 
		when base.avg_clr_time_ms > iqr_avg_clr_time_ms.iqr_HIGH then 'HIGH' 
		else 'NORMAL' end as avg_clr_time_ms_n
	, case 
		when base.avg_logical_writes < iqr_avg_logical_writes.iqr_low then 'LOW' 
		when base.avg_logical_writes > iqr_avg_logical_writes.iqr_HIGH then 'HIGH' 
		else 'NORMAL' end as avg_logical_writes_n
	, case 
		when base.avg_physical_reads < iqr_avg_physical_reads.iqr_low then 'LOW' 
		when base.avg_physical_reads > iqr_avg_physical_reads.iqr_HIGH then 'HIGH' 
		else 'NORMAL' end as avg_physical_reads_n
	, base.statement_start_offset
	, base.statement_end_offset
	, base.sql_handle
	, base.plan_handle
	, base.execution_count
	, base.avg_elapsed_time_ms / 1000 as avg_elapsed_time_ms
	, base.avg_worker_time_ms / 1000 as avg_worker_time_ms
	, base.avg_rows
	, base.avg_logical_reads
	, base.avg_clr_time_ms / 1000 as avg_clr_time_ms
	, base.avg_logical_writes
	, base.avg_physical_reads
	from #base as base
	cross join iqr_execution_count
	cross join iqr_avg_elapsed_time_ms
	cross join iqr_avg_worker_time_ms
	cross join iqr_avg_rows
	cross join iqr_avg_logical_reads
	cross join iqr_avg_clr_time_ms
	cross join iqr_avg_logical_writes
	cross join iqr_avg_physical_reads
)
, filters as (
	select execution_count
	, avg_elapsed_time_ms
	, avg_worker_time_ms
	, avg_rows
	, avg_logical_reads
	, avg_clr_time_ms
	, avg_logical_writes
	, avg_physical_reads
	, statement_start_offset
	, statement_end_offset
	, sql_handle
	, plan_handle
	from normal
	where 1=1
	AND execution_count_n = coalesce(@execution_count, execution_count_n)
	AND avg_elapsed_time_ms_n = coalesce(@avg_elapsed_time_ms, avg_elapsed_time_ms_n)
	AND avg_worker_time_ms_n = coalesce(@avg_worker_time_ms, avg_worker_time_ms_n)
	AND avg_rows_n = coalesce(@avg_rows, avg_rows_n)
	AND avg_logical_reads_n = coalesce(@avg_logical_reads, avg_logical_reads_n)
	AND avg_clr_time_ms_n = coalesce(@avg_clr_time_ms, avg_clr_time_ms_n)
	AND avg_logical_writes_n = coalesce(@avg_logical_writes, avg_logical_writes_n)
	AND avg_physical_reads_n = coalesce(@avg_physical_reads, avg_physical_reads_n)
)
, plans as (
	select f.avg_clr_time_ms
	, f.avg_elapsed_time_ms
	, f.avg_logical_reads
	, f.avg_logical_writes
	, f.avg_physical_reads
	, f.avg_rows
	, f.avg_worker_time_ms
	, f.execution_count
	, db_name(p.dbid) as database_name
	, object_name(p.objectid, p.dbid) as obj
	, p.query_plan
	from filters f
	cross apply sys.dm_exec_query_plan(f.plan_handle) p
)
, statements as (
	select f.avg_clr_time_ms
	, f.avg_elapsed_time_ms
	, f.avg_logical_reads
	, f.avg_logical_writes
	, f.avg_physical_reads
	, f.avg_rows
	, f.avg_worker_time_ms
	, f.execution_count
	, db_name(t.dbid) as database_name
	, object_name(t.objectid, t.dbid) as obj
	, CASE WHEN f.statement_start_offset > 0 THEN
		CASE WHEN f.statement_end_offset = -1 THEN substring(t.text, (f.statement_start_offset/2) + 1, 2147483647) 
		ELSE substring(t.text, (f.statement_start_offset/2) + 1, ((f.statement_end_offset - f.statement_start_offset)/2)) END
	  ELSE
		CASE WHEN f.statement_end_offset = -1 THEN t.text
		ELSE LEFT(t.text, (f.statement_end_offset/2)+1 ) END
	  END as executing_statement
	from filters f
	cross apply sys.dm_exec_sql_text(f.sql_handle) t
)
, iqr_all as (
	select 'iqr_execution_count' as iqr_category, * 
	, (select count(1) from #base where execution_count >= ((mx / 21) * 0)  and execution_count < ((mx / 21) * 1))  as h00
	, (select count(1) from #base where execution_count >= ((mx / 21) * 1)  and execution_count < ((mx / 21) * 2))  as h01
	, (select count(1) from #base where execution_count >= ((mx / 21) * 2)  and execution_count < ((mx / 21) * 3))  as h02
	, (select count(1) from #base where execution_count >= ((mx / 21) * 3)  and execution_count < ((mx / 21) * 4))  as h03
	, (select count(1) from #base where execution_count >= ((mx / 21) * 4)  and execution_count < ((mx / 21) * 5))  as h04
	, (select count(1) from #base where execution_count >= ((mx / 21) * 5)  and execution_count < ((mx / 21) * 6))  as h05
	, (select count(1) from #base where execution_count >= ((mx / 21) * 6)  and execution_count < ((mx / 21) * 7))  as h06
	, (select count(1) from #base where execution_count >= ((mx / 21) * 7)  and execution_count < ((mx / 21) * 8))  as h07
	, (select count(1) from #base where execution_count >= ((mx / 21) * 8)  and execution_count < ((mx / 21) * 9))  as h08
	, (select count(1) from #base where execution_count >= ((mx / 21) * 9)  and execution_count < ((mx / 21) * 10)) as h09
	, (select count(1) from #base where execution_count >= ((mx / 21) * 10) and execution_count < ((mx / 21) * 11)) as h10
	, (select count(1) from #base where execution_count >= ((mx / 21) * 11) and execution_count < ((mx / 21) * 12)) as h11
	, (select count(1) from #base where execution_count >= ((mx / 21) * 12) and execution_count < ((mx / 21) * 13)) as h12
	, (select count(1) from #base where execution_count >= ((mx / 21) * 13) and execution_count < ((mx / 21) * 14)) as h13
	, (select count(1) from #base where execution_count >= ((mx / 21) * 14) and execution_count < ((mx / 21) * 15)) as h14
	, (select count(1) from #base where execution_count >= ((mx / 21) * 15) and execution_count < ((mx / 21) * 16)) as h15
	, (select count(1) from #base where execution_count >= ((mx / 21) * 16) and execution_count < ((mx / 21) * 17)) as h16
	, (select count(1) from #base where execution_count >= ((mx / 21) * 17) and execution_count < ((mx / 21) * 18)) as h17
	, (select count(1) from #base where execution_count >= ((mx / 21) * 18) and execution_count < ((mx / 21) * 19)) as h18
	, (select count(1) from #base where execution_count >= ((mx / 21) * 19) and execution_count < ((mx / 21) * 20)) as h19
	, (select count(1) from #base where execution_count >= ((mx / 21) * 20)) as h20
	from iqr_execution_count union all
	select 'iqr_avg_clr_time_ms', * 
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 0)  and avg_clr_time_ms < ((mx / 21) * 1))  as h00
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 1)  and avg_clr_time_ms < ((mx / 21) * 2))  as h01
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 2)  and avg_clr_time_ms < ((mx / 21) * 3))  as h02
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 3)  and avg_clr_time_ms < ((mx / 21) * 4))  as h03
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 4)  and avg_clr_time_ms < ((mx / 21) * 5))  as h04
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 5)  and avg_clr_time_ms < ((mx / 21) * 6))  as h05
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 6)  and avg_clr_time_ms < ((mx / 21) * 7))  as h06
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 7)  and avg_clr_time_ms < ((mx / 21) * 8))  as h07
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 8)  and avg_clr_time_ms < ((mx / 21) * 9))  as h08
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 9)  and avg_clr_time_ms < ((mx / 21) * 10)) as h09
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 10) and avg_clr_time_ms < ((mx / 21) * 11)) as h10
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 11) and avg_clr_time_ms < ((mx / 21) * 12)) as h11
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 12) and avg_clr_time_ms < ((mx / 21) * 13)) as h12
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 13) and avg_clr_time_ms < ((mx / 21) * 14)) as h13
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 14) and avg_clr_time_ms < ((mx / 21) * 15)) as h14
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 15) and avg_clr_time_ms < ((mx / 21) * 16)) as h15
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 16) and avg_clr_time_ms < ((mx / 21) * 17)) as h16
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 17) and avg_clr_time_ms < ((mx / 21) * 18)) as h17
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 18) and avg_clr_time_ms < ((mx / 21) * 19)) as h18
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 19) and avg_clr_time_ms < ((mx / 21) * 20)) as h19
	, (select count(1) from #base where avg_clr_time_ms >= ((mx / 21) * 20)) as h20
	from iqr_avg_clr_time_ms union all
	select 'iqr_avg_elapsed_time_ms', * 
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 0)  and avg_elapsed_time_ms < ((mx / 21) * 1))  as h00
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 1)  and avg_elapsed_time_ms < ((mx / 21) * 2))  as h01
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 2)  and avg_elapsed_time_ms < ((mx / 21) * 3))  as h02
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 3)  and avg_elapsed_time_ms < ((mx / 21) * 4))  as h03
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 4)  and avg_elapsed_time_ms < ((mx / 21) * 5))  as h04
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 5)  and avg_elapsed_time_ms < ((mx / 21) * 6))  as h05
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 6)  and avg_elapsed_time_ms < ((mx / 21) * 7))  as h06
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 7)  and avg_elapsed_time_ms < ((mx / 21) * 8))  as h07
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 8)  and avg_elapsed_time_ms < ((mx / 21) * 9))  as h08
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 9)  and avg_elapsed_time_ms < ((mx / 21) * 10)) as h09
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 10) and avg_elapsed_time_ms < ((mx / 21) * 11)) as h10
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 11) and avg_elapsed_time_ms < ((mx / 21) * 12)) as h11
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 12) and avg_elapsed_time_ms < ((mx / 21) * 13)) as h12
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 13) and avg_elapsed_time_ms < ((mx / 21) * 14)) as h13
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 14) and avg_elapsed_time_ms < ((mx / 21) * 15)) as h14
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 15) and avg_elapsed_time_ms < ((mx / 21) * 16)) as h15
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 16) and avg_elapsed_time_ms < ((mx / 21) * 17)) as h16
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 17) and avg_elapsed_time_ms < ((mx / 21) * 18)) as h17
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 18) and avg_elapsed_time_ms < ((mx / 21) * 19)) as h18
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 19) and avg_elapsed_time_ms < ((mx / 21) * 20)) as h19
	, (select count(1) from #base where avg_elapsed_time_ms >= ((mx / 21) * 20)) as h20
	from iqr_avg_elapsed_time_ms union all
	select 'iqr_avg_logical_reads', * 
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 0)  and avg_logical_reads < ((mx / 21) * 1))  as h00
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 1)  and avg_logical_reads < ((mx / 21) * 2))  as h01
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 2)  and avg_logical_reads < ((mx / 21) * 3))  as h02
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 3)  and avg_logical_reads < ((mx / 21) * 4))  as h03
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 4)  and avg_logical_reads < ((mx / 21) * 5))  as h04
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 5)  and avg_logical_reads < ((mx / 21) * 6))  as h05
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 6)  and avg_logical_reads < ((mx / 21) * 7))  as h06
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 7)  and avg_logical_reads < ((mx / 21) * 8))  as h07
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 8)  and avg_logical_reads < ((mx / 21) * 9))  as h08
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 9)  and avg_logical_reads < ((mx / 21) * 10)) as h09
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 10) and avg_logical_reads < ((mx / 21) * 11)) as h10
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 11) and avg_logical_reads < ((mx / 21) * 12)) as h11
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 12) and avg_logical_reads < ((mx / 21) * 13)) as h12
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 13) and avg_logical_reads < ((mx / 21) * 14)) as h13
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 14) and avg_logical_reads < ((mx / 21) * 15)) as h14
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 15) and avg_logical_reads < ((mx / 21) * 16)) as h15
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 16) and avg_logical_reads < ((mx / 21) * 17)) as h16
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 17) and avg_logical_reads < ((mx / 21) * 18)) as h17
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 18) and avg_logical_reads < ((mx / 21) * 19)) as h18
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 19) and avg_logical_reads < ((mx / 21) * 20)) as h19
	, (select count(1) from #base where avg_logical_reads >= ((mx / 21) * 20)) as h20
	from iqr_avg_logical_reads union all
	select 'iqr_avg_logical_writes', * 
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 0)  and avg_logical_writes < ((mx / 21) * 1))  as h00
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 1)  and avg_logical_writes < ((mx / 21) * 2))  as h01
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 2)  and avg_logical_writes < ((mx / 21) * 3))  as h02
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 3)  and avg_logical_writes < ((mx / 21) * 4))  as h03
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 4)  and avg_logical_writes < ((mx / 21) * 5))  as h04
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 5)  and avg_logical_writes < ((mx / 21) * 6))  as h05
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 6)  and avg_logical_writes < ((mx / 21) * 7))  as h06
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 7)  and avg_logical_writes < ((mx / 21) * 8))  as h07
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 8)  and avg_logical_writes < ((mx / 21) * 9))  as h08
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 9)  and avg_logical_writes < ((mx / 21) * 10)) as h09
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 10) and avg_logical_writes < ((mx / 21) * 11)) as h10
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 11) and avg_logical_writes < ((mx / 21) * 12)) as h11
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 12) and avg_logical_writes < ((mx / 21) * 13)) as h12
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 13) and avg_logical_writes < ((mx / 21) * 14)) as h13
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 14) and avg_logical_writes < ((mx / 21) * 15)) as h14
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 15) and avg_logical_writes < ((mx / 21) * 16)) as h15
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 16) and avg_logical_writes < ((mx / 21) * 17)) as h16
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 17) and avg_logical_writes < ((mx / 21) * 18)) as h17
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 18) and avg_logical_writes < ((mx / 21) * 19)) as h18
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 19) and avg_logical_writes < ((mx / 21) * 20)) as h19
	, (select count(1) from #base where avg_logical_writes >= ((mx / 21) * 20)) as h20
	from iqr_avg_logical_writes union all
	select 'iqr_avg_physical_reads', * 
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 0)  and avg_physical_reads < ((mx / 21) * 1))  as h00
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 1)  and avg_physical_reads < ((mx / 21) * 2))  as h01
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 2)  and avg_physical_reads < ((mx / 21) * 3))  as h02
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 3)  and avg_physical_reads < ((mx / 21) * 4))  as h03
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 4)  and avg_physical_reads < ((mx / 21) * 5))  as h04
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 5)  and avg_physical_reads < ((mx / 21) * 6))  as h05
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 6)  and avg_physical_reads < ((mx / 21) * 7))  as h06
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 7)  and avg_physical_reads < ((mx / 21) * 8))  as h07
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 8)  and avg_physical_reads < ((mx / 21) * 9))  as h08
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 9)  and avg_physical_reads < ((mx / 21) * 10)) as h09
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 10) and avg_physical_reads < ((mx / 21) * 11)) as h10
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 11) and avg_physical_reads < ((mx / 21) * 12)) as h11
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 12) and avg_physical_reads < ((mx / 21) * 13)) as h12
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 13) and avg_physical_reads < ((mx / 21) * 14)) as h13
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 14) and avg_physical_reads < ((mx / 21) * 15)) as h14
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 15) and avg_physical_reads < ((mx / 21) * 16)) as h15
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 16) and avg_physical_reads < ((mx / 21) * 17)) as h16
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 17) and avg_physical_reads < ((mx / 21) * 18)) as h17
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 18) and avg_physical_reads < ((mx / 21) * 19)) as h18
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 19) and avg_physical_reads < ((mx / 21) * 20)) as h19
	, (select count(1) from #base where avg_physical_reads >= ((mx / 21) * 20)) as h20
	from iqr_avg_physical_reads union all
	select 'iqr_avg_rows', * 
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 0)  and avg_rows < ((mx / 21) * 1))  as h00
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 1)  and avg_rows < ((mx / 21) * 2))  as h01
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 2)  and avg_rows < ((mx / 21) * 3))  as h02
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 3)  and avg_rows < ((mx / 21) * 4))  as h03
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 4)  and avg_rows < ((mx / 21) * 5))  as h04
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 5)  and avg_rows < ((mx / 21) * 6))  as h05
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 6)  and avg_rows < ((mx / 21) * 7))  as h06
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 7)  and avg_rows < ((mx / 21) * 8))  as h07
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 8)  and avg_rows < ((mx / 21) * 9))  as h08
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 9)  and avg_rows < ((mx / 21) * 10)) as h09
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 10) and avg_rows < ((mx / 21) * 11)) as h10
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 11) and avg_rows < ((mx / 21) * 12)) as h11
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 12) and avg_rows < ((mx / 21) * 13)) as h12
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 13) and avg_rows < ((mx / 21) * 14)) as h13
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 14) and avg_rows < ((mx / 21) * 15)) as h14
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 15) and avg_rows < ((mx / 21) * 16)) as h15
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 16) and avg_rows < ((mx / 21) * 17)) as h16
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 17) and avg_rows < ((mx / 21) * 18)) as h17
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 18) and avg_rows < ((mx / 21) * 19)) as h18
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 19) and avg_rows < ((mx / 21) * 20)) as h19
	, (select count(1) from #base where avg_rows >= ((mx / 21) * 20)) as h20
	from iqr_avg_rows union all
	select 'iqr_avg_worker_time_ms', * 
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 0)  and avg_worker_time_ms < ((mx / 21) * 1))  as h00
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 1)  and avg_worker_time_ms < ((mx / 21) * 2))  as h01
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 2)  and avg_worker_time_ms < ((mx / 21) * 3))  as h02
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 3)  and avg_worker_time_ms < ((mx / 21) * 4))  as h03
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 4)  and avg_worker_time_ms < ((mx / 21) * 5))  as h04
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 5)  and avg_worker_time_ms < ((mx / 21) * 6))  as h05
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 6)  and avg_worker_time_ms < ((mx / 21) * 7))  as h06
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 7)  and avg_worker_time_ms < ((mx / 21) * 8))  as h07
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 8)  and avg_worker_time_ms < ((mx / 21) * 9))  as h08
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 9)  and avg_worker_time_ms < ((mx / 21) * 10)) as h09
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 10) and avg_worker_time_ms < ((mx / 21) * 11)) as h10
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 11) and avg_worker_time_ms < ((mx / 21) * 12)) as h11
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 12) and avg_worker_time_ms < ((mx / 21) * 13)) as h12
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 13) and avg_worker_time_ms < ((mx / 21) * 14)) as h13
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 14) and avg_worker_time_ms < ((mx / 21) * 15)) as h14
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 15) and avg_worker_time_ms < ((mx / 21) * 16)) as h15
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 16) and avg_worker_time_ms < ((mx / 21) * 17)) as h16
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 17) and avg_worker_time_ms < ((mx / 21) * 18)) as h17
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 18) and avg_worker_time_ms < ((mx / 21) * 19)) as h18
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 19) and avg_worker_time_ms < ((mx / 21) * 20)) as h19
	, (select count(1) from #base where avg_worker_time_ms >= ((mx / 21) * 20)) as h20
	from iqr_avg_worker_time_ms 
)
, iqr_all_h as (
	select *, mx/21 as h_size 
	from iqr_all
)

	select * from iqr_all_h
/*
	select * from iqr_all_h
	select * from statements
	select * from filters
	select * from plans
*/

drop table #base

