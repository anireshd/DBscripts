SELECT 
    cntr_value
FROM
    sys.dm_os_performance_counters
WHERE 
    object_name LIKE '%:Memory Manager%' AND 
    counter_name = 'Total Server Memory (KB)'

SELECT 
    cntr_value 
FROM 
    sys.dm_os_performance_counters
WHERE 
    object_name LIKE '%:General Statistics%' AND 
    counter_name = 'User Connections'

SELECT 
    instance_name,cntr_value 
FROM 
    sys.dm_os_performance_counters
WHERE 
    object_name LIKE '%:Wait Statistics%' AND 
    counter_name = 'Lock waits'

SELECT 
    instance_name,cntr_value 
FROM 
    sys.dm_os_performance_counters
WHERE 
    object_name LIKE '%:Wait%' AND 
    counter_name = 'Log buffer waits'

SELECT 
    object_name,counter_name,cntr_value
FROM 
    sys.dm_os_performance_counters
WHERE 
    object_name LIKE '%SQLServer:Wait Statistics%' AND 
    instance_name = 'Waits in progress'

SELECT st.text AS [SQL Text],
 w.session_id, 
 w.wait_duration_ms,
 w.wait_type, w.resource_address, 
 w.blocking_session_id, 
 w.resource_description FROM sys.dm_os_waiting_tasks AS w
 INNER JOIN sys.dm_exec_connections AS c ON w.session_id = c.session_id 
 CROSS APPLY (SELECT * FROM sys.dm_exec_sql_text(c.most_recent_sql_handle))
 AS st WHERE w.session_id > 50
 AND w.wait_duration_ms > 0
