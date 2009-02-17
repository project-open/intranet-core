-- /packages/intranet-core/sql/common/intranet-core-backup.sql
--
-- Copyright (C) 2004 - 2009 ]project-open[
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
-- Backup Companies
--

delete from im_view_columns where view_id = 102;
delete from im_views where view_id = 102;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	102, 'im_companies', 1410, 50, '
select
        c.*,
        im_email_from_user_id(c.manager_id) as manager_email,
        im_email_from_user_id(c.accounting_contact_id) as accounting_contact_email,
        im_email_from_user_id(c.primary_contact_id) as primary_contact_email,
        im_category_from_id(c.company_type_id) as company_type,
        im_category_from_id(c.company_status_id) as company_status,
        im_category_from_id(c.crm_status_id) as crm_status,
        im_category_from_id(c.annual_revenue_id) as annual_revenue,
	o.office_name as main_office_name
from
        im_companies c,
	im_offices o
where
	c.main_office_id = o.office_id
');


delete from im_view_columns where column_id > 10200 and column_id < 10299;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10201,102,NULL,'company_name',
'$company_name','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10203,102,NULL,'company_path',
'$company_path','','',3,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10205,102,NULL,'main_office_name',
'$main_office_name','','',5,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10207,102,NULL,'deleted_p',
'$deleted_p','','',7,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10209,102,NULL,'company_type',
'$company_type','','',9,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10211,102,NULL,'company_status',
'$company_status','','',11,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10213,102,NULL,'crm_status',
'$crm_status','','',13,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10215,102,NULL,'primary_contact_email',
'$primary_contact_email','','',15,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10217,102,NULL,'accounting_contact_email',
'$accounting_contact_email','','',17,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10219,102,NULL,'manager_email',
'$manager_email','','',19,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10221,102,NULL,'vat_number',
'$vat_number','','',21,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10223,102,NULL,'referral_source',
'$referral_source','','',23,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10225,102,NULL,'annual_revenue',
'$annual_revenue','','',25,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10227,102,NULL,'billable_p',
'$billable_p','','',27,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10229,102,NULL,'site_concept',
'[ns_urlencode $site_concept]','','',29,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10231,102,NULL,'contract_value',
'$contract_value','','',31,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10233,102,NULL,'start_date',
'$start_date','','',33,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10235,102,NULL,'note',
'[ns_urlencode $note]','','',35,'');




delete from im_view_columns where view_id = 103;
delete from im_views where view_id = 103;
insert into im_views (
	view_id, view_name, view_type_id, visible_for, sort_order, view_sql
) values (
	103, 'im_company_members', 1410, '', 80, '
select
	c.company_name,
	im_email_from_user_id(r.object_id_two) as user_email,
	im_category_from_id(m.object_role_id) as role
from
	acs_rels r,
	im_biz_object_members m,
	im_companies c
where
	r.rel_id = m.rel_id
	and r.object_id_one = c.company_id
');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10301,103,NULL,'company_name',
'$company_name','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10303,103,NULL,'user_email',
'$user_email','','',3,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10305,103,NULL,'role',
'$role','','',5,'');




---------------------------------------------------------
-- Backup Projects
--

delete from im_view_columns where view_id = 100;
delete from im_views where view_id = 100;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	100, 'im_projects', 1410, 60, '
select
        p.*,
        c.company_name,
        im_project_name_from_id(p.parent_id) as parent_name,
        im_email_from_user_id(p.project_lead_id) as project_lead_email,
        im_email_from_user_id(p.supervisor_id) as supervisor_email,
        im_category_from_id(p.project_type_id) as project_type,
        im_category_from_id(p.project_status_id) as project_status,
        im_category_from_id(p.billing_type_id) as billing_type,
        to_char(p.end_date, ''YYYYMMDD HH24:MI'') as end_date_time,
        to_char(p.start_date, ''YYYYMMDD HH24:MI'') as start_date_time
from
        im_projects p,
        im_projects parent_p,
        im_companies c
where
        p.company_id = c.company_id
