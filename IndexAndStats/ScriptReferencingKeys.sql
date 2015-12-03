declare @ref_obj nvarchar(255) = N'[dbo].[tbl]';
WITH RefColumns AS
(
       SELECT
              C.referenced_object_id AS [object_id],
              C.parent_object_id,
              STUFF((SELECT ', ' + QUOTENAME(B.name)
                     FROM sys.foreign_key_columns A 
                           JOIN sys.columns B ON B.[object_id] = A.referenced_object_id AND B.column_id = A.referenced_column_id
                           WHERE C.parent_object_id = A.parent_object_id AND C.referenced_object_id = A.referenced_object_id
                           FOR XML PATH('')), 1, 2, '') AS ColumnNames
       FROM sys.foreign_key_columns C
       GROUP BY C.referenced_object_id, C.parent_object_id
)
,ParentColumns AS
(
       SELECT
              C.parent_object_id AS [object_id],
              C.referenced_object_id,
              STUFF((SELECT ', ' + QUOTENAME(B.name)
                     FROM sys.foreign_key_columns A 
                           JOIN sys.columns B ON B.[object_id] = A.parent_object_id AND B.column_id = A.parent_column_id
                           WHERE C.parent_object_id = A.parent_object_id AND C.referenced_object_id = A.referenced_object_id
                           FOR XML PATH('')), 1, 2, '') AS ColumnNames
       FROM sys.foreign_key_columns C
       GROUP BY C.parent_object_id, C.referenced_object_id
)

SELECT
       'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(PT.[schema_id])) + '.' + QUOTENAME(PT.name) + ' DROP  CONSTRAINT' + ' ' + QUOTENAME(FK.name) AS [DropFKScript],
       'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(PT.[schema_id])) + '.' + QUOTENAME(PT.name) + ' WITH CHECK ADD  CONSTRAINT '+ QUOTENAME(FK.name) + CHAR(13) + CHAR(10) +
       'FOREIGN KEY(' + PC.ColumnNames + ')' + CHAR(13) + CHAR(10) + 
	   'REFERENCES ' + QUOTENAME(SCHEMA_NAME(RT.[schema_id])) + '.' + QUOTENAME(RT.name) + ' (' + RC.ColumnNames + ')' + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10) +
       'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(PT.[schema_id])) + '.' + 
       QUOTENAME(PT.name) + ' CHECK CONSTRAINT ' + QUOTENAME(FK.name) + CHAR(13) + CHAR(10) + 'GO' + CHAR(13) + CHAR(10)
       AS [CreateFKScript]
FROM sys.foreign_keys FK   
       JOIN sys.tables PT ON PT.[object_id] = FK.parent_object_id
       JOIN ParentColumns AS PC ON PC.[object_id] = FK.parent_object_id AND PC.referenced_object_id = FK.referenced_object_id
       JOIN sys.tables RT ON RT.[object_id] = FK.referenced_object_id
       JOIN RefColumns AS RC ON RC.[object_id] = FK.referenced_object_id AND RC.parent_object_id = FK.parent_object_id
WHERE RT.name = 'tbl'
       --RT.name = 'tbl'
ORDER BY PT.name
GO
