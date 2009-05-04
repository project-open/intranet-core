-- /packages/intranet-core/sql/postgres/intranet-permissions.sql
--
-- Copyright (c) 1999-2008 ]project-open[
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
-- @author	unknown@arsdigita.com
-- @author	frank.bergmann@project-open.com


-------------------------------------------------------------
-- Profiles
--
-- "Profiles" is a group type that is used to keep 
-- user permission information in a distinguishable
-- for from regular groups.

select acs_object_type__create_type (
	'im_profile',		-- object_type
	'Profile',		-- pretty_name
	'Profile',		-- pretty_plural
	'group',		-- supertype
	'im_profiles',		-- table_name
	'profile_id',		-- id_column
	'im_profile',		-- package_name
	'f',			-- abstract_p
	null,			-- type_extension_table
	'im_profile__name'	-- name_method
);

insert into acs_object_type_tables (object_type,table_name,id_column)
values ('im_profile', 'im_profiles', 'profile_id');



-------------------------------------------------------------
-- DB-neutral API for permissions
--

create or replace function im_object_permission_p (integer, integer, varchar)
returns char as '
DECLARE
	p_object_id	alias for $1;
	p_user_id	alias for $2;
	p_privilege	alias for $3;
BEGIN
	return acs_permission__permission_p(p_object_id, p_user_id, p_privilege);
END;' language 'plpgsql';


create or replace function im_grant_permission (integer, integer, varchar)
returns integer as '
DECLARE
	p_object_id	alias for $1;
	p_party_id	alias for $2;
	p_privilege	alias for $3;
BEGIN
	PERFORM acs_permission__grant_permission(p_object_id, p_party_id, p_privilege);
	return 0;
END;' language 'plpgsql';

create or replace function im_revoke_permission (integer, integer, varchar)
returns integer as '
DECLARE
	p_object_id	alias for $1;
	p_party_id	alias for $2;
	p_privilege	alias for $3;
BEGIN
	PERFORM acs_permission__revoke_permission(p_object_id, p_party_id, p_privilege);
	return 0;
END;' language 'plpgsql';



-------------------------------------------------------------
-- Shortcut proc to setup loads of privileges.
--
create or replace function im_priv_create (varchar, varchar)
returns integer as '
DECLARE
	p_priv_name		alias for $1;
	p_profile_name		alias for $2;

	v_profile_id		integer;
	v_object_id		integer;
	v_count			integer;
BEGIN
	-- Get the group_id from group_name
	select group_id into v_profile_id from groups
	where group_name = p_profile_name;

	-- Get the Main Site id, used as the global identified for permissions
	select package_id into v_object_id from apm_packages 
	where package_key=''acs-subsite'';

	select count(*) into v_count from acs_permissions
	where object_id = v_object_id and grantee_id = v_profile_id and privilege = p_priv_name;

	IF NULL != v_profile_id AND 0 = v_count THEN
		PERFORM acs_permission__grant_permission(v_object_id, v_profile_id, p_priv_name);
	END IF;

	return 0;
end;' language 'plpgsql';


-- add the same relation types for im_profile as for "group".
--insert into group_type_rels (group_rel_type_id, rel_type, group_type)
--select 
--	acs_object_id_seq.nextval, 
--	r.rel_type, 
--	'im_profile' as group_type
--from
--	group_type_rels r
--where 
--	r.group_type = 'group'
--;


CREATE TABLE im_profiles (
	profile_id	integer not null
			constraint im_profiles_pk
			primary key
			constraint im_profiles_profile_id_fk
			references groups(group_id),
	profile_gif	varchar(100) default 'profile'
);

insert into group_types (group_type) values ('im_profile');




create or replace function im_profile__new (varchar, varchar) 
returns integer as '
DECLARE
	pretty_name	alias for $1;
	profile_gif	alias for $2;
BEGIN
	return im_profile__new(
	null,
	''im_profile'',
	now(),
	0,
	null,
	null,

	null,
	null,
	pretty_name,
	''closed'',
	profile_gif
	);
END;' language 'plpgsql';


create or replace function im_profile__name (integer) 
returns varchar as '
DECLARE
	p_profile_id		alias for $1;
	
	v_profile_name		varchar;
BEGIN
	select	group_name
	into	v_profile_name
	from	groups
	where	group_id = p_profile_id;

	return v_profile_name;
END;' language 'plpgsql';



create or replace function im_profile__new (
	integer, varchar, timestamptz, integer, varchar, integer,
	varchar, varchar, varchar, varchar, varchar
) returns integer as '
DECLARE
	p_profile_id	alias for $1;
	p_object_type	alias for $2;
	p_creation_date	alias for $3;
	p_creation_user	alias for $4;
	p_creation_ip	alias for $5;
	p_context_id	alias for $6;

	p_email		alias for $7;
	p_url		alias for $8;
	p_group_name	alias for $9;
	p_join_policy	alias for $10;
	p_profile_gif	alias for $11;

	v_group_id integer;
BEGIN
	v_group_id := acs_group__new (
			p_profile_id,
			p_object_type,
			p_creation_date,
			p_creation_user,
			p_creation_ip,
			p_email,
			p_url,
			p_group_name,
			p_join_policy,
			p_context_id
	);

	insert into im_profiles (
		profile_id, 
		profile_gif
	) values (
		v_group_id, 
		p_profile_gif
	);

	return v_group_id;

end;' language 'plpgsql';



create or replace function im_profile__delete (integer) returns integer as '
DECLARE
	v_profile_id		alias for $1;
BEGIN
	delete from im_profiles
	where profile_id=v_profile_id;

	PERFORM acs_group__delete( v_profile_id );

	return 0;
end;' language 'plpgsql';




-- Return a string with all profiles of the user
create or replace function im_profiles_from_user_id(integer)
returns varchar as '
DECLARE
	v_user_id	alias for $1;
	v_profiles	varchar;
	row		RECORD;
BEGIN
	v_profiles := '''';
	FOR row IN
		select	group_name
		from	groups g,
			im_profiles p,
			group_distinct_member_map m
		where	m.member_id = v_user_id
			and g.group_id = m.group_id
			and g.group_id = p.profile_id
	LOOP
	    IF '''' != v_profiles THEN v_profiles := v_profiles || '', ''; END IF;
	    v_profiles := v_profiles || row.group_name;
	END LOOP;

	return v_profiles;
END;' language 'plpgsql';
select im_profiles_from_user_id(624);




-- Function to add a new member to a user_group
create or replace function user_group_member_add ( integer, integer, varchar)
returns integer as '
DECLARE
	p_group_id	alias for $1;
	p_user_id	alias for $2;
	p_role		alias for $3;

	v_rel_id		integer;
BEGIN
	v_rel_id := membership_rel__new(
		p_group_id,	-- object_id_one
		p_user_id,	-- object_id_two
		0,		-- creation_user
		null		-- creation_ip
	);
	return v_rel_id;
END;' language 'plpgsql';


-- Function to add a new member to a user_group
create or replace function user_group_member_del (integer, integer)
returns integer as '
DECLARE
	row		RECORD;
	p_group_id	alias for $1;
	p_user_id	alias for $2;

	v_rel_id	integer;
BEGIN
	for row in 
		select	rel_id
		from	acs_rels
		where	object_id_one = p_group_id
			and object_id_two = p_user_id
	loop
	PERFORM membership_rel__delete(row.rel_id);
	end loop;

	return 0;
end;' language 'plpgsql';


-------------------------------------------------------------
-- Add Profiles
--
-- Profiles are just regular groups that are used to define
-- user permissions using the intranet-core object.

create or replace function im_create_profile (varchar, varchar)
returns integer as '
DECLARE
	v_pretty_name	alias for $1;
	v_profile_gif	alias for $2;

	v_group_id	integer;
	v_rel_id	integer;
	n_groups	integer;
	v_category_id   integer;
BEGIN
	-- Check that the group does not exist before
	select count(*)
	into n_groups
	from groups
	where group_name = v_pretty_name;

	-- only add the group if it did not exist before...
	if n_groups = 0 then

	v_group_id := im_profile__new(
		v_pretty_name,
		v_profile_gif
	);

	v_rel_id := composition_rel__new (
		null,			-- rel_id
		''composition_rel'',	-- rel_type
		-2,			-- object_id_one
		v_group_id,		-- object_id_two
		0,			-- creation_user
		null			-- creation_ip
	);
	
	select acs_object_id_seq.nextval into v_category_id;

	-- Add the group to the Intranet User Type categories
	perform im_category_new (
		v_category_id,  -- category_id
		v_pretty_name, 		    -- category
		''Intranet User Type'',     -- category_type
		null	   		    -- description
	);

	update im_categories set aux_int1 = v_group_id where category_id = v_category_id;

	end if;
	return 0;
end;' language 'plpgsql';

create or replace function im_drop_profile (varchar) 
returns integer as '
DECLARE
	row		RECORD;
	v_pretty_name	alias for $1;

	v_group_id	integer;
BEGIN
	-- Check that the group does not exist before
	select group_id
	into v_group_id
	from groups
	where group_name = v_pretty_name;

	-- First we need to remove this dependency ...
	delete from im_profiles where profile_id = v_group_id;
	delete from acs_permissions where grantee_id=v_group_id;
	-- the acs_group package takes care of segments referred
	-- to by rel_constraints__rel_segment. We delete the ones
	-- references by rel_constraints__required_rel_segment here.
	for row in 
	select cons.constraint_id
	from rel_constraints cons, rel_segments segs
	where
		segs.segment_id = cons.required_rel_segment
		and segs.group_id = v_group_id
	loop

	PERFORM rel_segment__delete(row.constraint_id);

	end loop;

	-- delete the actual group
	PERFORM im_profile__delete(v_group_id);

	-- now delete the category
	delete from im_categories where category = v_pretty_name and category_type = ''Intranet User Type'';
        
	return 0;
end;' language 'plpgsql';

select im_create_profile ('P/O Admins','admin');
select im_create_profile ('Customers','customer'); 
select im_create_profile ('Employees','employee'); 
select im_create_profile ('Freelancers','freelance'); 
select im_create_profile ('Project Managers','proman'); 
select im_create_profile ('Senior Managers','senman'); 
select im_create_profile ('Accounting','accounting'); 
select im_create_profile ('Sales','sales'); 
select im_create_profile ('HR Managers','profile'); 
select im_create_profile ('Freelance Managers','profile'); 



-------------------------------------------------------------
-- Privileges
--
-- Privileges are permission tokens relative to the "subsite"
-- package object.
-- 

-- "View" privilege in addition to "read":
-- This privilege is used to indicate whether a user has the
-- right to see the existence of a type of objects, a privilege 
-- inferior to read.
-- This privilege is used:
--	- In the ProjectViewPage in order to decide 
--		whether to show or not the company contact.
--		Read(Companies) means that the user is able
--		to actually read the company contact information,
--	so we have to show a link to the UserViewPage.
--	View(Company) indicates that we can show the
--	name of the company contact, but not display
--	a link to the UserViewPage.
--	If both privileges are missing, we are not going
--	to reveil even the existence of a company contact.
--	- The privilege is also used to decided whether to
--	display the submenus for users such as Employees,
--	Freelancers etc. The current_user needs to have 
--	the view privilege to see the list of users
--	(independed to te possible permission to see "read"
--	of the users that might be displayed).

select acs_privilege__create_privilege('view','View','View');
select acs_privilege__add_child('admin', 'view');

-- Global Privileges
-- These privileges are applied only to the "Main Site" object.
-- They determine global user characteristics independet of
-- individual objects (such as companies, users, ...)

-- Companies & Offices
select acs_privilege__create_privilege('add_companies','Add Companies','Add Companies');
select acs_privilege__add_child('admin', 'add_companies');
select acs_privilege__create_privilege('view_companies','View Companies','View Companies');
select acs_privilege__add_child('admin', 'view_companies');
select acs_privilege__create_privilege('view_companies_all','View All Companies','View All Companies');
select acs_privilege__add_child('admin', 'view_companies_all');
select acs_privilege__create_privilege('edit_companies_all','Edit All Companies','Edit All Companies');
select acs_privilege__add_child('admin', 'edit_companies_all');
select acs_privilege__create_privilege('view_company_contacts','View Company Contacts','View Company Contacts');
select acs_privilege__add_child('admin', 'view_company_contacts');
select acs_privilege__create_privilege('view_company_details','View Company Details','View Company Details');
select acs_privilege__add_child('admin', 'view_company_details');
select acs_privilege__create_privilege('view_offices','View Offices','View Offices');
select acs_privilege__add_child('admin', 'view_offices');
select acs_privilege__create_privilege('view_offices_all','View All Offices','View Offices');
select acs_privilege__add_child('admin', 'view_offices_all');
select acs_privilege__create_privilege('add_offices','Add Offices','Add Offices');
select acs_privilege__add_child('admin', 'add_offices');
select acs_privilege__create_privilege('view_internal_offices','View Internal Offices','View Internal Offices');
select acs_privilege__add_child('admin', 'view_internal_offices');
select acs_privilege__create_privilege('edit_internal_offices','Edit Internal Offices','Edit Internal Offices');
select acs_privilege__add_child('admin', 'edit_internal_offices');

-- Projects
select acs_privilege__create_privilege('add_projects','Add Projects','Add Projects');
select acs_privilege__add_child('admin', 'add_projects');
select acs_privilege__create_privilege('view_project_members','View Project Members','View Project Members');
select acs_privilege__add_child('admin', 'view_project_members');
select acs_privilege__create_privilege('view_projects_all','View All Projects','View All Projects');
select acs_privilege__add_child('admin', 'view_projects_all');
select acs_privilege__create_privilege('edit_projects_all','Edit All Projects','Edit All Projects');
select acs_privilege__add_child('admin', 'edit_projects_all');
select acs_privilege__create_privilege('view_projects_history','View Project History','View Project History');
select acs_privilege__add_child('admin', 'view_projects_history');
select acs_privilege__create_privilege('edit_project_basedata','Edit Project Base Data','Edit Project Base Data');
select acs_privilege__add_child('admin', 'edit_project_basedata');

-- Users
select acs_privilege__create_privilege('add_users','Add Users','Add Users');
select acs_privilege__add_child('admin', 'add_users');
select acs_privilege__create_privilege('view_users','View Users','View Users');
select acs_privilege__add_child('admin', 'view_users');
select acs_privilege__create_privilege('view_user_regs','View User Registrations','View User Registrations');
select acs_privilege__add_child('admin', 'view_user_regs');

-- Other
select acs_privilege__create_privilege('search_intranet','Search Intranet','Search Intranet');
select acs_privilege__add_child('admin', 'search_intranet');
select acs_privilege__create_privilege('admin_categories','Admin Categories','Admin Categories');
select acs_privilege__add_child('admin', 'admin_categories');
select acs_privilege__create_privilege('view_topics','General permission to see forum topics','');
select acs_privilege__add_child('admin', 'view_topics');



select im_priv_create('edit_project_basedata','Employees');
select im_priv_create('edit_project_basedata','Customers');
select im_priv_create('edit_project_basedata','Freelancers');
select im_priv_create('edit_project_basedata','Accounting');
select im_priv_create('edit_project_basedata','P/O Admins');
select im_priv_create('edit_project_basedata','Project Managers');
select im_priv_create('edit_project_basedata','Senior Managers');
select im_priv_create('edit_project_basedata','Sales');
select im_priv_create('edit_project_basedata','HR Managers');
select im_priv_create('edit_project_basedata','Freelance Managers');


-- -----------------------------------------------------
-- Add privileges for budget and budget_hours
--
select acs_privilege__create_privilege('add_budget','Add Budget','Add Budget');
select acs_privilege__add_child('admin', 'add_budget');
select acs_privilege__create_privilege('view_budget','View Budget','View Budget');
select acs_privilege__add_child('admin', 'view_budget');

select acs_privilege__create_privilege('add_budget_hours','Add Budget Hours','Add Budget Hours');
select acs_privilege__add_child('admin', 'add_budget_hours');
select acs_privilege__create_privilege('view_budget_hours','View Budget Hours','View Budget Hours');
select acs_privilege__add_child('admin', 'view_budget_hours');


-- Set preliminary privileges to setup the
-- permission matrix

select im_priv_create('view_budget','Accounting');
select im_priv_create('view_budget','P/O Admins');
select im_priv_create('view_budget','Project Managers');
select im_priv_create('view_budget','Senior Managers');

select im_priv_create('add_budget','Accounting');
select im_priv_create('add_budget','P/O Admins');
select im_priv_create('add_budget','Senior Managers');

select im_priv_create('view_budget_hours','Employees');
select im_priv_create('view_budget_hours','Accounting');
select im_priv_create('view_budget_hours','P/O Admins');
select im_priv_create('view_budget_hours','Project Managers');
select im_priv_create('view_budget_hours','Senior Managers');

select im_priv_create('add_budget_hours','Accounting');
select im_priv_create('add_budget_hours','P/O Admins');
select im_priv_create('add_budget_hours','Senior Managers');



-------------------------------------------------------------
-- Who can edit project_status_id even if there is a WF?
--
select acs_privilege__create_privilege('edit_project_status','Edit Project Status','Edit Project Status');
select acs_privilege__add_child('admin', 'edit_project_status');

select im_priv_create('edit_project_status','Accounting');
select im_priv_create('edit_project_status','P/O Admins');
select im_priv_create('edit_project_status','Senior Managers');



-------------------------------------------------------------
-- Who needs to login manually always?
--
SELECT acs_privilege__create_privilege('require_manual_login','Require manual login - dont allow auto-login', 'Require manual login - dont allow auto-login');
SELECT acs_privilege__add_child('admin', 'require_manual_login');

select im_priv_create('require_manual_login','P/O Admins');
select im_priv_create('require_manual_login','Senior Managers');
select im_priv_create('require_manual_login','Project Managers');
select im_priv_create('require_manual_login','Accounting');





-------------------------------------------------------------
-- Privileges Setup
--
-- Setup an initial privilege matrix

-- Shortcut proc define subgroup behaviour
--
create or replace function im_subgroup_create (varchar, varchar)
returns integer as '
DECLARE
	p_parent_name	alias for $1;
	p_subgroup_name alias for $2;

	v_rel_id		integer;
	v_parent_id		integer;
	v_subgroup_id		integer;
BEGIN
	-- Get the group_id from group_name
	select group_id into v_parent_id from groups
	where group_name = p_parent_name;

	-- Get the subgroup
	select group_id into v_subgroup_id from groups
	where group_name = p_subgroup_name;

	v_rel_id := composition_rel__new(
		v_parent_id,
		v_subgroup_id,
		0,
		null
	);
	return 0;
end;' language 'plpgsql';


-- Shortcut to grant privileges about one group to
-- the memebers or another group.
-- Example: 
--	im_user_matrix_grant('Freelancers','Employees','admin')
--	grants administration privileges of freelancers to
--	staff employees.
--
create or replace function im_user_matrix_grant (varchar, varchar, varchar)
returns integer as '
DECLARE
	p_group_name		alias for $1;
	p_grantee_group_name	alias for $2;
	p_privilege		alias for $3;

	v_group_id		integer;
	v_grantee_id		integer;
BEGIN
	-- Get the group_id from group_name
	select group_id into v_group_id from groups
	where group_name = p_group_name;

	-- Get the subgroup
	select group_id into v_grantee_id from groups
	where group_name = p_grantee_group_name;

	PERFORM acs_permission__grant_permission(
		v_group_id,
		v_grantee_id,
		p_privilege
	);
	return 0;
end;' language 'plpgsql';




------------------------------------------------------------
-- Check whether user_id is (some kind of) member of group_id.
create or replace function ad_group_member_p (integer, integer)
returns char as '
DECLARE
	p_user_id	alias for $1;
	p_group_id	alias for $2;

	ad_group_member_count	integer;
BEGIN
	select count(*) into ad_group_member_count from acs_rels
	where object_id_one = p_group_id and object_id_two = p_user_id;

	if ad_group_member_count = 0 then
		return ''f'';
	else
		return ''t'';
	end if;
end;' language 'plpgsql';


------------------------------------------------------------
-- Check whether user_id is an administrator of group_id.
-- ToDo: Hardcoded implementation - replace by privilege
-- scheme that works through all types of business objects.
--
create or replace function ad_group_member_admin_role_p (integer, integer)
returns integer as '
DECLARE
	p_user_id	alias for $1;
	p_group_id	alias for $2;

	ad_group_member_count	integer;
BEGIN
	select count(*) into ad_group_member_count 
	from acs_rels r, im_biz_object_members m, im_categories c
	where
		r.object_id_one = p_group_id
		and r.object_id_two = p_user_id
		and r.rel_id = m.rel_id
		and m.object_role_id = c.category_id
		and (c.category = ''Project Manager'' or c.category = ''Key Account'');

	if ad_group_member_count = 0 then
		return ''f'';
	else
		return ''t'';
	end if;
end;' language 'plpgsql';

