-- /packages/intranet-core/sql/common/intranet-views.sql
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
-- @author	guillermo.belcic@project-open.com
-- @author	frank.bergmann@project-open.com
-- @author	juanjo.ruiz@project-open.com


-- Defines a number of views to business objects,
-- implementing configurable reports, similar to
-- the choice of columns in the old addressbook.
--
-- frank.bergmann@project-open.com, 2003-07-24
--

-- ViewIDs: IDs < 1.000.000 are reserved for ]po[ modules.
--
--------------------------------------------------------
-- Base Views
--
--  0 -  9	Customers
--  10- 19	Users
--  20- 29	Projects
--  30- 39	Invoices & Payments
--  40- 49	Forum
--  50- 59	Freelance
--  60- 69	Quality
--  70- 79	Marketplace(?)
--  80- 89	Offices
--  90- 99	Translation

--------------------------------------------------------
-- Backup Views
--
-- 100  im_projects
-- 101  im_project_roles
-- 102  im_customers
-- 103  im_customer_roles
-- 104  im_offices
-- 105  im_office_roles
-- 106  im_categories
-- 107	im_employees
--
-- 110  users
-- 111  im_profiles
--
-- 120  im_freelancers
-- 121  im_freelance_skills
--
-- 130  im_forum_topics
-- 131	im_forum_folders
-- 132	im_forum_topic_user_map
--
-- 140  im_filestorage
--
-- 150  im_translation
-- 151	im_target_languages
-- 152	im_project_trans_details
--
-- 160  im_quality
--
-- 170  im_marketplace
--
-- 180  im_hours
-- 181  im_absences
--
-- 190  im_costs
-- 191  im_payments
-- 192  im_invoices
-- 193  im_invoice_items
-- 194  im_project_invoice_map
-- 195  im_trans_prices
-- 196	im_cost_centers
-- 197	im_investments

-- 930 	im_timesheet_task_list_report

--------------------------------------------------------
-- Views - Sequences 
--
-- 200-209		Timesheet
-- 210-219		Riskmanagement
-- 220-249		Costs
-- 250-259		Translation Quality
-- 260-269		Workflow
-- 270-279		intranet-helpdesk Tickets
-- 300-309		intranet-portfolio-management
-- 310-899		reserved
-- 900-909		Intranet Materials Reserved
-- 900-909		im_material_list
-- 910-919		Intranet Materials Reserved
-- 910-919		im_translation_task_list
-- 920-929		Intranet Portfolio Management
-- 930-939		intranet-reporting
-- 940-949		intranet-confdb
-- 950-959		intranet-idea-management
-- 960-969		intranet-customer-portal
-- 970-979		reserved
-- 980-989		reserved
-- 990-999		reserved
-- 1000-9999		reserved
-- 10000-10000000	reserved


---------------------------------------------------------
-- Views
--
-- Views are a kind of meta-data that determine how a user
-- can see business objects.
-- Every view has:
--	1. Filters - Determine what objects to see
--	2. Columns - Determine how to render columns.
--


---------------------------------------------------------
-- Standard Views for TCL pages
--
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (1, 'company_list', 'view_companies', 1400);
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (2, 'company_view', 'view_companies', 1405);
-- 3 reserved for company_csv

insert into im_views (view_id, view_name, visible_for, view_type_id)
values (10, 'user_list', 'view_users', 1400);
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (11, 'user_view', 'view_users', 1405);
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (12, 'user_contact', 'view_users', 1405);
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (13, 'user_community', 'view_users', 1405);
-- 3 reserved for users_csv


insert into im_views (view_id, view_name, visible_for, view_type_id)
values (20, 'project_list', 'view_projects', 1400);
-- 21 reserved for project_costs profit & loss view
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (22, 'project_status', 'view_projects', 1400);
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (23, 'project_personal_list', 'view_projects', 1400);
-- 24 reserved for project_csv
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (25, 'project_hierarchy', 'view_projects', 1400);
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (26, 'personal_todo_list', 'view_projects', 1400);



insert into im_views (view_id, view_name, visible_for, view_type_id)
values (80, 'office_list', 'view_offices', 1400);
insert into im_views (view_id, view_name, visible_for, view_type_id)
values (81, 'office_view', 'view_offices', 1405);



---------------------------------------------------------
-- Project Status List

--
delete from im_view_columns where column_id > 2200 and column_id < 2299;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2201,22,NULL,'Project Nr',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',
'','',1,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2203,22,NULL,'Client',
'"<A HREF=/intranet/companies/view?company_id=$company_id>$company_name</A>"',
'','',2,'im_permission $user_id view_companies');
-- columns to be here inserted by intranet-timesheet
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2213,22,NULL,'Status',
'$project_status','','',14,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2215,22,NULL,'Start Date',
'$start_date_formatted','','',15,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2217,22,NULL,'Delivery Date',
'$end_date_formatted','','',16,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2219,22,NULL,'Create',
'$create_date','','',17,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2221,22,NULL,'Quote',
'$quote_date','','',18,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2223,22,NULL,'Open',
'$open_date','','',19,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2225,22,NULL,'Deliver',
'$deliver_date','','',20,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2227,22,NULL,'Invoice',
'$invoice_date','','',21,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2229,22,NULL,'Close',
'$close_date','','',22,'');



