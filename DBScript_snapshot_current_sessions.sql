CREATE TABLE #temp_sp_who2
    (
      SPID INT,
      Status VARCHAR(1000) NULL,
      Login SYSNAME NULL,
      HostName SYSNAME NULL,
      BlkBy SYSNAME NULL,
      DBName SYSNAME NULL,
      Command VARCHAR(1000) NULL,
      CPUTime INT NULL,
      DiskIO INT NULL,
      LastBatch VARCHAR(1000) NULL,
      ProgramName VARCHAR(1000) NULL,
      SPID2 INT
      , rEQUESTID INT NULL --comment out for SQL 2000 databases

    )


INSERT  INTO #temp_sp_who2 -- date and time
EXEC sp_who2

SELECT  distinct ProgramName,count(*)
FROM    #temp_sp_who2
WHERE  spid >50 
group by ProgramName
order by count(*) desc
-- HostName not like '%PRDWWW%'
--and HostName not like '%PRDFRDI%'

SELECT  distinct HostName,count(*)
FROM    #temp_sp_who2
WHERE  spid >50 
group by HostName
order by count(*) desc

SELECT  distinct Login,count(*)
FROM    #temp_sp_who2
WHERE  spid >50 
group by Login
order by count(*) desc

Select login_name,
       program_name,
       host_name,
       nt_domain,
       nt_user_name 
From sys.dm_exec_sessions

