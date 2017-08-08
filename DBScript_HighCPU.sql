-- HIGH CPU *******
--  Who is running what at this instant 
SELECT st.text AS [Command text], login_time, [host_name], 
[program_name], sys.dm_exec_requests.session_id, client_net_address,
sys.dm_exec_requests.status, command, db_name(database_id) AS DatabaseName, sys.dm_exec_requests.cpu_time, sys.dm_exec_requests.logical_reads
, ISNULL(sys.dm_exec_requests.wait_type, 'None')AS 'Wait Type'
FROM sys.dm_exec_requests 
INNER JOIN sys.dm_exec_connections 
ON sys.dm_exec_requests.session_id = sys.dm_exec_connections.session_id
INNER JOIN sys.dm_exec_sessions 
ON sys.dm_exec_sessions.session_id = sys.dm_exec_requests.session_id
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
WHERE sys.dm_exec_requests.session_id >= 51
AND sys.dm_exec_requests.session_id <> @@spid
AND st.text not like '%push_notification_device_insert_update%'
ORDER BY sys.dm_exec_requests.status


DBCC SHOW_STATISTICS("tblShowtimes",IX_tblShowtimes_terminate_dm) ;
DBCC SHOW_STATISTICS("tblShowtimes",AK_tblShowtimes) ;
DBCC SHOW_STATISTICS("tblShowtimes",IX_tblShowtimes_theater_pkey_termiante_dm_user_dm) ;
DBCC SHOW_STATISTICS("tblShowtimes",IX_tblShowtimes_theater_user_dm) ;
DBCC SHOW_STATISTICS("tblShowtimes",PK_showtimes) ;

--USE Transfer
--GO
--sp_recompile xpperformance
--sp_recompile Showtimes_Merge
--sp_recompile Showtimes_Amenities_Insert

--USE Fandango
--GO
--update statistics tblshowtimes
--update statistics tblshowtimes_tms
--update statistics tblshowtimes_amenity
--update statistics tblshowtimes_amenity_tms
--update statistics show_times_xref
--update statistics tblshowtimes_history
--update statistics tblmovie_detail_rule
--update statistics tblmovie_detail_rule_amenity


