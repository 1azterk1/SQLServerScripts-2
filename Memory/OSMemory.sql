SELECT total_physical_memory_kb / 1024 AS total_physical_memory_mb ,
 available_physical_memory_kb / 1024 AS available_physical_memory_mb ,
 total_page_file_kb / 1024 AS total_page_file_mb ,
 available_page_file_kb / 1024 AS available_page_file_mb ,
 system_memory_state_desc
FROM sys.dm_os_sys_memory
