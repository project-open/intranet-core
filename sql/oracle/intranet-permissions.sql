-- /packages/intranet-core/sql/oracle/intranet-permissions.sql
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
-- @author	unknown@arsdigita.com
-- @author	frank.bergmann@project-open.com

-------------------------------------------------------------
-- DB-neutral API for permissions
--

create or replace function im_object_permission_p (
       p_object_id  IN integer, 
       p_user_id    IN integer, 
       p_privilege  IN varchar
)
return char
IS
BEGIN
	return acs_permission.permission_p(p_object_id, p_user_id, p_privilege);
END im_object_permission_p;
/
show errors

create or replace procedure im_grant_permission (
       p_object_id  IN integer,
       p_party_id    IN integer,
       p_privilege  IN varchar
)
IS
BEGIN
    acs_permission.grant_permission(p_object_id, p_party_id, p_privilege);
END im_grant_permission;
/
show errors

create or replace procedure im_revoke_permission (
       p_object_id  IN integer,
       p_party_id    IN integer,
       p_privilege  IN varchar
)
IS
BEGIN
    acs_permission.revoke_permission(p_object_id, p_party_id, p_privilege);
END im_revoke_permission;
/
show errors


-------------------------------------------------------------
-- Project/Open Profiles
--
-- "Profiles" is a group type that is used to keep 
-- user permission information in a distinguishable
-- for from regular groups.

BEGIN
 acs_object_type.create_type (
   supertype     => 'group',
   object_type   => 'im_profile',
   pretty_name   => 'Project/Open Profile',
   pretty_plural => 'Project/Open Profiles',
   table_name    => 'im_profiles',
   id_column     => 'profile_id'
 );
END;
/
show errors;

-- add the same relation types for im_profile as for "group".
insert into group_type_rels (group_rel_type_id, rel_type, group_type)
select 
	acs_object_id_seq.nextval, 
	r.rel_type, 
	'im_profile' as group_type
from
	group_type_rels r
where 
	r.group_type = 'group'
;


CREATE TABLE im_profiles (
	profile_id	integer not null
			constraint im_profiles_pk
			primary key
			constraint im_profiles_profile_id_fk
			references groups(group_id),
	profile_gif	varchar(100) default 'profile'
);

insert into group_types (group_type) values ('im_profile');


create or replace package im_profile as
  function new (
	group_id	IN integer default null,
	group_name	IN varchar,
	email	   IN varchar default null,
	url	     IN varchar default null,
	object_type     IN varchar default 'im_profile',
	creation_date   IN date default sysdate,
	creation_ip     IN varchar default null,
	last_modified   IN date default sysdate,
	modifying_ip    IN varchar default null,
	creation_user   IN integer default null,
	context_id	IN integer default null,
	join_policy     IN varchar default null,
	profile_gif	IN varchar default 'profile'
 ) return integer;

  procedure del (
    group_id	in integer
  );
END im_profile;
/
show errors;

create or replace package body im_profile as
  function new (
	group_id	IN integer default null,
	group_name	IN varchar,
	email	   IN varchar default null,
	url	     IN varchar default null,
	object_type     IN varchar default 'im_profile',
	creation_date   IN date default sysdate,
	creation_ip     IN varchar default null,
	last_modified   IN date default sysdate,
	modifying_ip    IN varchar default null,
	creation_user   IN integer default null,
	context_id	IN integer default null,
	join_policy     IN varchar default null,
	profile_gif	IN varchar default 'profile'
  ) return integer 
  IS
    v_group_id integer;
  begin
    v_group_id := acs_group.new (
		     group_id		=> new.group_id,
		     group_name		=> new.group_name,
		     email		=> new.email,
		     url		=> new.url,
		     object_type	=> new.object_type,
		     creation_date	=> new.creation_date,
		     creation_ip	=> new.creation_ip,
		     creation_user	=> new.creation_user,
		     context_id		=> new.context_id,
		     join_policy	=> new.join_policy
		   );
    insert into im_profiles (
	profile_id, 
	profile_gif
    ) values (
	v_group_id, 
	profile_gif
    );

    return v_group_id;
  end new;

  procedure del (group_id in integer) is
  begin
    delete from im_profiles
    where profile_id=group_id;
    acs_group.del( group_id );
  end del;
end im_profile;
/
show errors;






-- Function to add a new member to a user_group
create or replace procedure user_group_member_add (
	p_group_id IN integer,
	p_user_id IN integer,
	p_role IN varchar)
IS
	v_system_user_id	integer;
	v_rel_id		integer;
BEGIN
	v_system_user_id := 0;
	v_rel_id := membership_rel.new(
		object_id_one    => p_group_id,
		object_id_two    => p_user_id,
		creation_user    => v_system_user_id,
		creation_ip	=> '0:0:0:0'
	 );
end;
/
show errors


-- Function to add a new member to a user_group
create or replace procedure user_group_member_del (
	p_group_id IN integer,
	p_user_id IN integer)
IS
	v_rel_id		integer;
