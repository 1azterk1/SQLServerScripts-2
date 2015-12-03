set transaction isolation level read uncommitted
-- Get total buffer usage by database
SELECT DB_NAME(database_id) AS [Database Name] ,
 COUNT(*) * 8 / 1024.0 AS [Cached Size (MB)]
FROM sys.dm_os_buffer_descriptors
WHERE database_id > 0--4 -- include/exclude system databases
 -- AND database_id <> 32767 -- include/exclude ResourceDB
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC ;
