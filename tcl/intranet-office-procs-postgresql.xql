<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-office-procs-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-08 -->
<!-- @arch-tag 6f019819-1ff9-4aa0-98e6-f46984e3c9a3 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  <fullquery name="office::new.create_new_office">
    <querytext>

      select im_office__new (
        null,
        'im_office',
        :creation_date,
        :creation_user,
        :creation_ip,
        :context_id,
        :office_name,
        :office_path,
        :office_type_id,
        :office_status_id,
	:company_id
      );

    </querytext>
  </fullquery>
  
</queryset>
