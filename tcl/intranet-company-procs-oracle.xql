<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-company-procs-oracle.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-09 -->
<!-- @arch-tag 701d75f2-9489-4bbb-af2e-2507e2f1b448 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  
  <fullquery name="company::new.create_new_company">
    <querytext>
begin
    :1 := im_company.new(
        object_type     => 'im_company',
        company_name    => :company_name,
        company_path   => :company_path,
        main_office_id  => :main_office_id,
        creation_date => :creation_date,
        creation_user => :creation_user,
        creation_ip => :creation_ip,
        context_id => :context_id,
        company_type_id => :company_type_id,
        company_status_id => :company_status_id
     );
end;

    </querytext>
  </fullquery>
</queryset>
