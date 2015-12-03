SELECT
	OBJECT_NAME(resource_associated_entity_id, dtl.resource_database_id),
	dtl.resource_subtype,
	dtl.request_mode,
	dtl.request_session_id,
	DB_NAME(dtl.resource_database_id) AS database_name
FROM sys.dm_tran_locks dtl
WHERE dtl.resource_type = 'OBJECT'
