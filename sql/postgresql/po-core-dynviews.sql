-- /packages/intranet-core/sql/postgres/intranet-core-dynviews.sql
--
-- Copyright (C) 1999-2004 Project/Open
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
-- @author      frank.bergmann@project-open.com

---------------------------------------------------------
-- Views
--
-- Views are a kind of meta-data that determine how a user
-- can see a business object.

create sequence po_dynviews_seq start 100;
create table po_dynviews (
	dynview_id		integer
				constraint po_views_pk primary key,
	dynview_name		varchar(100) 
				constraint po_views_dynview_name_nn not null 
				constraint po_views_dynview_name_unique unique
);

create sequence po_dynview_columns_seq start 1000;
create table po_dynview_columns (
	column_id		integer 
				constraint po_dynview_columns_pk 
				primary key,
	dynview_id		integer 
				constraint po_dynview_columns_dynview_nn 
				not null
				constraint po_dynview_columns_dynview_fk 
				references po_dynviews,
	column_name		varchar(100) not null,
	-- tcl command being executed using "eval" for rendering the column
	column_render_tcl	varchar(4000),
	-- for when the column name results from an "as" command
	-- for ex., you can customize viewing columns
	extra_select_sql		varchar(4000),
	sort_order		integer not null,
	-- tcl command being evalued to check if the column should be 
	-- visible for the current user
	visible_for_tcl		varchar(1000)	
);


-- 0 - 9	Companies
-- 10-19	Users
-- 20-29	Projects
-- 30-39	Invoices & Payments
-- 40-49	Forum
-- 50-59	Freelance
-- 60-69	Quality
-- 70-79	Marketplace(?)
-- 80-89
-- 90-99


insert into po_dynviews values (1, 'company_list');
insert into po_dynviews values (2, 'company_view');

insert into po_dynviews values (10, 'user_list');
insert into po_dynviews values (11, 'user_view');
insert into po_dynviews values (12, 'user_contact');

insert into po_dynviews values (20, 'project_list');
insert into po_dynviews values (21, 'project_costs');
insert into po_dynviews values (22, 'project_status');

insert into po_dynviews values (30, 'invoice_list');
insert into po_dynviews values (31, 'invoice_new');
insert into po_dynviews values (32, 'payment_list');




-- -------------------------------------------------------------------
-- CompanyListPage columns.
--
delete from po_dynview_columns where column_id > 0 and column_id < 9;
--
insert into po_dynview_columns values (1,1,'Company',
'"<A HREF=$company_view_page?company_id=$company_id>$company_name</A>"','',1,'');

insert into po_dynview_columns values (3,1,'Type',
'$company_type','',2,'');

insert into po_dynview_columns values (4,1,'Status',
'$company_status','',3,'');

insert into po_dynview_columns values (5,1,'Contact',
'"<A HREF=$user_view_page?user_id=$company_contact_id>$company_contact_name</A>"','',4,'');

insert into po_dynview_columns values (6,1,'Contact Email',
'"<A HREF=mailto:$company_contact_email>$company_contact_email</A>"','',5,'');



-- -------------------------------------------------------------------
-- Payment List Page
--
delete from po_dynview_columns where column_id > 3200 and column_id < 3299;
--
insert into po_dynview_columns values (3201,32,'Payment #',
'"<A HREF=/po-invoicing/invoices/view-payment?payment_id=$payment_id>$payment_id</A>"','',1,
'po-core::security::po_permission_p -privilege payment_read');

insert into po_dynview_columns values (3203,32,'Invoice',
'"<A HREF=/po-invoicing/invoices/view?invoice_id=$invoice_id>$invoice_nr</A>"','',3,
'po-core::security::po_permission_p -privilege invoice_read');

insert into po_dynview_columns values (3205,32,'Client',
'"<A HREF=/po-core/companies/view?company_id=$company_id>$company_name</A>"','',5,
'po-core::security::po_permission_p -privilege customer_read');

insert into po_dynview_columns values (3207,32,'Received',
'$received_date','',7,
'po-core::security::po_permission_p -privilege payment_read');

insert into po_dynview_columns values (3209,32,'Invoice Amount',
'$amount','',9,
'po-core::security::po_permission_p  -privilege payment_read');

insert into po_dynview_columns values (3211,32,'Amount Paid',
'$amount $currency','',11,
'po-core::security::po_permission_p -privilege payment_read');

insert into po_dynview_columns values (3213,32,'Status',
'$payment_status_id','',13,
'po-core::security::po_permission_p -privilege payment_read');

