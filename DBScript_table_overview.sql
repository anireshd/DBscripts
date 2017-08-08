WITH ColCount 
AS 
( SELECT object_id, COUNT(column_id) AS 'col_cnt' 
  FROM sys.columns
  GROUP BY object_id)
SELECT  CASE WHEN i.index_id IN ( 0, 1 ) THEN SCHEMA_NAME(t.schema_id) + '.' + t.name ELSE '           "' END AS 'schema.table', 
		i.name, p.partition_number AS 'part_num',
		CASE i.index_id
			WHEN 0 THEN 'Heap'
            WHEN 1 THEN 'Clustered'
            ELSE 'Index'
        END AS 'type', 
		CASE i.is_primary_key WHEN 1 THEN 'Y' ELSE ''END AS 'PK', 
		CASE i.is_unique WHEN 1 THEN 'Y' ELSE '' END AS 'unique',
		--i.is_unique_constraint AS 'unique_cnst',
		CASE WHEN i.index_id IN ( 0, 1 ) THEN CAST(c.col_cnt AS VARCHAR(5)) ELSE '' END AS 'columns',
        CASE WHEN i.index_id IN ( 0, 1 ) OR (i.has_filter = 1) THEN CAST(p.ROWS AS VARCHAR(20)) ELSE '' END AS 'rows',
        STR(s.in_row_reserved_page_count / 128.0, 10, 2) AS 'IN-Row MB',
        STR(s.lob_reserved_page_count / 128.0, 10, 2) AS 'LOB MB',
        STR(s.row_overflow_reserved_page_count / 128.0, 10, 2) AS 'Overflow MB',
		i.fill_factor, 
		CASE i.has_filter WHEN 1 THEN 'Y' ELSE ''END AS 'filtered', 
        REPLACE(p.data_compression_desc, 'NONE', '') AS 'compresssion',         /* Need to comment out this line for 2005 */
		CASE i.is_disabled WHEN 1 THEN 'Y' ELSE ''END AS 'disabled',
		COALESCE((u.user_seeks + u.user_scans + u.user_lookups),0) AS 'ix_reads', 
	    COALESCE(u.user_updates,0) AS 'ix_writes'
FROM    sys.tables t
		INNER JOIN ColCount c ON c.object_id = t.object_id
        INNER JOIN sys.indexes i ON i.object_id = t.object_id
		LEFT OUTER JOIN sys.dm_db_index_usage_stats u ON i.object_id = u.object_id AND i.index_id = u.index_id AND database_id = DB_ID()
		INNER JOIN sys.partitions p ON p.object_id = i.object_id AND p.index_id = i.index_id
        INNER JOIN sys.dm_db_partition_stats s ON s.partition_id = p.partition_id AND s.partition_number = p.partition_number
WHERE   t.is_ms_shipped = 0 
		--AND t.object_id = OBJECT_ID('dbo.CI_ConfigurationItems')   /* Optionally filter by object */
ORDER BY SCHEMA_NAME(t.schema_id), t.name, i.index_id, p.partition_number;


/*
	What to look for...

	How are the tables organized?  
		- Do we have multiple schemas
		- Are the table names clear
		- Can you tell columns are in the indexes

	Is there a unique primary key on every table?

	Do all tables have clustered indexes?

	How big are the tables?  
		- Row counts (optimize the big ones first)
		- Column counts (narrow tables perform better)
		- MB (watch out for lots of LOB or row overflow storage)

	Is Fill Factor frequently used?
		This is generally a bad idea
		It's one good use is to help lessen excessive page splits

	Do we have filtered indexes?
		Indexes built with WHERE clauses
		May not get stats updated automatically often enough

	Are there disabled indexes?
		Nice way to "drop" and index while saving it's definition
		REBUILD to put back in use
		Don't disable your clustered index - it disables access to your table

	Are we using compression?
		Awesome way to save storage space and reduce IO
		Costs some CPU to do the compressing
		Less good for heavily used data
		Adjust index maintenance scripts so REBUILDS use it

	Are we using our indexes?
		Want to see reads >> writes

*/

