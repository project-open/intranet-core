<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-user-procs-oracle.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-10 -->
<!-- @arch-tag 010bcfcc-071d-4091-a006-fe5cc1f24785 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  
  <fullquery name="im_user_registration_component.registered_users">
    <querytext>
      select
        s.*
      from
        (select
                r.*,
                rownum row_num
        from
                (
select
        u.user_id,
        u.username,
        u.screen_name,
        u.last_visit,
        u.second_to_last_visit,
        u.n_sessions,
        u.creation_date,
	u.member_state,
        im_email_from_user_id(u.user_id) as email,
        im_name_from_user_id(u.user_id) as name
from
        cc_users u
order by
        u.creation_date DESC
                ) r
        ) s
      where
        row_num <= :max_rows

    </querytext>
  </fullquery>
</queryset>