insert into po_dynview_columns values (3290,32,'Del',
'[if {1} {set ttt "<input type=checkbox name=del_payment value=$payment_id>"}]',
'',99,'po-core::security::po_permission_p -privilege payment_read');

--
commit;




-- -------------------------------------------------------------------
-- Invoice List Page
--
delete from po_dynview_columns where column_id > 3000 and column_id < 3099;
--
insert into po_dynview_columns values (3001,30,'Invoice #',
'"<A HREF=/po-invoicing/invoices/view?invoice_id=$invoice_id>$invoice_nr</A>"','',1,
'po-core::security::po_permission_p -privilege invoice_read');

insert into po_dynview_columns values (3003,30,'Preview',
'"<A HREF=/po-invoicing/invoices/view?invoice_id=$invoice_id${amp}render_template_id=$template_id>$invoice_nr</A>"',
'',2,'po-core::security::po_permission_p -privilege invoice_read');

insert into po_dynview_columns values (3005,30,'Client',
'"<A HREF=/po-core/companies/view?company_id=$company_id>$company_name</A>"','',3,
'po-core::security::po_permission_p -privilege customer_read');

insert into po_dynview_columns values (3007,30,'Due Date',
'[if {$overdue > 0} {set t "<font color=red>$due_date_calculated</font>"} else {set t "$due_date_calculated"}]',
'',4,'po-core::security::po_permission_p -privilege invoice_read');

insert into po_dynview_columns values (3011,30,'Amount',
'$amount_formatted $currency',
'',6,'po-core::security::po_permission_p -privilege invoice_read');

insert into po_dynview_columns values (3013,30,'Paid',
'$payment_amount $payment_currency',
'',7,'po-core::security::po_permission_p -privilege invoice_read');

insert into po_dynview_columns values (3017,30,'Status',
'[im_cost_status_select "cost_status.$invoice_id" $cost_status_id]','',13,
'po-core::security::po_permission_p -privilege invoice_read');

insert into po_dynview_columns values (3098,30,'Del',
'[if {[string equal "" $payment_amount]} {set ttt "<input type=checkbox name=del_invoice value=$invoice_id>"}]',
'',99,'po-core::security::po_permission_p -privilege invoice_read');

--
commit;


-- -------------------------------------------------------------------
-- Invoice New Page (shows Projects)
--
delete from po_dynview_columns where column_id > 3100 and column_id < 3199;
--
insert into po_dynview_columns values (3101,31,'Project #',
'"<A HREF=/po-core/projects/view?project_id=$group_id>$short_name</A>"','',1,
'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (3103,31,'Client',
'"<A HREF=/po-core/companies/view?company_id=$company_id>$company_name</A>"','',2,
'po-core::security::po_permission_p -privilege customer_read');

insert into po_dynview_columns values (3105,31,'Final User',
'$final_company',
'',3,'po-core::security::po_permission_p -privilege customer_read');

