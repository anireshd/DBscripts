-- Gather missing index data for the current database
SELECT  SCHEMA_NAME(t.schema_id) AS [schema], t.name 'table', 
        ( avg_total_user_cost * avg_user_impact ) * ( user_seeks + user_scans ) AS 'impact',
        'CREATE NONCLUSTERED INDEX ix_IndexName ON ' + SCHEMA_NAME(t.schema_id)
        + '.' + t.name COLLATE DATABASE_DEFAULT + ' ('
        + ISNULL(d.equality_columns, '')
        + CASE WHEN d.inequality_columns IS NULL THEN ''
               ELSE CASE WHEN d.equality_columns IS NULL THEN ''
                         ELSE ','
                    END + d.inequality_columns
          END + ') ' +
          CASE WHEN d.included_columns IS NULL THEN ''
               ELSE 'INCLUDE (' + d.included_columns + ')'
          END + ';' AS 'create_index_statement', d.equality_columns,
        d.inequality_columns, d.included_columns
FROM    sys.dm_db_missing_index_group_stats AS s
        INNER JOIN sys.dm_db_missing_index_groups AS g ON s.group_handle = g.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details AS d ON g.index_handle = d.index_handle 
        INNER JOIN sys.tables t WITH ( NOLOCK ) ON d.OBJECT_ID = t.OBJECT_ID
WHERE   d.database_id = DB_ID() AND
		s.group_handle IN ( SELECT TOP 500 group_handle
							FROM  sys.dm_db_missing_index_group_stats WITH ( NOLOCK )
							ORDER BY ( avg_total_user_cost * avg_user_impact ) * 
							         ( user_seeks + user_scans ) DESC ) 
--		AND t.object_id = object_id('dbo.Person')		/* Optionally filter by table */
ORDER BY ( avg_total_user_cost * avg_user_impact ) * ( user_seeks + user_scans ) DESC;

/*
	I like to start by running the query against the entire database.  I'll identify a table 
	that seems to need work (high impact missing indexes) and run it a second time looking at
	just that table (see the commented out line in the where clause).  There are typically 
	multiple missing indexes on problematic tables.

	Then I'll try to distill which columns most need indexes and focus on those.  I'm trying 
	to get a bigger picture with this approach.  I don't want to create a new index only to 
	find that had I added one column to an INCLUDE clause I could have addressed multiple 
	problem queries.

*/