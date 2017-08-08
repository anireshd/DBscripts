/*
	Compiling a query plan is a costly thing to do, so SQL Server caches plans for reuse.
	For each cached plan it also stores execution statistics for the individual executable 
	statements that comprise the stored procedure, prepared SQL or T-SQL batch.

	We can tap into these statistics to try to find costly statements that might benefit 
	from query or index tuning.

	Below is a series of queries you can use to find the top most costly statements in terms 
	of average logical reads, CPU time, execution time, and total statement executions.

	You'll notice they all look pretty similar.  Each varies only in the column used in the 
	ORDER BY clause.

*/

SET NOCOUNT ON;

-- Highest average logical reads
SELECT  CASE st.dbid WHEN 32767 THEN 'resourcedb' WHEN NULL THEN 'NA' ELSE DB_NAME(st.dbid) END AS 'db_name',
        object_name(st.objectid) AS object_name, SUBSTRING(st.text, ( qs.statement_start_offset / 2 ) + 1,
                  ( ( CASE qs.statement_end_offset
                        WHEN -1 THEN DATALENGTH(st.text)
                        ELSE qs.statement_end_offset
                      END - qs.statement_start_offset ) / 2 ) + 1) AS 'SQL statements with highest average logical reads',
        qs.exec_cnt, qs.avg_CPU_ms, qs.avg_time_ms, qs.avg_logical_reads,
        qs.avg_logical_writes, qp.query_plan
FROM    ( SELECT TOP 10 
                    plan_handle, statement_start_offset, statement_end_offset,
                    execution_count AS 'exec_cnt',
                    total_worker_time / ( execution_count * 1000 ) AS 'avg_CPU_ms',
                    ( total_elapsed_time / ( execution_count * 1000 ) ) AS 'avg_time_ms',
                    CASE WHEN total_logical_reads > 0
                         THEN ( total_logical_reads / execution_count )
                         ELSE 0
                    END AS 'avg_logical_reads',
                    CASE WHEN total_logical_writes > 0
                         THEN ( total_logical_writes / execution_count )
                         ELSE 0
                    END AS 'avg_logical_writes'
          FROM      sys.dm_exec_query_stats
          ORDER BY  ( total_logical_reads / execution_count ) DESC
        ) AS qs
        CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.avg_logical_reads DESC;	
GO

-- Highest Average CPU
SELECT  CASE st.dbid WHEN 32767 THEN 'resourcedb' WHEN NULL THEN 'NA' ELSE DB_NAME(st.dbid) END AS 'db_name',
        object_name(st.objectid) AS object_name, SUBSTRING(st.text, ( qs.statement_start_offset / 2 ) + 1,
                  ( ( CASE qs.statement_end_offset
                        WHEN -1 THEN DATALENGTH(st.text)
                        ELSE qs.statement_end_offset
                      END - qs.statement_start_offset ) / 2 ) + 1) AS 'SQL statements with highest average CPU',
        qs.exec_cnt, qs.avg_CPU_ms, qs.avg_time_ms, qs.avg_logical_reads,
        qs.avg_logical_writes, qp.query_plan
FROM    ( SELECT TOP 10
                    plan_handle, statement_start_offset, statement_end_offset,
                    execution_count AS 'exec_cnt',
                    total_worker_time / ( execution_count * 1000 ) AS 'avg_CPU_ms',
                    ( total_elapsed_time / ( execution_count * 1000 ) ) AS 'avg_time_ms',
                    CASE WHEN total_logical_reads > 0
                         THEN ( total_logical_reads / execution_count )
                         ELSE 0
                    END AS 'avg_logical_reads',
                    CASE WHEN total_logical_writes > 0
                         THEN ( total_logical_writes / execution_count )
                         ELSE 0
                    END AS 'avg_logical_writes'
          FROM      sys.dm_exec_query_stats
          ORDER BY  ( total_worker_time / execution_count ) DESC
        ) AS qs
        CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.avg_CPU_ms DESC;	
GO

-- Slowest avg exec times
SELECT  CASE st.dbid WHEN 32767 THEN 'resourcedb' WHEN NULL THEN 'NA' ELSE DB_NAME(st.dbid) END AS 'db_name',
        object_name(st.objectid) AS object_name, SUBSTRING(st.text, ( qs.statement_start_offset / 2 ) + 1,
                  ( ( CASE qs.statement_end_offset
                        WHEN -1 THEN DATALENGTH(st.text)
                        ELSE qs.statement_end_offset
                      END - qs.statement_start_offset ) / 2 ) + 1) AS 'SQL statements with longest average execution times',
        qs.exec_cnt, qs.avg_CPU_ms, qs.avg_time_ms, qs.avg_logical_reads,
        qs.avg_logical_writes, qp.query_plan
FROM    ( SELECT TOP 10
                    plan_handle, statement_start_offset, statement_end_offset,
                    execution_count AS 'exec_cnt',
                    total_worker_time / ( execution_count * 1000 ) AS 'avg_CPU_ms',
                    ( total_elapsed_time / ( execution_count * 1000 ) ) AS 'avg_time_ms',
                    CASE WHEN total_logical_reads > 0
                         THEN ( total_logical_reads / execution_count )
                         ELSE 0
                    END AS 'avg_logical_reads',
                    CASE WHEN total_logical_writes > 0
                         THEN ( total_logical_writes / execution_count )
                         ELSE 0
                    END AS 'avg_logical_writes'
          FROM      sys.dm_exec_query_stats
          ORDER BY  ( total_elapsed_time / execution_count ) DESC
        ) AS qs
        CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.avg_time_ms DESC;	
GO

-- Highest execution counts
SELECT  CASE st.dbid WHEN 32767 THEN 'resourcedb' WHEN NULL THEN 'NA' ELSE DB_NAME(st.dbid) END AS 'db_name',
        object_name(st.objectid) AS object_name, SUBSTRING(st.text, ( qs.statement_start_offset / 2 ) + 1,
                  ( ( CASE qs.statement_end_offset
                        WHEN -1 THEN DATALENGTH(st.text)
                        ELSE qs.statement_end_offset
                      END - qs.statement_start_offset ) / 2 ) + 1) AS 'SQL statements with highest average execution counts',
        qs.exec_cnt, qs.avg_CPU_ms, qs.avg_time_ms, qs.avg_logical_reads,
        qs.avg_logical_writes, qp.query_plan
FROM    ( SELECT TOP 10
                    plan_handle, statement_start_offset, statement_end_offset,
                    execution_count AS 'exec_cnt',
                    total_worker_time / ( execution_count * 1000 ) AS 'avg_CPU_ms',
                    ( total_elapsed_time / ( execution_count * 1000 ) ) AS 'avg_time_ms',
                    CASE WHEN total_logical_reads > 0
                         THEN ( total_logical_reads / execution_count )
                         ELSE 0
                    END AS 'avg_logical_reads',
                    CASE WHEN total_logical_writes > 0
                         THEN ( total_logical_writes / execution_count )
                         ELSE 0
                    END AS 'avg_logical_writes'
          FROM      sys.dm_exec_query_stats
          ORDER BY  execution_count  DESC
        ) AS qs
        CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.avg_logical_writes DESC;	
GO

/*
	For further Plan Cache exploration...

	Check out what other information is in 

	-- Biggest plans
	SELECT * FROM sys.dm_exec_cached_plans ORDER BY size_in_bytes DESC;

*/
