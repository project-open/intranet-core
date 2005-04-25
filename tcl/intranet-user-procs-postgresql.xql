<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-user-procs-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-10 -->
<!-- @arch-tag 5efc2dd7-a552-4d4c-b83e-63b7204ae058 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="im_user_registration_component.registered_users">
    <querytext>
      select
        u.user_id,
        u.username,
        u.screen_name,
        u.last_visit,
        u.second_to_last_visit,
        u.n_sessions,
        to_char(u.creation_date, :date_format) as creation_date,
	u.member_state,
        im_email_from_user_id(u.user_id) as email,
        im_name_from_user_id(u.user_id) as name
      from
        cc_users u
      order by
        u.creation_date DESC
      limit $max_rows
    </querytext>
  </fullquery>
</queryset>
