<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">


<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>8.1</version>
  </rdbms>
  <fullquery name="users_info_query">
    <querytext>
select 
	u.first_names, 
	u.last_name, 
        im_name_from_user_id(u.user_id) as name,
	u.email,
        u.url,
	u.creation_date as registration_date, 
	u.creation_ip as registration_ip,
	to_char(u.last_visit, :date_format) as last_visit,
	u.screen_name,
	u.username,
	u.member_state,
	u.creation_user as creation_user_id,
	im_name_from_user_id(u.creation_user) as creation_user_name,
	auth.short_name as authority_short_name,
	auth.pretty_name as authority_pretty_name
from
	cc_users u
	LEFT OUTER JOIN auth_authorities auth ON (u.authority_id = auth.authority_id)
where
	u.user_id = :user_id_from_search

    </querytext>
  </fullquery>

  <fullquery name="otp_installed">
    <querytext>

        select count(*)
        from apm_enabled_package_versions
        where package_key = 'intranet-otp'

    </querytext>
  </fullquery>

  <fullquery name="get_date_created">
    <querytext>
      select to_char(creation_date, 'Month DD, YYYY') from acs_objects where object_id = :user_id_from_search
    </querytext>
  </fullquery>
</queryset>