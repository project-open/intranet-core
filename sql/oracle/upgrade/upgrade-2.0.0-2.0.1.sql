------------------------------------------------------------------------------
-- packages/intranet-core/sql/oracle/upgrade-2.0.0-2.0.1.sql
--
-- @author frank.bergmann@project-open.com
-- @creation-date 2004-08-01
--

update im_view_columns set column_name='Company' where column_id=1;

@../intranet-customers.sql
@../intranet-categories.sql
@../intranet-views.sql

alter table im_view_columns add
	extra_from             varchar(4000);