');


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10001,100,NULL,'project_name',
'$project_name','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10003,100,NULL,'project_nr',
'$project_nr','','',3,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10013,100,NULL,'project_path',
'$project_path','','',13,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10015,100,NULL,'parent_name',
'$parent_name','','',15,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10017,100,NULL,'company_name',
'$company_name','','',17,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10019,100,NULL,'project_type',
'$project_type','','',19,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10021,100,NULL,'project_status',
'$project_status','','',21,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10023,100,NULL,'description',
'[ns_urlencode $description]','','',23,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10025,100,NULL,'billing_type',
'$billing_type','','',25,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10027,100,NULL,'start_date',
'$start_date_time','','',27,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10029,100,NULL,'end_date',
'$end_date_time','','',29,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10031,100,NULL,'note',
'[ns_urlencode $note]','','',31,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10033,100,NULL,'project_lead_email',
'$project_lead_email','','',33,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10035,100,NULL,'supervisor_email',
'$supervisor_email','','',35,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10037,100,NULL,'requires_report_p',
'$requires_report_p','','',37,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10039,100,NULL,'project_budget',
'$project_budget','','',39,'');
--



delete from im_view_columns where view_id = 101;
delete from im_views where view_id = 101;
insert into im_views (
	view_id, view_name, view_type_id, visible_for, sort_order, view_sql
) values (
	101, 'im_project_members', 1410, '', 90, '
select
	p.project_name,
	im_email_from_user_id(r.object_id_two) as user_email,
	im_category_from_id(m.object_role_id) as role
from
	acs_rels r,
	im_biz_object_members m,
	im_projects p
where
	r.rel_id = m.rel_id
	and r.object_id_one = p.project_id
');

delete from im_view_columns where column_id > 10100 and column_id < 10199;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10101,101,NULL,'project_name','$project_name','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10103,101,NULL,'user_email','$user_email','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10105,101,NULL,'role','$role','','',5,'');




---------------------------------------------------------
-- Backup Offices
--

delete from im_view_columns where view_id = 104;
delete from im_views where view_id = 104;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	104, 'im_offices', 1410, 40, '
select
        o.*,
	im_email_from_user_id(o.contact_person_id) as contact_person_email,
	im_category_from_id(o.office_type_id) as office_type,
	im_category_from_id(o.office_status_id) as office_status
from
        im_offices o
');


delete from im_view_columns where column_id > 10400 and column_id < 10499;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10401,104,NULL,'office_name',
'$office_name','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10413,104,NULL,'office_path',
'$office_path','','',13,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10419,104,NULL,'office_type',
'$office_type','','',19,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10421,104,NULL,'office_status',
'$office_status','','',21,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10423,104,NULL,'public_p',
'$public_p','','',23,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10425,104,NULL,'phone',
'$phone','','',25,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10427,104,NULL,'fax',
'$fax','','',27,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10429,104,NULL,'address_line1',
'[ns_urlencode $address_line1]','','',29,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10433,104,NULL,'address_line2',
'[ns_urlencode $address_line2]','','',33,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10435,104,NULL,'address_city',
'[ns_urlencode $address_city]','','',35,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10437,104,NULL,'address_state',
'$address_state','','',37,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10439,104,NULL,'address_postal_code',
'$address_postal_code','','',41,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10441,104,NULL,'address_country_code',
'$address_country_code','','',41,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10443,104,NULL,'contact_person_email',
'$contact_person_email','','',43,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10445,104,NULL,'landlord',
'[ns_urlencode $landlord]','','',45,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10447,104,NULL,'security',
'$security','','',47,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (10449,104,NULL,'note',
'[ns_urlencode $note]','','',49,'');



delete from im_view_columns where view_id = 105;
delete from im_views where view_id = 105;
insert into im_views (
	view_id, view_name, view_type_id, visible_for, sort_order, view_sql
) values (
	105, 'im_office_members', 1410, '', 70, '
select
	p.office_name,
	im_email_from_user_id(r.object_id_two) as user_email,
	im_category_from_id(m.object_role_id) as role
from
	acs_rels r,
	im_biz_object_members m,
	im_offices p
where
	object_id_one=567
	and r.rel_id = m.rel_id
	and r.object_id_one = p.office_id
');

delete from im_view_columns where column_id > 10504 and column_id < 10599;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10501,105,NULL,'office_name','$office_name','','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10503,105,NULL,'user_email','$user_email','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10505,105,NULL,'role','$role','','',5,'');




---------------------------------------------------------
-- Backup Categories
--

delete from im_view_columns where view_id = 106;
delete from im_views where view_id = 106;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	106, 'im_categories', 1410, 10, '
select	c.*
from	im_categories c
');

