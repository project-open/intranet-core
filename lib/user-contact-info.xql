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
	c.home_phone,
	c.work_phone,
	c.cell_phone,
	c.pager,
	c.fax,
	c.aim_screen_name,
	c.icq_number,
	c.ha_line1,
	c.ha_line2,
	c.ha_city,
	c.ha_state,
	c.ha_postal_code,
	c.ha_country_code,
	c.wa_line1,
	c.wa_line2,
	c.wa_city,
	c.wa_state,
	c.wa_postal_code,
	c.wa_country_code,
	c.note
from
	users_contact c
where
	c.user_id = :user_id_from_search

    </querytext>
  </fullquery>

  <fullquery name="column_list_sql">
    <querytext>
	select	column_name,
		column_render_tcl,
		visible_for
	from	im_view_columns
	where	view_id=:view_id
		and group_id is null
	order by
		sort_order

    </querytext>
  </fullquery>



</queryset>
