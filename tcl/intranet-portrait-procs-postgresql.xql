<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-freelance/tcl/intranet-freelance-procs-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @author  (frank.bergmann@project-open.com) -->
<!-- @creation-date 2004-09-20 -->
<!-- @arch-tag 8c8ca7fd-e2e0-49a3-87c6-4566e4b921ea -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="im_portrait_component.get_user_info">
    <querytext>
select
      u.first_names,
      u.last_name,
      gp.portrait_id,
      gp.portrait_upload_date,
      gp.portrait_comment,
      gp.portrait_original_width,
      gp.portrait_original_height,
      gp.portrait_client_file_name
from
        users u
      LEFT JOIN
        general_portraits gp ON u.user_id = gp.on_what_id
where
        u.user_id = :user_id
        and 'USERS' = gp.on_which_table
        and 't' = gp.portrait_primary_p
      
    </querytext>
  </fullquery>

</queryset>