insert into po_dynview_columns values (3107,31,'Project Name',
'$group_name',
'',4,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (3109,31,'Type',
'$project_type',
'',5,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (3111,31,'Status',
'$project_status',
'',6,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (3113,31,'Delivery Date',
'$end_date',
'',7,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (3115,31,'Sel',
'"<input type=checkbox name=select_project value=$group_id>"',
'',8,'po-core::security::po_permission_p -privilege project_read');

--
commit;




-- -------------------------------------------------------------------
-- Project Status List Page
--
delete from po_dynview_columns where column_id > 2200 and column_id < 2299;
--
insert into po_dynview_columns values (2201,22,'Project #',
'"<A HREF=/po-core/projects/view?project_id=$group_id>$short_name</A>"',
'',1,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2203,22,'Client',
'"<A HREF=/po-core/companies/view?company_id=$company_id>$company_name</A>"',
'',2,'po-core::security::po_permission_p -privilege customer_read');

insert into po_dynview_columns values (2205,22,'Final User',
'$final_company','',3,'po-core::security::po_permission_p -privilege customer_read');

insert into po_dynview_columns values (2207,22,'Spend Days',
'$spend_days','',4,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2209,22,'Estim. Days',
'$est_days','',5,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2213,22,'Status',
'$project_status','',14,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2215,22,'Start Date',
'$start_date','',15,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2217,22,'Delivery Date',
'$end_date','',16,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2219,22,'Create',
'$create_date','',17,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2221,22,'Quote',
'$quote_date','',18,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2223,22,'Open',
'$open_date','',19,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2225,22,'Deliver',
'$deliver_date','',20,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2227,22,'Invoice',
'$invoice_date','',21,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2229,22,'Close',
'$close_date','',22,'po-core::security::po_permission_p -privilege project_read');
--
commit;



-- -------------------------------------------------------------------
-- Project List Page
--
delete from po_dynview_columns where column_id > 2000 and column_id < 2099;
--
insert into po_dynview_columns values (2001,20,'Project #',
'"<A HREF=/po-core/projects/view?project_id=$group_id>$short_name</A>"','',1,
'po-core::security::po_permission_p -privilege project_read');
insert into po_dynview_columns values (2003,20,'Client',
'"<A HREF=/po-core/companies/view?company_id=$company_id>$company_name</A>"','',2,
'po-core::security::po_permission_p -privilege customer_read');
insert into po_dynview_columns values (2005,20,'Final User',
'$final_company','',3,'po-core::security::po_permission_p -privilege customer_read');
insert into po_dynview_columns values (2007,20,'Project Name',
'$group_name','',4,'po-core::security::po_permission_p -privilege project_read');
insert into po_dynview_columns values (2009,20,'Type',
'$project_type','',5,'po-core::security::po_permission_p -privilege project_read');
insert into po_dynview_columns values (2011,20,'Subject Area',
'$subject_area','',6,'po-core::security::po_permission_p -privilege project_read');
insert into po_dynview_columns values (2013,20,'Project Manager',
'"<A HREF=/po-core/users/view?user_id=$project_lead_id>$lead_name</A>"','',7,
'po-core::security::po_permission_p -privilege project_read');
insert into po_dynview_columns values (2015,20,'Start Date',
'$start_date','',8,'po-core::security::po_permission_p -privilege project_read');
insert into po_dynview_columns values (2017,20,'Delivery Date',
'$end_date','',9,'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2019,20,'Words',
'[po_format_project_duration $task_words "" $task_hours]','',10,
'po-core::security::po_permission_p -privilege project_read');

insert into po_dynview_columns values (2021,20,'Status',
'$project_status','',11,'po-core::security::po_permission_p -privilege project_read');
commit;



-- -------------------------------------------------------------------
-- Add 'user_list' rows.
--
delete from po_dynview_columns where column_id > 199 and column_id < 299;
--
-- insert into po_dynview_columns values (207,10,'#',
-- '$user_id','',6,'po-core::security::po_permission_p -privilege user_read');

insert into po_dynview_columns values (200,10,'Name',
'"<a href=/po-core/users/view?user_id=$user_id>$name</a>"','',2,
'po-core::security::po_permission_p -privilege user_read');

insert into po_dynview_columns values (201,10,'Email',
'"<a href=mailto:$email>$email</a>"','',3,
'po-core::security::po_permission_p -privilege user_read');
-- insert into po_dynview_columns values (202,10,'Status',
-- '$status','',4,'po-core::security::po_permission_p -privilege user_read');

insert into po_dynview_columns values (203,10,'MSM',
'"<A HREF=\"http://arkansasmall.tcworks.net:8080/message/msn/$msn_email\"><IMG SRC=\"http://arkansasmall.tcworks.net:8080/msn/$msn_email\" width=21 height=22 border=0 ALT=\"MSN Status\"></A>"','',5,'po-core::security::po_permission_p -privilege user_read');

insert into po_dynview_columns values (204,10,'Work Phone',
'$work_phone','',6,'po-core::security::po_permission_p -privilege user_read');

insert into po_dynview_columns values (205,10,'Cell Phone',
'$cell_phone','',7,'po-core::security::po_permission_p -privilege user_read');

insert into po_dynview_columns values (206,10,'Home Phone',
'$home_phone','',8,'po-core::security::po_permission_p -privilege user_read');


-- -------------------------------------------------------------------
-- Add 'user_view' rows.
--
delete from po_dynview_columns where column_id > 1100 and column_id < 1199;
--
insert into po_dynview_columns values (1101,11,'Name','$name','',1,
'po_dynview_user_permission $user_id $current_user_id $name -privilege user_read');
insert into po_dynview_columns values (1103,11,'Email',
'"<a href=\"mailto:$email\">$email</a>"','',2,
'po_dynview_user_permission $user_id $current_user_id $email -privilege user_read');
insert into po_dynview_columns values (1105,11,'Home',
'"<a href=\"$url\">$url</a>"','',3,
'po_dynview_user_permission $user_id $current_user_id $url -privilege user_read');
--
insert into po_dynview_columns values (1121,11,'Site Admin','$admin_role','',10,
'po_dynview_user_permission $user_id $current_user_id $admin_role -privilege user_read');
insert into po_dynview_columns values (1123,11,'Wheel','$wheel_role','',11,
'po_dynview_user_permission $user_id $current_user_id $wheel_role -privilege user_read');
insert into po_dynview_columns values (1125,11,'Project Man.','$pm_role','',12,
'po_dynview_user_permission $user_id $current_user_id $pm_role -privilege user_read');
insert into po_dynview_columns values (1127,11,'Accounting','$accounting_role','',13,
'po_dynview_user_permission $user_id $current_user_id $accounting_role -privilege user_read');
insert into po_dynview_columns values (1129,11,'Employee','$employee_role','',14,
'po_dynview_user_permission $user_id $current_user_id $employee_role -privilege user_read');
insert into po_dynview_columns values (1131,11,'Client','$company_role','',15,
'po_dynview_user_permission $user_id $current_user_id $company_role -privilege user_read');
insert into po_dynview_columns values (1133,11,'Freelance','$freelance_role','',16,
'po_dynview_user_permission $user_id $current_user_id $freelance_role -privilege user_read');
--
insert into po_dynview_columns values (1199,11,' ',
'"<input type=submit value=Edit>"','',99,
'set a $edit_user');
--
commit;




-- -------------------------------------------------------------------
-- Add 'user_contact' rows.
--
delete from po_dynview_columns where column_id > 399 and column_id < 499;
--
insert into po_dynview_columns values (401,12,'Home Phone','$home_phone','',1,
'po_dynview_user_permission $user_id $current_user_id $home_phone -privilege user_read');
insert into po_dynview_columns values (403,12,'Cell Phone','$cell_phone','',2,
'po_dynview_user_permission $user_id $current_user_id $cell_phone -privilege user_read');
insert into po_dynview_columns values (404,12,'Work Phone','$work_phone','',3,
'po_dynview_user_permission $user_id $current_user_id $work_phone -privilege user_read');
insert into po_dynview_columns values (405,12,'Pager','$pager','',4,
'po_dynview_user_permission $user_id $current_user_id $pager -privilege user_read');
insert into po_dynview_columns values (407,12,'Fax','$fax','',5,
'po_dynview_user_permission $user_id $current_user_id $fax -privilege user_read');
insert into po_dynview_columns values (409,12,'AIM','$apo_screen_name','',6,
'po_dynview_user_permission $user_id $current_user_id $apo_screen_name -privilege user_read');
insert into po_dynview_columns values (411,12,'ICQ','$icq_number','',7,
'po_dynview_user_permission $user_id $current_user_id $icq_number -privilege user_read');
insert into po_dynview_columns values (413,12,'Home Line 1','$ha_line1','',8,
'po_dynview_user_permission $user_id $current_user_id $ha_line1 -privilege user_read');
insert into po_dynview_columns values (415,12,'Home Line 2','$ha_line2','',9,
'po_dynview_user_permission $user_id $current_user_id $ha_line2 -privilege user_read');
insert into po_dynview_columns values (417,12,'Home City','$ha_city','',10,
'po_dynview_user_permission $user_id $current_user_id $ha_city -privilege user_read');
insert into po_dynview_columns values (421,12,'Home ZIP','$ha_postal_code','',11,
'po_dynview_user_permission $user_id $current_user_id $ha_postal_code -privilege user_read');
insert into po_dynview_columns values (423,12,'Home Country','$ha_country_name','',12,
'po_dynview_user_permission $user_id $current_user_id $ha_country_name -privilege user_read');
insert into po_dynview_columns values (425,12,'Work Line 1','$wa_line1','',13,
'po_dynview_user_permission $user_id $current_user_id $wa_line1 -privilege user_read');
insert into po_dynview_columns values (427,12,'Work Line 2','$wa_line2','',14,
'po_dynview_user_permission $user_id $current_user_id $wa_line2 -privilege user_read');
insert into po_dynview_columns values (429,12,'Work City','$wa_city','',15,
'po_dynview_user_permission $user_id $current_user_id $wa_city -privilege user_read');
insert into po_dynview_columns values (433,12,'Work ZIP','$wa_postal_code','',16,
'po_dynview_user_permission $user_id $current_user_id $wa_postal_code -privilege user_read');
insert into po_dynview_columns values (435,12,'Work Country','$wa_country_name','',17,
'po_dynview_user_permission $user_id $current_user_id $wa_country_name -privilege user_read');
insert into po_dynview_columns values (437,12,'Note','$note','',18,
'po_dynview_user_permission $user_id $current_user_id $note -privilege user_read');
insert into po_dynview_columns values (439,12,' ',
'"<input type=submit value=Edit>"','',99,
'set a $edit_user');
--
commit;

