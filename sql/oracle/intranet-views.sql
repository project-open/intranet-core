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
-- @author	guillermo.belcic@project-open.com
-- @author	frank.bergmann@project-open.com


-- Defines a number of views to business objects,
-- implementing configurable reports, similar to
-- the choice of columns in the old addressbook.
--
-- fraber@fraber.de, 2003-07-24
--

-- ViewIDs: IDs < 1000 are reserved for Project/Open modules.
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
-- 100-199	Backup Exports

---------------------------------------------------------
-- Views
--
-- Views are a kind of meta-data that determine how a user
-- can see business objects.
-- Every view has:
--	1. Filters - Determine what objects to see
--	2. Columns - Determine how to render columns.
--

create sequence im_views_seq start with 1000;
create table im_views (
	view_id			integer 
				constraint im_views_pk
				primary key,
	view_name		varchar(100) 
				constraint im_views_name_un
				not null unique,
	view_type_id		integer
				constraint im_views_type_fk
				references im_categories,
	view_status_id		integer
				constraint im_views_status_fk
				references im_categories,
	visible_for		varchar(1000),
	view_sql		varchar(4000)
);

create sequence im_view_columns_seq start with 1000;
create table im_view_columns (
	column_id		integer 
				constraint im_view_columns_pk
				primary key,
	view_id			integer not null 
				constraint im_view_view_id_fk
				references im_views,
	-- group_id=NULL identifies the default view.
	-- however, there may be customized views for a specific group
	group_id			integer
				constraint im_view_columns_group_id_fk
				references groups,
	column_name		varchar(100) not null,
	-- tcl command being executed using "eval" for rendering the column
	column_render_tcl	varchar(4000),
	-- for when the column name results from an "as" command
	-- for ex., you can customize viewing columns
	extra_select		varchar(4000),
	extra_where		varchar(4000),
	sort_order		integer not null,
	-- set of permission tokens that allow viewing this column,
	-- separated with spaces and OR-joined
	visible_for		varchar(1000)
);