delete from im_view_columns where column_id >= 10600 and column_id < 10699;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10601,106,NULL,'category_id','$category_id','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10602,106,NULL,'category','$category','','',2,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10603,106,NULL,'category_type','$category_type','','',3,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10605,106,NULL,'category_gif','$category_gif','','',5,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10607,106,NULL,'enabled_p','$enabled_p','','',7,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10609,106,NULL,'parent_only_p','$parent_only_p','','',9,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (
10611,106,NULL,'category_description','[ns_urlencode $category_description]','','',11,'');



---------------------------------------------------------
-- Backup Users
--

delete from im_view_columns where view_id = 110;
delete from im_views where view_id = 110;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	110, 'im_users', 1410, 20, '
SELECT
        pe.first_names,
        pe.last_name,
        pa.email,
        pa.url,
        u.screen_name,
	u.username,
	u.password,
	u.salt,
	u.password_question,
	u.password_answer,
	c.home_phone,
	c.work_phone,
	c.cell_phone,
	c.pager,
	c.fax,
	c.aim_screen_name,
	c.msn_screen_name,
	c.icq_number,
	c.ha_line1,
	c.ha_line2,
	c.ha_city,
	c.ha_state,
	c.ha_postal_code,
	c.ha_country_code,
	c.wa_line1,
	c.wa_line2,
	c.wa_city,
	c.wa_state,
	c.wa_postal_code,
	c.wa_country_code,
	c.note
FROM
        users u LEFT OUTER JOIN users_contact c ON u.user_id = c.user_id,
        parties pa,
        persons pe
WHERE
        u.user_id = pa.party_id
        and u.user_id = pe.person_id
');


delete from im_view_columns where column_id > 11000 and column_id < 11099;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11001,110,NULL,'first_names',
'$first_names','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11013,110,NULL,'last_name',
'$last_name','','',13,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11015,110,NULL,'email',
'$email','','',15,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11017,110,NULL,'url',
'$url','','',17,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11019,110,NULL,'screen_name',
'$screen_name','','',19,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11021,110,NULL,'username',
'$username','','',21,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11023,110,NULL,'password',
'$password','','',23,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11025,110,NULL,'salt',
'$salt','','',25,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11027,110,NULL,'password_question',
'$password_question','','',27,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11029,110,NULL,'password_answer',
'$password_answer','','',29,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11031,110,NULL,'home_phone',
'$home_phone','','',31,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11033,110,NULL,'work_phone',
'$work_phone','','',33,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11035,110,NULL,'cell_phone',
'$cell_phone','','',35,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11037,110,NULL,'pager',
'$pager','','',37,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11039,110,NULL,'fax',
'$fax','','',39,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11041,110,NULL,'aim_screen_name',
'$aim_screen_name','','',41,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11043,110,NULL,'msn_screen_name',
'$msn_screen_name','','',43,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11045,110,NULL,'icq_number',
'$icq_number','','',45,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11047,110,NULL,'ha_line1',
'$ha_line1','','',47,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11049,110,NULL,'ha_line2',
'$ha_line2','','',49,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11051,110,NULL,'ha_city',
'$ha_city','','',51,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11053,110,NULL,'ha_state',
'$ha_state','','',53,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11055,110,NULL,'ha_postal_code',
'$ha_postal_code','','',55,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11057,110,NULL,'ha_country_code',
'$ha_country_code','','',57,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11059,110,NULL,'wa_line1',
'$wa_line1','','',59,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11061,110,NULL,'wa_line2',
'$wa_line2','','',61,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11063,110,NULL,'wa_city',
'$wa_city','','',63,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11065,110,NULL,'wa_state',
'$wa_state','','',65,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11067,110,NULL,'wa_postal_code',
'$wa_postal_code','','',67,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11069,110,NULL,'wa_country_code',
'$wa_country_code','','',69,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11071,110,NULL,'note',
'[ns_urlencode $note]','','',71,'');




---------------------------------------------------------
-- Backup Profiles
--

delete from im_view_columns where view_id = 111;
delete from im_views where view_id = 111;
insert into im_views (
	view_id, view_name, view_type_id, sort_order, view_sql
) values (
	111, 'im_profiles', 1410, 30, '
SELECT
	g.group_name as profile_name,
	im_email_from_user_id(m.member_id) as user_email
FROM
	acs_objects o,
	group_distinct_member_map m,
	groups g
WHERE
	o.object_id = m.group_id
	and o.object_type = ''im_profile''
	and o.object_id = g.group_id
');

delete from im_view_columns where column_id > 11104 and column_id < 11199;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11101,111,NULL,'profile_name',
'$profile_name','','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (11103,111,NULL,'user_email',
'$user_email','','',3,'');



