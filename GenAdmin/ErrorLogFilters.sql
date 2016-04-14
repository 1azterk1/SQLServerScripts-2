declare 
  @p1 int /* Error log sequence number where 0 is latest */
, @p2 int /* Error log type (1:errorlog; 2:agent log) */
, @p3 nvarchar(4000) /* search term 1 */
, @p4 nvarchar(4000) /* search term 2 */
, @p5 datetime /* Start time */ 
, @p6 datetime /* End time */ 
, @p7 nvarchar(10) /* List Direction (ASC or DESC)*/;

select @p1 = 0
, @p2 = 1
, @p3 = null
, @p4 = null
, @p5 = dateadd(hh, -5, GETDATE())
, @p6 = GETDATE()
, @p7 = 'DESC';

exec xp_readerrorlog @p1, @p2, @p3, @p4, @p5, @p6, @p7;