--
delete from im_view_columns where column_id >= 2000 and column_id < 2099;
--

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2000,20,NULL,'Ok',
'<center>[im_project_on_track_bb $on_track_status_id]</center>',
'','',0,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2002,20,NULL,'Per',
'[im_date_format_locale $percent_completed 2 1] %','','',2,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2005,20,NULL,'Project nr',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',
'','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2010,20,NULL,'Project Name',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_name</A>"','','',10,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2015,20,NULL,'Client',
'"<A HREF=/intranet/companies/view?company_id=$company_id>$company_name</A>"',
'','',15,'im_permission $user_id view_companies');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2020,20,NULL,'Type',
'$project_type','','',20,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2025,20,NULL,'Project Manager',
'"<A HREF=/intranet/users/view?user_id=$project_lead_id>$lead_name</A>"',
'','',25,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2030,20,NULL,'Start Date',
'$start_date_formatted','','',30,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2035,20,NULL,'Delivery Date',
'$end_date_formatted','','',35,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2040,20,NULL,'Status',
'$project_status','','',40,'');



--
delete from im_view_columns where column_id > 2300 and column_id < 2399;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2301,23,NULL,'Project nr',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',
'','',1,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2303,23,NULL,'Project Name',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_name</A>"','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2309,23,NULL,'Type',
'$project_type','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2313,23,NULL,'Project Manager',
'"<A HREF=/intranet/users/view?user_id=$project_lead_id>$lead_name</A>"',
'','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2335,23,NULL,'Delivery Date',
'$end_date_formatted','','',35,'');


--
delete from im_view_columns where column_id > 0 and column_id < 8;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1,1,NULL,'Company',
'"<A HREF=$company_view_page?company_id=$company_id>$company_name</A>"','','',1,
'expr 1');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (3,1,NULL,'Type',
'$company_type','','',2,'expr 1');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (4,1,NULL,'Status',
'$company_status','','',3,'expr 1');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (5,1,NULL,'Contact',
'"<A HREF=$user_view_page?user_id=$company_contact_id>$company_contact_name</A>"',
'','',4,'im_permission $user_id view_company_contacts');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (6,1,NULL,'Contact Email',
'"<A HREF=mailto:$company_contact_email>$company_contact_email</A>"','','',5,
'im_permission $user_id view_company_contacts');

-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (7,1,NULL,'Contact Phone',
-- '$company_phone','','',6,'im_permission $user_id view_company_contact');




--------------------------------------------------------------------------
-- Project Hierarchy

--
delete from im_view_columns where view_id = 25;
--
insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) 
values (25,2510,10,'Empty','$arrow_right_html');

insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) 
values (25,2520,20,'Nr','"$subproject_indent<a href=$subproject_url>$subproject_nr</a>"');

insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) 
values (25,2530,30,'Name','"$subproject_indent<a href=$subproject_url>$subproject_name</a>"');

insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) 
values (25,2540,40,'Status','$subproject_status');

