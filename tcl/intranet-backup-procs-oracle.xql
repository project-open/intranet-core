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
  <fullquery name="im_import_project_members.create_member">
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
  <fullquery name="im_import_costs.create_cost">
    <querytext>
     BEGIN
      :1 := im_cost.new (
        cost_name               => :cost_name,
        customer_id             => :customer_id,
        provider_id             => :provider_id,
        cost_status_id          => :cost_status_id,
        cost_type_id            => :cost_type_id,
	creation_user		=> :creator_id,
	creation_ip		=> '[ad_conn peeraddr]'
       );
    END;
    </querytext>
  </fullquery>
  <fullquery name="im_import_cost_centers.create_cost_center">
    <querytext>
     BEGIN
      :1 := im_cost_center.new (
        cost_center_name               => :cost_center_name,
        cost_center_label             => :cost_center_label,
        cost_center_code             => :cost_center_code,
        type_id             => :cost_center_type_id,
        status_id          => :cost_center_status_id,
        parent_id            => :parent_id
       );
    END;
    </querytext>
  </fullquery>
  <fullquery name="im_import_project_invoice_map.create_rel">
    <querytext>
	 begin
           :1 := acs_rel.new(
                object_id_one => :project_id,
                object_id_two => :invoice_id
           );
       end;
    </querytext>
  </fullquery>
</queryset>
