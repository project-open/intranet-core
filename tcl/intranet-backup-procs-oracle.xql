<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-backup-procs-oracle.xql -->
<!-- @author  (avila@digiteix.com) -->
<!-- @creation-date 2004-10-19 -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  
  <fullquery name="im_import_users.create_user">
    <querytext>
      
    BEGIN
    :1 := acs_user.new(
	username      => :username,
	email	 => :email,
	first_names   => :first_names,
	last_name     => :last_name,
	password      => :password,
	salt	  => :salt
      );
    END;
    </querytext>
  </fullquery>
   
  <fullquery name="im_import_users.add_to_registered_users">
    <querytext>
      
    BEGIN
    :1 := membership_rel.new(
            object_id_one    => :registered_users,
            object_id_two    => :user_id,
            member_state     => 'approved'
            );
    END;
    </querytext>
  </fullquery>

  <fullquery name="im_import_profiles.delete_rels">
    <querytext>
      BEGIN
     	 membership_rel.del(row.rel_id);
      END;
    </querytext>
   </fullquery>
  
   
   <fullquery name="im_import_profiles.insert_profile">
    <querytext>
    begin
     :1 := membership_rel.new(
	object_id_one    => :profile_id,
	object_id_two    => :user_id,
	member_state     => 'approved'
     );
    END;
    </querytext>
  </fullquery>
  <fullquery name="im_import_offices.office_create">
    <querytext>
     BEGIN
    :1 := im_office.new(
	office_name	=> :office_name,
	office_path	=> :office_path
        );
       END;    
    </querytext>
  </fullquery>
  <fullquery name="im_import_companies.company_create">
    <querytext>
     BEGIN
      :1 := im_company.new(
	company_name	=> :company_name,
	company_path	=> :company_path,
	main_office_id	=> :main_office_id	
       );
     END;
    </querytext>
  </fullquery>
  <fullquery name="im_import_project.project_create">
    <querytext>
     BEGIN
    :1 := im_project.new(
	project_name	=> :project_name,
	project_nr	=> :project_nr,
	project_path	=> :project_path,
	company_id	=> :company_id
      );
    END;
    </querytext>
  </fullquery>
  <fullquery name="im_import_office_members.create_member">
    <querytext>
     BEGIN
    :1 := im_biz_object_member.new(
	object_id	=> :object_id,
	user_id		=> :user_id,
	object_role_id	=> :object_role_id
       );
    END;
    </querytext>
  </fullquery>
  <fullquery name="im_import_company_members.create_member">
    <querytext>
     BEGIN
    :1 := im_biz_object_member.new(
	object_id	=> :object_id,
	user_id		=> :user_id,
	object_role_id	=> :object_role_id
       );
    END;
    </querytext>
  </fullquery>
</queryset>