---------------------------------------------------------
-- Standard Views for TCL pages
--
insert into im_views (view_id, view_name, visible_for) values (1, 'customer_list', 'view_customers');
insert into im_views (view_id, view_name, visible_for) values (2, 'customer_view', 'view_customers');
insert into im_views (view_id, view_name, visible_for) values (10, 'user_list', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (11, 'user_view', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (12, 'user_contact', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (20, 'project_list', 'view_projects');
insert into im_views (view_id, view_name, visible_for) values (21, 'project_costs', 'view_projects');
insert into im_views (view_id, view_name, visible_for) values (22, 'project_status', 'view_projects');
insert into im_views (view_id, view_name, visible_for) values (80, 'office_list', 'view_offices');
insert into im_views (view_id, view_name, visible_for) values (81, 'office_view', 'view_offices');



-- Project Status List Page
--
delete from im_view_columns where column_id > 2200 and column_id < 2299;
--
insert into im_view_columns values (2201,22,NULL,'Project #',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',
'','',1,'');
insert into im_view_columns values (2203,22,NULL,'Client',
'"<A HREF=/intranet/customers/view?customer_id=$customer_id>$customer_name</A>"',
'','',2,'im_permission $user_id view_customers');
-- columns to be here inserted by intranet-timesheet
insert into im_view_columns values (2213,22,NULL,'Status',
'$project_status','','',14,'');
insert into im_view_columns values (2215,22,NULL,'Start Date',
'$start_date','','',15,'');
insert into im_view_columns values (2217,22,NULL,'Delivery Date',
'$end_date','','',16,'');
insert into im_view_columns values (2219,22,NULL,'Create',
'$create_date','','',17,'');
insert into im_view_columns values (2221,22,NULL,'Quote',
'$quote_date','','',18,'');
insert into im_view_columns values (2223,22,NULL,'Open',
'$open_date','','',19,'');
insert into im_view_columns values (2225,22,NULL,'Deliver',
'$deliver_date','','',20,'');
insert into im_view_columns values (2227,22,NULL,'Invoice',
'$invoice_date','','',21,'');
insert into im_view_columns values (2229,22,NULL,'Close',
'$close_date','','',22,'');
--
commit;

-- Project List Page
--
delete from im_view_columns where column_id > 2000 and column_id < 2099;
--
insert into im_view_columns values (2001,20,NULL,'Project #',
'"<A HREF=/intranet/projects/view?project_id=$project_id>$project_nr</A>"',
'','',1,'');
insert into im_view_columns values (2003,20,NULL,'Client',
'"<A HREF=/intranet/customers/view?customer_id=$customer_id>$customer_name</A>"',
'','',2,'im_permission $user_id view_customers');
insert into im_view_columns values (2007,20,NULL,'Project Name',
'$project_name','','',4,'');
insert into im_view_columns values (2009,20,NULL,'Type',
'$project_type','','',5,'');
insert into im_view_columns values (2013,20,NULL,'Project Manager',
'"<A HREF=/intranet/users/view?user_id=$project_lead_id>$lead_name</A>"',
'','',7,'');
insert into im_view_columns values (2015,20,NULL,'Start Date',
'$start_date','','',8,'');
insert into im_view_columns values (2017,20,NULL,'Delivery Date',
'$end_date','','',9,'');

insert into im_view_columns values (2021,20,NULL,'Status',
'$project_status','','',11,'');
commit;


-- CustomerListPage columns.
--
delete from im_view_columns where column_id > 0 and column_id < 8;
--
insert into im_view_columns values (1,1,NULL,'Client',
'"<A HREF=$customer_view_page?customer_id=$customer_id>$customer_name</A>"','','',1,
'expr 1');
insert into im_view_columns values (3,1,NULL,'Type',
'$customer_type','','',2,'expr 1');
insert into im_view_columns values (4,1,NULL,'Status',
'$customer_status','','',3,'expr 1');
insert into im_view_columns values (5,1,NULL,'Contact',
'"<A HREF=$user_view_page?user_id=$customer_contact_id>$customer_contact_name</A>"',
'','',4,'im_permission $user_id view_customer_contacts');
insert into im_view_columns values (6,1,NULL,'Contact Email',
'"<A HREF=mailto:$customer_contact_email>$customer_contact_email</A>"','','',5,
'im_permission $user_id view_customer_contacts');
-- insert into im_view_columns values (7,1,NULL,'Contact Phone',
-- '$customer_phone','','',6,'im_permission $user_id view_customer_contact');
commit;


--------------------------------------------------------------
-- UsersListPage
--
delete from im_view_columns where column_id > 199 and column_id < 299;
--
-- insert into im_view_columns values (207,10,NULL,'#',
-- '$user_id','','',6,'');

insert into im_view_columns values (200,10,NULL,'Name',
'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"','','',2,'');

insert into im_view_columns values (201,10,NULL,'Email',
'"<a href=mailto:$email>$email</a>"','','',3,'');

-- insert into im_view_columns values (202,10,NULL,'Status',
-- '$status','','',4,'');

insert into im_view_columns values (203,10,NULL,'MSM',
'"<A HREF=\"http://arkansasmall.tcworks.net:8080/message/msn/$msn_email\">
<IMG SRC=\"http://arkansasmall.tcworks.net:8080/msn/$msn_email\"
width=21 height=22 border=0 ALT=\"MSN Status\"></A>"','','',5,'');

insert into im_view_columns values (204,10,NULL,'Work Phone',
'$work_phone','','',6,'');

insert into im_view_columns values (205,10,NULL,'Cell Phone',
'$cell_phone','','',7,'');

insert into im_view_columns values (206,10,NULL,'Home Phone',
'$home_phone','','',8,'');
--
commit;



-------------------------------------------------------------------
-- UsersViewPage
--
delete from im_view_columns where column_id > 1100 and column_id <= 1199;
--
insert into im_view_columns values (1101,11,NULL,'Name','$name','','',1,
'im_view_user_permission $user_id $current_user_id $name view_users');
insert into im_view_columns values (1103,11,NULL,'Email',
'"<a href=\"mailto:$email\">$email</a>"','','',2,
'im_view_user_permission $user_id $current_user_id $email view_users');
insert into im_view_columns values (1105,11,NULL,'Home',
'"<a href=\"$url\">$url</a>"','','',3,
'im_view_user_permission $user_id $current_user_id $url view_users');
--
commit;


---------------------------------------------------------------
-- UsersContactViewPage
--
delete from im_view_columns where column_id > 399 and column_id < 499;
--
insert into im_view_columns values (401,12,NULL,'Home Phone','$home_phone','','',1,
'im_view_user_permission $user_id $current_user_id $home_phone view_users');
insert into im_view_columns values (403,12,NULL,'Cell Phone','$cell_phone','','',2,
'im_view_user_permission $user_id $current_user_id $cell_phone view_users');
insert into im_view_columns values (404,12,NULL,'Work Phone','$work_phone','','',3,
'im_view_user_permission $user_id $current_user_id $work_phone view_users');
insert into im_view_columns values (405,12,NULL,'Pager','$pager','','',4,
'im_view_user_permission $user_id $current_user_id $pager view_users');
insert into im_view_columns values (407,12,NULL,'Fax','$fax','','',5,
'im_view_user_permission $user_id $current_user_id $fax view_users');
insert into im_view_columns values (409,12,NULL,'AIM','$aim_screen_name','','',6,
'im_view_user_permission $user_id $current_user_id $aim_screen_name view_users');
insert into im_view_columns values (411,12,NULL,'ICQ','$icq_number','','',7,
'im_view_user_permission $user_id $current_user_id $icq_number view_users');
insert into im_view_columns values (413,12,NULL,'Home Line 1','$ha_line1','','',8,
'im_view_user_permission $user_id $current_user_id $ha_line1 view_users');
insert into im_view_columns values (415,12,NULL,'Home Line 2','$ha_line2','','',9,
'im_view_user_permission $user_id $current_user_id $ha_line2 view_users');
insert into im_view_columns values (417,12,NULL,'Home City','$ha_city','','',10,
'im_view_user_permission $user_id $current_user_id $ha_city view_users');
insert into im_view_columns values (421,12,NULL,'Home ZIP','$ha_postal_code','','',11,
'im_view_user_permission $user_id $current_user_id $ha_postal_code view_users');
insert into im_view_columns values (423,12,NULL,'Home Country','$ha_country_name','','',
12,'im_view_user_permission $user_id $current_user_id $ha_country_name view_users');
insert into im_view_columns values (425,12,NULL,'Work Line 1','$wa_line1','','',13,
'im_view_user_permission $user_id $current_user_id $wa_line1 view_users');
insert into im_view_columns values (427,12,NULL,'Work Line 2','$wa_line2','','',14,
'im_view_user_permission $user_id $current_user_id $wa_line2 view_users');
insert into im_view_columns values (429,12,NULL,'Work City','$wa_city','','',15,
'im_view_user_permission $user_id $current_user_id $wa_city view_users');
insert into im_view_columns values (433,12,NULL,'Work ZIP','$wa_postal_code','','',16,
'im_view_user_permission $user_id $current_user_id $wa_postal_code view_users');
insert into im_view_columns values (435,12,NULL,'Work Country','$wa_country_name','','',
17,'im_view_user_permission $user_id $current_user_id $wa_country_name view_users');
insert into im_view_columns values (437,12,NULL,'Note','$note','','',18,
'im_view_user_permission $user_id $current_user_id $note view_users');
insert into im_view_columns values (439,12,NULL,' ',
'"<input type=submit value=Edit>"','','',99,
'set a $write');
--
commit;


----------------------------------------------------------------
-- Offices
--

-- OfficeListPage columns.
--
delete from im_view_columns where column_id >= 8000 and column_id <= 8099;
--
insert into im_view_columns values (8001,80,NULL,'Office',
'"<A HREF=$office_view_page?office_id=$office_id>$office_name</A>"','','',10,
'im_permission $user_id view_customer_details');
insert into im_view_columns values (8002,80,NULL,'Company',
'"<A HREF=$customer_view_page?customer_id=$customer_id>$customer_name</A>"','','',20,
'im_permission $user_id view_customers');
insert into im_view_columns values (8003,80,NULL,'Type',
'$office_type','','',30,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8004,80,NULL,'Status',
'$office_status','','',40,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8005,80,NULL,'Contact',
'"<A HREF=$user_view_page?user_id=$contact_person_id>$contact_person_name</A>"',
'','',50,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8006,80,NULL,'City',
'$address_city','','',60,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8007,80,NULL,'Phone',
'$phone','','',70,'im_permission $user_id view_customer_details');
--
commit;


-- OfficeViewPage columns.
--
delete from im_view_columns where column_id >= 8100 and column_id <= 8199;
--
insert into im_view_columns values (8100,81,NULL,'Office Name','$office_name','','',
10, 'im_permission $user_id view_customer_details');
insert into im_view_columns values (8102,81,NULL,'Company',
'"<A HREF=$customer_view_page?customer_id=$customer_id>$customer_name</A>"','','',
20, 'im_permission $user_id view_customers');
insert into im_view_columns values (8104,81,NULL,'Type', '$office_type','','',
40,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8106,81,NULL,'Status','$office_status','','',
60,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8108,81,NULL,'Contact',
'"<A HREF=$user_view_page?user_id=$contact_person_id>$contact_person_name</A>"','','',
80,'im_permission $user_id view_customer_details');

insert into im_view_columns values (8130,81,NULL,'Phone','$phone','','',
300,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8132,81,NULL,'Fax','$fax','','',
320,'im_permission $user_id view_customer_details');

insert into im_view_columns values (8150,81,NULL,'City','$address_city','','',
500,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8152,81,NULL,'State','$address_state','','',
520,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8154,81,NULL,'Country','$address_country','','',
540,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8156,81,NULL,'ZIP','$address_postal_code','','',
560,'im_permission $user_id view_customer_details');
insert into im_view_columns values (8158,81,NULL,'Address',
'$address_line1 $address_line2','','',
580,'im_permission $user_id view_customer_details');

insert into im_view_columns values (8170,81,NULL,'Note','$note','','',
700,'im_permission $user_id view_customer_details');

--
delete from im_view_columns where column_id >= 8190 and column_id <= 8199;
insert into im_view_columns values (8190,81,NULL,' ','"<input type=submit value=Edit>"','','',
900,'set a $admin');

--
commit;
