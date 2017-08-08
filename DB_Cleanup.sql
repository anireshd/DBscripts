
insert into metadata.tblInventory
(database_nm, Object_nm,Object_tp)

select 'Fandango',name,'Table' from sys.tables where name not in
('movie_detail_20121130',
'show_times_xref_122612',
'show_times_xref_20121130',
'show_times_xref_20121227',
'show_times_xref_20121228',
'theater_xref_20121203',
'temp_hmedved',
'temp_st_xref_nopassfix_1',
'temp_tmsp_nopassfix_1',
'temp_warmbodies',
'tm_bhn_notactivated',
'tm_incomm_notactivated',
'tm_plndr'
)
except
select 'Fandango',object_nm,'Table' from metadata.tblInventory

select name from sys.tables
except
select object_nm from metadata.tblInventory

select name from sys.views
except
select object_nm from metadata.tblInventory

select name from sys.procedures
except
select object_nm from metadata.tblInventory