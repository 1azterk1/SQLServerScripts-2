-- DBCC SQLPERF ('sys.dm_os_latch_stats', CLEAR);

SELECT latch_class ,
 waiting_requests_count AS waitCount ,
 wait_time_ms AS waitTime ,
 max_wait_time_ms AS maxWait
FROM sys.dm_os_latch_stats
ORDER BY wait_time_ms DESC
