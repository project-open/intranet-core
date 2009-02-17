-- /packages/intranet-core/sql/common/intranet-biz-objects.sql
--
-- Copyright (C) 1999 - 2009 ]project-open[
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
-- @author	  frank.bergmann@project-open.com


-- ------------------------------------------------------------
-- Roles for all Biz Objects
-- ------------------------------------------------------------

-- Core only knows about Member and PM
-- Project/Translation adds Translator, Proof Reader, ...
-- Project/Advertizing adds Producer, Designer, Texter, ...
-- Project/IT adds Business Analyst, Architect, Developer, ...

-- ToDo: Insert category hierarchy to be able to ask:
-- Is this an "object administrator" or a "full member"?

insert into im_categories (
	category_id, category, category_type, 
	category_gif, category_description) 
values (1300, 'Full Member', 'Intranet Biz Object Role', 
	'member', 'Full Member');

insert into im_categories (
	category_id, category, category_type, 
	category_gif, category_description) 
values (1301, 'Project Manager', 'Intranet Biz Object Role', 
	'project-manager', 'Project Manager');

insert into im_categories (
	category_id, category, category_type, 
	category_gif, category_description) 
values (1302, 'Key Account', 'Intranet Biz Object Role', 
	'key-account', 'Key Account Manager');

insert into im_categories (
	category_id, category, category_type, 
	category_gif, category_description) 
values (1303, 'Office Manager', 'Intranet Biz Object Role', 
	'office-manager', 'Office Manager');


-- Being used for "Final Customers" of projects, where
-- the final customer and the invoicing customer are
-- different
insert into im_categories (
        category_id, category, category_type,
        category_gif, category_description)
values (1304, 'Final Customer', 'Intranet Biz Object Role',
        'member', 'Final Customer');


-- Generic association between objects.
-- Dunno what this maybe used for in the future...
insert into im_categories (
        category_id, category, category_type,
        category_gif, category_description)
values (1305, 'Generic Association', 'Intranet Biz Object Role',
        'member', 'Generic Association');


-- Mail Association - Mails assocated with a BizObject
insert into im_categories (
        category_id, category, category_type,
        category_gif, category_description)
values (1306, 'Mail Association', 'Intranet Biz Object Role',
        'member', 'Related Mail');




-------------------------------------------------------------
-- Create these entries at the very end,
-- because the objects types need to be there first.

insert into im_biz_object_urls (object_type, url_type, url) values (
'user','view','/intranet/users/view?user_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'user','edit','/intranet/users/new?user_id=');

insert into im_biz_object_urls (object_type, url_type, url) values (
'person','view','/intranet/users/view?user_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'person','edit','/intranet/users/new?user_id=');




-------------------------------------------------------------
-- Offices

-- Setup the list of roles that a user can take with
-- respect to a office:
--      Full Member (1300) and
--      Office Manager (1303)
--
insert into im_biz_object_role_map values ('im_office',85,1300);
insert into im_biz_object_role_map values ('im_office',85,1303);



--------------------------------------------------------------
-- Projects

-- Setup the list of roles that a user can take with
-- respect to a project:
--	Full Member (1300) and
--	Project Manager (1301)
--
insert into im_biz_object_role_map values ('im_project',85,1300);
insert into im_biz_object_role_map values ('im_project',85,1301);
insert into im_biz_object_role_map values ('im_project',86,1300);
insert into im_biz_object_role_map values ('im_project',86,1301);



--------------------------------------------------------------
-- Companies

-- Setup the list of roles that a user can take with
-- respect to a company:
--      Full Member (1300) and
--      Key Account Manager (1302)
--
insert into im_biz_object_role_map values ('im_company',85,1300);
insert into im_biz_object_role_map values ('im_company',85,1302);