BEGIN
     for row in (
	select rel_id
	from acs_rels
	where
		object_id_one = p_group_id
		and object_id_two = p_user_id
     ) loop
	membership_rel.del(row.rel_id);
     end loop;
end;
/
show errors




-------------------------------------------------------------
-- Add Profiles
--
-- Profiles are just regular groups that are used to define
-- user permissions using the intranet-core object.

create or replace procedure im_create_profile (
	v_pretty_name IN varchar,
	v_profile_gif IN varchar
)
IS
  v_system_user_id  integer;
  v_group_id	integer;
  v_rel_id	integer;
  n_groups	integer;
BEGIN

     -- Check that the group doesn't exist before
     select count(*)
     into n_groups
     from groups
     where group_name = v_pretty_name;

     -- only add the group if it didn't exist before...
     if n_groups = 0 then

	v_group_id := im_profile.new(
		group_name	=> v_pretty_name,
		profile_gif	=> v_profile_gif
	);

	v_rel_id := composition_rel.new(
		object_id_one   => -2,
		object_id_two   => v_group_id,
		creation_user   => v_system_user_id,
		creation_ip	=> '0:0:0:0'
	);
     end if;

END;
/
show errors;


create or replace procedure im_drop_profile (
	v_pretty_name IN varchar
)
IS
  v_group_id	integer;
BEGIN
     -- Check that the group doesn't exist before
     select group_id
     into v_group_id
     from groups
     where group_name = v_pretty_name;

     -- First we need to remove this dependency ...
     delete from im_profiles where profile_id = v_group_id;
     delete from acs_permissions where grantee_id=v_group_id;
     -- the acs_group package takes care of segments referred
     -- to by rel_constraints.rel_segment. We delete the ones
     -- references by rel_constraints.required_rel_segment here.
     for row in (
	select cons.constraint_id
	from rel_constraints cons, rel_segments segs
	where
		segs.segment_id = cons.required_rel_segment
		and segs.group_id = v_group_id
     ) loop

	rel_segment.del(row.constraint_id);

     end loop;

     -- delete the actual group
     im_profile.del(v_group_id);
end;
/
show errors;


prompt *** Creating User Profiles
begin
   im_create_profile ('P/O Admins','admin');
   im_create_profile ('Customers','customer'); 
   im_create_profile ('Employees','employee'); 
   im_create_profile ('Freelancers','freelance'); 
   im_create_profile ('Project Managers','proman'); 
   im_create_profile ('Senior Managers','senman'); 
   im_create_profile ('Accounting','accounting'); 
   im_create_profile ('Sales','sales'); 
end;
/
show errors;



-------------------------------------------------------------
-- Privileges
--
-- Privileges are permission tokens relative to the "subsite"
-- (package) object "Project/Open Core".
-- 

prompt *** Creating Privileges
begin
    -- "View" privilege in addition to "read":
    -- This privilege is used to indicate whether a user has the
    -- right to see the existence of a type of objects, a privilege 
    -- inferior to read.
    -- This privilege is used:
    --	    - In the ProjectViewPage in order to decide 
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
    acs_privilege.create_privilege('view','View','View');
    acs_privilege.add_child('admin', 'view');

    -- Global Privileges
    -- These privileges are applied only to the "Main Site" object.
    -- They determine global user characteristics independet of
    -- individual objects (such as companies, users, ...)
    acs_privilege.create_privilege('add_companies','Add Companies','Add Companies');
    acs_privilege.add_child('admin', 'add_companies');

    acs_privilege.create_privilege('view_companies','View Companies','View Companies');
    acs_privilege.add_child('admin', 'view_companies');

    acs_privilege.create_privilege('view_companies_all','View All Companies','View All Companies');
    acs_privilege.add_child('admin', 'view_companies_all');

    acs_privilege.create_privilege('view_company_contacts','View Company Contacts','View Company Contacts');
    acs_privilege.add_child('admin', 'view_company_contacts');

    acs_privilege.create_privilege('view_company_details','View Company Details','View Company Details');
    acs_privilege.add_child('admin', 'view_company_details');


    acs_privilege.create_privilege('view_offices','View Offices','View Offices');
    acs_privilege.add_child('admin', 'view_offices');

    acs_privilege.create_privilege('view_offices_all','View All Offices','View Offices');
    acs_privilege.add_child('admin', 'view_offices_all');

    acs_privilege.create_privilege('add_offices','Add Offices','Add Offices');
    acs_privilege.add_child('admin', 'add_offices');

    acs_privilege.create_privilege('view_internal_offices','View Internal Offices','View Internal Offices');
    acs_privilege.add_child('admin', 'view_internal_offices');

    acs_privilege.create_privilege('edit_internal_offices','Edit Internal Offices','Edit Internal Offices');
    acs_privilege.add_child('admin', 'edit_internal_offices');


    acs_privilege.create_privilege('add_projects','Add Projects','Add Projects');
    acs_privilege.add_child('admin', 'add_projects');

