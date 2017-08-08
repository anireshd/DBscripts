/*
	Indexes facilitate reads  
		They order information so we can quickly locate specific data in a table with 
		minimal IO.  The alternative to using an index is a table scan.
	
		Clustered indexes order the actual data in our tables (as in a phone book 
		or encyclopedia), and nonclustered indexes order subsets of the table's data 
		that are likely to be used in queries (eg, main ingredients and recipe names 
		in a cookbook's index) and include pointers back to the base data (the page 
		numbers in our cookbook).

	Indexes negatively impact writes
		Think about our cookbook.  If we want to add a new recipe or drop an unpopular 
		one we need to revise its index.  If we update a recipe to include a new 
		ingredient we'll also need to update the index.  

		The same goes for our SQL Server indexes.  Inserts, updates and deletes will 
		all necessitate updates to the relevant indexes.  The more indexes, the more
		updates.  So..
	
	Periodically review index usage in your databases
		- Optimally an index is heavily used for reads and infrequently updated.
		- Consider dropping indexes that are never or seldom used.
		- Monitor usage over the course of a business cycle to avoid dropping a
		  critical but infrequently used index.
		- Ensure you aren't violating vendor SLAs if you drop indexes.
		- Script out indexes before dropping them - just in case.
		- If an index has high writes can it be dropped during data loads or
		  times of heavy updates then rebuilt afterwards?
		- If you expected an index to be used can you figure out why it isn't?
		  Would an additional key column or INCLUDED columns help?
		  Is it a duplicate or subset of another (used) index?
		- Consider very carefully before dropping clustered indexes, unique
		  indexes, or those implemented as Primary Key constraints.
			  
	I typically use this query when I'm tuning indexes on a particular table.
	Before adding new indexes I like to check whether the existing indexes are 
	being used, and and sometimes you can make a small modification to an unused 
	index to fulfill the need for a "missing" index.
	
	I'll also run it to monitor usage of new or modified indexes.  Sometimes 
	you'll miss the mark and will need to INCLUDE an additional column or adjust 
	the key column order before the Optimizer will choose to use it.
*/

-- Index usage statistics since the last SQL Server restart
WITH    RowCounts
          AS ( SELECT   object_id, p.index_id, SUM(p.rows) AS row_count
               FROM     sys.partitions p
               GROUP BY object_id, p.index_id
             )
    SELECT  SCHEMA_NAME(t.schema_id) + '.' + t.name AS schema_object_name,
            COALESCE(i.name, '') + 
			CASE i.is_primary_key WHEN 0 THEN '' ELSE '  (PK)' END + 
			CASE i.is_unique WHEN 0 THEN '' ELSE ' (Unique)' END AS index_name, 
            CASE i.index_id
              WHEN 0 THEN N'Heap'	/* Heap */
              WHEN 1 THEN N'CL'		/* Clustered Index */
              ELSE N'NC'			/* Nonclustered Index */
            END AS type, r.row_count, u.user_seeks, u.user_scans, u.user_lookups,
            ( u.user_seeks + u.user_scans + u.user_lookups ) AS read_count,
            u.user_updates AS write_count, u.last_user_seek, u.last_user_scan,
            u.last_user_lookup, u.last_user_update
    FROM    sys.dm_db_index_usage_stats u
            RIGHT OUTER JOIN sys.indexes i ON u.object_id = i.object_id AND
                                              u.index_id = i.index_id
            INNER JOIN sys.tables t ON t.object_id = i.object_id
            INNER JOIN RowCounts r ON i.object_id = r.object_id AND
                                      i.index_id = r.index_id
    WHERE   i.type_desc IN ( N'HEAP', N'CLUSTERED', N'NONCLUSTERED' ) 
--		    AND i.object_id = OBJECT_ID('Person.Person')	/* optionally filter results by object */
    ORDER BY schema_object_name, i.index_id;

/*
	Note:  If an index is read multiple times by one query (e.g., the clustered
	index during Key Lookups) you'll only see the "reads" count increment by 1, 
	not the number of times the index was actually read.
*/
