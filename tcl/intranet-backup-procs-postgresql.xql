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
</queryset>
