SELECT physical_memory_in_use_kb ,
 virtual_address_space_committed_kb ,
 virtual_address_space_available_kb ,
 page_fault_count ,
 process_physical_memory_low ,
 process_virtual_memory_low
FROM sys.dm_os_process_memory
