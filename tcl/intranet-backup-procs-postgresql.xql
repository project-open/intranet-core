<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-backup-procs-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-09 -->
<!-- @arch-tag 761b5534-d01b-4538-bd3d-4b3df8f10419 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  

  <fullquery name="im_import_users.create_user">
    <querytext>
      select acs_user__new(
	null,		-- user_id
	'user',		-- object_type
	now(),		-- creation_date
	null,		-- creation_user
	null,		-- creation_ip
	null,		-- authority_id
        :username,	-- username
        :email,		-- email
	null,		-- url
        :first_names,	-- first_names
        :last_name,	-- last_name
        :password,	-- password
        :salt,		-- salt
	null,		-- screen_name
	't',
	null		-- context_id
	);
    </querytext>
  </fullquery>
  <fullquery name="im_import_users.add_to_registered_users">
    <querytext>
      
    select membership_rel__new(
	    null,			-- rel_id
	    'membership_rel',		-- reltype
            :registered_users, 		-- object_id_one
            :user_id,			-- object_id_two
            'approved',			-- member_state
            null,			--  creation_user
	    null			-- creation_ip
            );
    </querytext>
  </fullquery>
    <fullquery name="im_import_profiles.delete_rels">
      <querytext>
     	 select membership_rel__delete(:rel_id);
      </querytext>
    </fullquery>
    <fullquery name="im_import_profiles.insert_profile">
      <querytext>
         select  membership_rel__new(
           null,			-- rel_id
	   'membership_rel',		-- reltype
	   :profile_id,			-- object_id_one
	   :user_id,			-- object_id_two
	   'approved',			-- member_state
	   null,			--  creation_user
	   null			-- creation_ip
         );
      </querytext>
   </fullquery>
   <fullquery name="im_import_offices.office_create">
    <querytext>
        select  im_office__new(
	null,		-- office_id
	'im_office',	-- object_type
	now(),		-- creation_date
	null,		-- creattion_user
	null,		-- creation_ip
	null,		-- context_id
	:office_name,	-- office_name
	:office_path,	-- office_path
	170,		-- office_type_id
	160,		-- office_status_id
	null		-- company_id
        );
    </querytext>
  </fullquery>
  <fullquery name="im_import_companies.company_create">
    <querytext>
      select im_company__new(
	null,		-- company_id
	'im_company',	-- object_type
	now(),		-- creation_date
	null,		-- creation_user
	null,		-- creation_ip
	null,		-- context_id
	:company_name,	-- company_name
	:company_path,	-- company_path
	:main_office_id, -- main_office_id
	51,		-- company_type_id
	46		-- company_status_id
       );
    </querytext>
  </fullquery>
  <fullquery name="im_import_projects.project_create">
    <querytext>
    select im_project__new(
	null,		-- project_id
	'im_project',	-- object_type
	now(),		-- creation_date
	null,		-- creation_user
	null,		-- creation_ip
	null,		-- context_id
	:project_name,	-- project_name
	:project_nr,	-- project_nr
	:project_path,	-- project_path
	null,		-- parent_id
	:company_id,	-- company_id
	85,		-- project_type_id,
	76		-- project_status_id
      );
    </querytext>
  </fullquery>
  <fullquery name="im_import_office_members.create_member">
    <querytext>
    select im_biz_object_member__new(
	null,		-- rel_id
	'im_biz_object_member', -- rel_type
	:object_id,	-- object_id
	:user_id,	-- user_id
	:object_role_id, -- object_role_id
	null,		-- creation_user
	null		-- creation_ip
       );
    </querytext>
  </fullquery>
    <fullquery name="im_import_company_members.create_member">
    <querytext>
    select im_biz_object_member__new(
	null,		-- rel_id
	'im_biz_object_member', -- rel_type
	:object_id,	-- object_id
	:user_id,	-- user_id
	:object_role_id, -- object_role_id
	null,		-- creation_user
	null		-- creation_ip
       );
    </querytext>
  </fullquery>
</queryset>