-- 040228 fraber: Meaningless because everybody should be able to see (his) projects
--  acs_privilege.create_privilege('view_projects','View Projects','View Projects');
--  acs_privilege.add_child('admin', 'view_projects');

    acs_privilege.create_privilege('view_project_members','View Project Members','View Project Members');
    acs_privilege.add_child('admin', 'view_project_members');

    acs_privilege.create_privilege('view_projects_all','View All Projects','View All Projects');
    acs_privilege.add_child('admin', 'view_projects_all');

    acs_privilege.create_privilege('view_projects_history','View Project History','View Project History');
    acs_privilege.add_child('admin', 'view_projects_history');


    acs_privilege.create_privilege('add_users','Add Users','Add Users');
    acs_privilege.add_child('admin', 'add_users');

    acs_privilege.create_privilege('view_users','View Users','View Users');
    acs_privilege.add_child('admin', 'view_users');

    acs_privilege.create_privilege('view_user_regs','View User Registrations','View User Registrations');
    acs_privilege.add_child('admin', 'view_user_regs');


    acs_privilege.create_privilege('search_intranet','Search Intranet','Search Intranet');
    acs_privilege.add_child('admin', 'search_intranet');

    acs_privilege.create_privilege('admin_categories','Admin Categories','Admin Categories');
    acs_privilege.add_child('admin', 'admin_categories');

    acs_privilege.create_privilege('view_topics','General permission to see forum topics','');
    acs_privilege.add_child('admin', 'view_topics');
end;
/


-------------------------------------------------------------
-- Privileges Setup
--
-- Setup an initial privilege matrix

-- Shortcut proc to setup loads of privileges.
--
create or replace procedure im_priv_create (
	p_priv_name IN varchar,
	p_profile_name IN varchar
)
IS
  v_profile_id		integer;
  v_object_id		integer;
BEGIN
     -- Get the group_id from group_name
     select group_id 
     into v_profile_id
     from groups
     where group_name = p_profile_name;

     -- Get the Main Site id, used as the global identified for permissions
     select package_id
     into v_object_id
     from apm_packages 
     where package_key='acs-subsite';

     acs_permission.grant_permission(v_object_id, v_profile_id, p_priv_name);
END;
/
show errors;


-- Shortcut proc define subgroup behaviour
--
create or replace procedure im_subgroup_create (
	p_parent_name IN varchar,
	p_subgroup_name IN varchar
)
IS
	v_rel_id		integer;
	v_system_user_id	integer;
	v_parent_id		integer;
	v_subgroup_id		integer;
BEGIN
     -- Get the group_id from group_name
     select group_id
     into v_parent_id
     from groups
     where group_name = p_parent_name;

     -- Get the subgroup
     select group_id
     into v_subgroup_id
     from groups
     where group_name = p_subgroup_name;

	v_system_user_id := 0;
	v_rel_id := composition_rel.new(
		object_id_one   => v_parent_id,
		object_id_two   => v_subgroup_id,
		creation_user   => v_system_user_id,
		creation_ip	=> '0:0:0:0'
	 );
END;
/
show errors;


-- Shortcut to grant privileges about one group to
-- the memebers or another group.
-- Example: 
--	im_user_matrix_grant('Freelancers','Employees','admin')
--	grants administration privileges of freelancers to
--	staff employees.
--
create or replace procedure im_user_matrix_grant (
	p_group_name IN varchar,
	p_grantee_group_name IN varchar,
	p_privilege IN varchar
)
IS
	v_group_id		integer;
	v_grantee_id		integer;
BEGIN
     -- Get the group_id from group_name
     select group_id
     into v_group_id
     from groups
     where group_name = p_group_name;

     -- Get the subgroup
     select group_id
     into v_grantee_id
     from groups
     where group_name = p_grantee_group_name;

     acs_permission.grant_permission(
	v_group_id,
	v_grantee_id,
	p_privilege
     );
END;
/
show errors;



------------------------------------------------------------
-- Check whether user_id is (some kind of) member of group_id.
create or replace function ad_group_member_p (
    p_user_id IN integer,
    p_group_id IN integer
)
return char
IS
    ad_group_member_p    char(1);
BEGIN
    select decode(count(*), 0, 'f', 't')
    into ad_group_member_p
    from acs_rels
    where
	object_id_one = p_group_id
	and object_id_two = p_user_id;

    return ad_group_member_p;

END ad_group_member_p;
/
show errors


------------------------------------------------------------
-- Check whether user_id is an administrator of group_id.
-- ToDo: Hardcoded implementation - replace by privilege
-- scheme that works through all types of business objects.
--
create or replace function ad_group_member_admin_role_p (
    p_user_id IN integer,
    p_group_id IN integer
)
return char
IS
    ad_group_member_p    char(1);
BEGIN
    select decode(count(*), 0, 'f', 't')
    into ad_group_member_p
    from
	acs_rels r,
	im_biz_object_members m,
	im_categories c
    where
	r.object_id_one = p_group_id
	and r.object_id_two = p_user_id
	and r.rel_id = m.rel_id
	and m.object_role_id = c.category_id
	and (c.category = 'Project Manager' or c.category = 'Key Account');

    return ad_group_member_p;

END ad_group_member_admin_role_p;
/
show errors
