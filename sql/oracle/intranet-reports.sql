-- /packages/intranet-core/sql/oracle/intranet-views.sql
--
-- Copyright (C) 2004 Project/Open
--
-- This program is free software. You can redistribute it
-- and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option)
-- any later version. This program is distributed in the
-- hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
--
-- @author	frank.bergmann@project-open.com


---------------------------------------------------------
-- Reports for Backup

delete from im_views where view_id >= 100 and view_id <= 199;
insert into im_views values (100, 'im_projects', '', '
select
        p.*,
        c.customer_name,
        parent_p.project_name as parent_name,
        im_name_from_user_id(p.project_lead_id) as project_lead,
        im_name_from_user_id(p.supervisor_id) as supervisor,
        im_category_from_id(p.project_type_id) as project_type,
        im_category_from_id(p.project_status_id) as project_status,
        im_category_from_id(p.billing_type_id) as billing_type,
        to_char(p.end_date, ''YYYYMMDD HH24:MI'') as end_date_time,
        to_char(p.start_date, ''YYYYMMDD HH24:MI'') as start_date_time
from
        im_projects p,
        im_projects parent_p,
        im_customers c
where
        p.customer_id = c.customer_id
        and p.parent_id = parent_p.project_id
');
commit;


delete from im_view_columns where column_id > 10000 and column_id < 10099;
--
insert into im_view_columns values (
10001,100,NULL,'project_name','$project_name','','',1,'');
insert into im_view_columns values (
10003,100,NULL,'project_nr','$project_nr','','',3,'');
insert into im_view_columns values (
10013,100,NULL,'project_path','$project_path','','',13,'');
insert into im_view_columns values (
10015,100,NULL,'parent_name','$parent_name','','',15,'');
insert into im_view_columns values (
10017,100,NULL,'customer_name','$customer_name','','',17,'');
insert into im_view_columns values (
10019,100,NULL,'project_type','$project_type','',119,'');
insert into im_view_columns values (
10021,100,NULL,'project_status','$project_status','','',21,'');
insert into im_view_columns values (
10023,100,NULL,'description','$description','','',23,'');
insert into im_view_columns values (
10025,100,NULL,'billing_type','$billing_type','','',25,'');
insert into im_view_columns values (
10027,100,NULL,'start_date','$start_date_time','','',27,'');
insert into im_view_columns values (
10029,100,NULL,'end_date','$end_date_time','','',29,'');
insert into im_view_columns values (
10031,100,NULL,'note','$note','','',31,'');
insert into im_view_columns values (
10033,100,NULL,'project_lead','$project_lead','','',33,'');
insert into im_view_columns values (
10035,100,NULL,'supervisor','$supervisor','','',35,'');
insert into im_view_columns values (
10037,100,NULL,'requires_report_p','$requires_report_p','','',37,'');
insert into im_view_columns values (
10039,100,NULL,'project_budget','$project_budget','','',39,'');
--
commit;
