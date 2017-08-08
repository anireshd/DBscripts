use master
go
SELECT 
      open_tran,
      p.last_batch AS 'Last_Batch',
      "Database" = substring(d.name, 1, 30),
      p.spid, 
      p.blocked,
      "COMPUTER" = substring(p.hostname,1,100),
      Waittime,
      lastwaittype, 
      "LOGIN"    = substring(p.loginame,1,20), 
      "Status"   = substring(p.status, 1, 15), 
      p.waitresource,
      p.physical_io,
      p.cpu,
      Text
      
FROM 
      sysprocesses p    
JOIN  sysdatabases d
ON    d.dbid = p.dbid
Cross Apply sys.dm_exec_sql_text(sql_handle)

where
--Suspended: The session is waiting for an event, :such as I/O, to complete 
--Runnable: The session's task is in the runnable queue of a scheduler while waiting to get a time quantum.
      p.status in ('runnable', 'suspended')
AND 
spid > 49
ORDER BY cpu desc