-- insert into im_view_columns (view_id, column_id, sort_order, column_name, column_render_tcl) 
-- values (25,2590,90,'Empty','$arrow_left_html');




insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2503,25,NULL,'Project Name',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_name</A>"','','',3,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2509,25,NULL,'Type',
'$project_type','','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2513,25,NULL,'Project Manager',
'"<A HREF=/intranet/users/view?user_id=$project_lead_id>$lead_name</A>"',
'','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (2535,25,NULL,'Delivery Date',
'$end_date_formatted','','',35,'');








--------------------------------------------------------------
--
delete from im_view_columns where column_id > 199 and column_id < 299;

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (200,10,NULL,'Name',
'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"','','',2,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (201,10,NULL,'Email',
'"<a href=mailto:$email>$email</a>"','','',3,'');

-- insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (202,10,NULL,'Status',
-- '$status','','',4,'');

--insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
-- extra_select, extra_where, sort_order, visible_for) values (203,10,NULL,'MSM',
--'"<A HREF=\"http://arkansasmall.tcworks.net:8080/message/msn/$msn_email\"><IMG SRC=\"http://arkansasmall.tcworks.net:8080/msn/$msn_email\" width=21 height=22 border=0 ALT=\"[_ intranet-core.MSN_Status]\"></A>"',
-- '','',5,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (204,10,NULL,'Work Phone',
'$work_phone','','',6,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (205,10,NULL,'Cell Phone',
'$cell_phone','','',7,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (206,10,NULL,'Home Phone',
'$home_phone','','',8,'');



-------------------------------------------------------------------
--
delete from im_view_columns where view_id = 11;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1101,11,NULL,'Name','$name','','',1,
'im_view_user_permission $user_id $current_user_id $name view_users');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1103,11,NULL,'Email',
'"<a href=mailto:$email>$email</a>"','','',2,
'im_view_user_permission $user_id $current_user_id $email view_users');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1105,11,NULL,'Home',
'"<a href=$url>$url</a>"','','',3,
'im_view_user_permission $user_id $current_user_id $url view_users');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1107,11,NULL,'Username',
'$username','','',4,
'parameter::get_from_package_key -package_key intranet-core -parameter EnableUsersUsernameP -default 0');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1108,11,NULL,'Authority',
'$authority_pretty_name','','',5, 
'parameter::get_from_package_key -package_key intranet-core -parameter EnableUsersAuthorityP -default 0');



---------------------------------------------------------------
--
delete from im_view_columns where column_id > 399 and column_id < 499;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (401,12,NULL,'Home Phone','$home_phone','','',1,
'im_view_user_permission $user_id $current_user_id $home_phone view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (403,12,NULL,'Cell Phone','$cell_phone','','',2,
'im_view_user_permission $user_id $current_user_id $cell_phone view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (404,12,NULL,'Work Phone','$work_phone','','',3,
'im_view_user_permission $user_id $current_user_id $work_phone view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (405,12,NULL,'Pager','$pager','','',4,
'im_view_user_permission $user_id $current_user_id $pager view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (407,12,NULL,'Fax','$fax','','',5,
'im_view_user_permission $user_id $current_user_id $fax view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (409,12,NULL,'AIM','$aim_screen_name','','',6,
'im_view_user_permission $user_id $current_user_id $aim_screen_name view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (411,12,NULL,'ICQ','$icq_number','','',7,
'im_view_user_permission $user_id $current_user_id $icq_number view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (413,12,NULL,'Home Line 1','$ha_line1','','',8,
'im_view_user_permission $user_id $current_user_id $ha_line1 view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (415,12,NULL,'Home Line 2','$ha_line2','','',9,
'im_view_user_permission $user_id $current_user_id $ha_line2 view_users');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (417,12,NULL,'Home City','$ha_city','','',10,
'im_view_user_permission $user_id $current_user_id $ha_city view_users');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (419,12,NULL,'Home State','$ha_state','','',11,
'im_view_user_permission $user_id $current_user_id $ha_state view_users');


insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (421,12,NULL,'Home ZIP','$ha_postal_code','','',11,
'im_view_user_permission $user_id $current_user_id $ha_postal_code view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (423,12,NULL,'Home Country','$ha_country_name','','',
12,'im_view_user_permission $user_id $current_user_id $ha_country_name view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (425,12,NULL,'Work Line 1','$wa_line1','','',13,
'im_view_user_permission $user_id $current_user_id $wa_line1 view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (427,12,NULL,'Work Line 2','$wa_line2','','',14,
'im_view_user_permission $user_id $current_user_id $wa_line2 view_users');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (429,12,NULL,'Work City','$wa_city','','',15,
'im_view_user_permission $user_id $current_user_id $wa_city view_users');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (431,12,NULL,'Work State','$wa_state','','',16,
'im_view_user_permission $user_id $current_user_id $wa_state view_users');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (433,12,NULL,'Work ZIP','$wa_postal_code','','',16,
'im_view_user_permission $user_id $current_user_id $wa_postal_code view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (435,12,NULL,'Work Country','$wa_country_name','','',
17,'im_view_user_permission $user_id $current_user_id $wa_country_name view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (437,12,NULL,'Note','$note','','',18,
'im_view_user_permission $user_id $current_user_id $note view_users');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (439,12,NULL,' ',
'"<input type=submit value=Edit>"','','',99,
'set a $write');



-------------------------------------------------------------------
-- Unassigned Users View
--
delete from im_view_columns where view_id = 13;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1310,13,NULL,'Creation',
'$creation_date','','',10,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1315,13,NULL,'Last Visit',
'$last_visit_formatted','','',15,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1320,13,NULL,'Name',
'"<a href=$user_view_page?user_id=$user_id>$name</a>"','','',20,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1330,13,NULL,'Email',
'"<a href=mailto:$email>$email</a>"','','',30,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (1340,13,NULL,'State',
'$member_state','','',30,'');




----------------------------------------------------------------
-- Offices
--

--
delete from im_view_columns where column_id >= 8000 and column_id <= 8099;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8001,80,NULL,'Office',
'"<A HREF=$office_view_page?office_id=$office_id>$office_name</A>"','','',10,
'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8002,80,NULL,'Company',
'"<A HREF=$company_view_page?company_id=$company_id>$company_name</A>"','','',20,
'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8003,80,NULL,'Type',
'$office_type','','',30,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8004,80,NULL,'Status',
'$office_status','','',40,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8005,80,NULL,'Contact',
'"<A HREF=$user_view_page?user_id=$contact_person_id>$contact_person_name</A>"',
'','',50,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8006,80,NULL,'City',
'$address_city','','',60,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8007,80,NULL,'Phone',
'$phone','','',70,'');



--
delete from im_view_columns where column_id >= 8100 and column_id <= 8199;
--
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8100,81,NULL,'Office Name','$office_name','','',
10, '');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8101,81,NULL,'Office Path','$office_path','','',
15, '');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8102,81,NULL,'Company',
'"<A HREF=$company_view_page?company_id=$company_id>$company_name</A>"','','',
20, 'im_permission $user_id view_companies');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8104,81,NULL,'Type', '$office_type','','',
40,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8106,81,NULL,'Status','$office_status','','',
60,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8108,81,NULL,'Contact',
'"<A HREF=$user_view_page?user_id=$contact_person_id>$contact_person_name</A>"','','',
80,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8130,81,NULL,'Phone','$phone','','',
300,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8132,81,NULL,'Fax','$fax','','',
320,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8150,81,NULL,'City','$address_city','','',
500,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8152,81,NULL,'State','$address_state','','',
520,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8154,81,NULL,'Country','$address_country','','',
540,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8156,81,NULL,'ZIP','$address_postal_code','','',
560,'');
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8158,81,NULL,'Address',
'$address_line1 $address_line2','','',
580,'');

insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8170,81,NULL,'Note','$note','','',
700,'');

--
delete from im_view_columns where column_id >= 8190 and column_id <= 8199;
insert into im_view_columns (column_id, view_id, group_id, column_name, column_render_tcl,
extra_select, extra_where, sort_order, visible_for) values (8190,81,NULL,' ','"<input type=submit value=Edit>"','','',
900,'set a $admin');

--
