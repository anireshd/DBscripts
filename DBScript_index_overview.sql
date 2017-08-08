SET NOCOUNT ON;

-- Create an empty temp table
SELECT  t.schema_id, t.object_id, i.name, i.index_id, i.type_desc, i.is_unique, i.is_primary_key,
        CAST(NULL AS VARCHAR(1000)) AS 'key_cols',
        CAST(NULL AS VARCHAR(1000)) AS 'included_cols', i.fill_factor,
        i.filter_definition
INTO    #indexes
FROM    sys.tables t INNER JOIN sys.indexes i ON i.object_id = t.object_id
WHERE   1 = 2;
go

-- Populate it with basic index information (excludes XML, Spatial, ColumnStore and Hash index types)
INSERT  INTO #indexes ( schema_id, object_id, name, index_id, type_desc,
                        is_unique, is_primary_key, key_cols, included_cols,
                        fill_factor, filter_definition )
SELECT  t.schema_id, t.object_id, i.name, i.index_id, i.type_desc, i.is_unique,
        i.is_primary_key, CAST(NULL AS VARCHAR(1000)) AS 'key_cols',
        CAST(NULL AS VARCHAR(1000)) AS 'included_cols', i.fill_factor,
        i.filter_definition
FROM    sys.tables t
        INNER JOIN sys.indexes i ON i.object_id = t.object_id
WHERE   t.is_ms_shipped = 0 AND
		i.is_disabled = 0 AND
        --i.object_id = OBJECT_ID('Person.Address') AND  /* optionally filter by table */
        i.type_desc IN ( 'HEAP', 'CLUSTERED', 'NONCLUSTERED' );
GO

DECLARE my_indexes CURSOR
FOR
SELECT object_id, index_id
FROM    #indexes
FOR READ ONLY;
go

DECLARE @object_id INT,
		@index_id INT,
		@indexed_cols VARCHAR(1000),
		@included_cols VARCHAR(2000);
		
-- Open the cursor and retrieve the first value(s)
OPEN my_indexes;
FETCH my_indexes INTO @object_id, @index_id;

WHILE (@@fetch_status = 0) 
BEGIN
	-- Grab the indexed columns
    SELECT  @indexed_cols = ISNULL(@indexed_cols + ', ', '') + c.name
    FROM    sys.index_columns ic
            INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE   ic.is_included_column = 0 AND
            ic.object_id = @object_id AND
            ic.index_id = @index_id
    ORDER BY ic.key_ordinal;

    UPDATE  #indexes
    SET     key_cols = @indexed_cols
    WHERE   object_id = @object_id AND index_id = @index_id;

	SET @indexed_cols = NULL;

	-- Grab the included columns
	select @included_cols = IsNull(@included_cols + ', ','') + c.name
	FROM sys.index_columns ic INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id 
	WHERE ic.is_included_column = 1 and ic.object_id = @object_id AND index_id = @index_id;
	
	--SELECT @included_cols
	UPDATE #indexes SET included_cols = @included_cols WHERE object_id = @object_id AND index_id = @index_id;
	SET @included_cols = NULL;

	-- Get the next value(s)
    FETCH my_indexes INTO @object_id, @index_id
END

CLOSE my_indexes;
DEALLOCATE my_indexes;
GO 

SELECT  SCHEMA_NAME(i.schema_id) + '.' + OBJECT_NAME(i.object_id) AS 'schema.table',
        i.name, i.index_id, i.type_desc, CASE i.is_primary_key
                                           WHEN 1 THEN 'PK'
                                           ELSE ''
                                         END AS is_primary_key,
        CASE i.is_unique
          WHEN 1 THEN 'UNIQUE'
          ELSE ''
        END AS 'is_unique', i.key_cols, i.included_cols, i.fill_factor,
        i.filter_definition,
        STR(s.avg_fragmentation_in_percent, 5, 2) AS 'avg_frag', s.page_count
FROM    #indexes i
        CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), i.object_id, i.index_id, NULL, 'LIMITED') s 
		--INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) s ON s.object_id = i.object_id AND s.index_id = i.index_id   /* 2008 [R2] */
WHERE   s.alloc_unit_type_desc = N'IN_ROW_DATA'
ORDER BY SCHEMA_NAME(i.schema_id), OBJECT_NAME(i.object_id);		
--ORDER BY i.key_cols;    /* helpful when looking for duplicates */
GO

DROP TABLE #indexes;
go

/*
	What to look for...

	All tables should have a Primary Key
		This is your unique handle for each row in the table.  
		Remember that the Primary Key doesn't have to be your Clustered Index

	All/most tables should have clustered indexes
		Heaps are advantageous when you've got to load lots of data fast
		But to work efficiently with the data afterwards, you'll need indexes

	The Clustered Indexes should be NUSE:
		Narrow  (EmployeeID, not LastName + FirstName + MiddleName + DOB)
		Unique  (SSN, not LastName + FirstName)
		Static  (NetworkId, not CurrentJobID + LastName)
		Ever-increasing  (Identity - good, GUID - bad)

	No more than around 5 indexes on an OLTP table
		As table data changes the table's indexes must be kept in sync.
		This incurs additional writes which can slow transactions and impact 
		the performance of a busy transactionsal system.
	
	Are Unique indexes in use?  
		Use them when you have natually unique data values:  SSN, Employee Ids, 
		email addresses, Network Ids, etc. 
		They help with data integrity and can help the Query Optimizer formulate
		better plans.

	Are included columns being used?  
		They're a great way to "cover" queries (saving the extra IO of Look Ups).
		If they're infrequent/absent look for index tuning opportunities.

	Fill Factor should seldom be something other than 0
		Using a fill factor can help in situations where indexes are becoming
		very fragmented very quickly.  Otherwise, you're just wasting space
		and increasing IO.

	Are filtered indexes being used?  They're helpful with skewed data or when 
		a column contains a lot of NULLs

	A clear, consistently used naming convention
	I like to be able to deciper what the index is on from its name.  It's also 
	helpful to use prefix charters to identify special indexes:
		PK_TableName (primary key)
		AK_MedicalRecordNumber (alternate key)
		u_SocialSecurityNumber (unique index)
		f_CustomerDiscount (filtered index)	
*/

