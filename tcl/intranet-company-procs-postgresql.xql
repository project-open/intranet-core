<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-company-procs-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-09 -->
<!-- @arch-tag 0cbec04f-a982-45e4-88b0-c5933aaa9b0b -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="company::new.create_new_company">
    <querytext>

      select im_company__new (
        null,
        'im_company',
        :creation_date,
        :creation_user,
        :creation_ip,
        :context_id,
        :company_name,
        :company_path,
        :main_office_id,
        :company_type_id,
        :company_status_id
      );

    </querytext>
  </fullquery>
</queryset>
