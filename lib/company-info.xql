<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">


<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>8.1</version>
  </rdbms>
  <fullquery name="column_list_sql">
    <querytext>

        select  w.deref_plpgsql_function,
		aa.attribute_name,
		aa.table_name
        from    im_dynfield_widgets w,
                im_dynfield_attributes a,
                acs_attributes aa
        where   a.widget_name = w.widget_name and
                a.acs_attribute_id = aa.attribute_id and
                aa.object_type = 'im_company'
    </querytext>
  </fullquery>

  <fullquery name="company_get_info">
    <querytext>
select 
	c.*,
	im_name_from_user_id(c.primary_contact_id) as primary_contact_name,
	im_email_from_user_id(c.primary_contact_id) as primary_contact_email,
	im_name_from_user_id(c.accounting_contact_id) as accounting_contact_name,
	im_email_from_user_id(c.accounting_contact_id) as accounting_contact_email,
	im_name_from_user_id(c.manager_id) as manager,
	im_category_from_id(c.company_status_id) as company_status,
	im_category_from_id(c.company_type_id) as company_type,
	im_category_from_id(c.annual_revenue_id) as annual_revenue,
	to_char(start_date,'Month DD, YYYY') as start_date, 
        o.phone,
        o.fax,
        o.address_line1,
        o.address_line2,
        o.address_city,
        o.address_state,
        o.address_postal_code,
        o.address_country_code,
	$extra_select
from 
	im_companies c,
        im_offices o
where 
        c.company_id = :company_id
	and c.main_office_id = o.office_id

    </querytext>
  </fullquery>

  <fullquery name="company_get_cc">
    <querytext>
      select cc.country_name from country_codes cc where cc.iso = :address_country_code
    </querytext>
  </fullquery>

  <fullquery name="dynfield_select">
    <querytext>
    	select
	aa.pretty_name,
	aa.attribute_name
	from
		im_dynfield_widgets w,
		acs_attributes aa,
		im_dynfield_attributes a
		LEFT OUTER JOIN (
			select *
			from im_dynfield_layout
			where page_url = ''
		) la ON (a.attribute_id = la.attribute_id)
	where
		a.widget_name = w.widget_name and
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type = 'im_company' and
		(a.also_hard_coded_p is NULL or a.also_hard_coded_p = 'f')
	order by
		coalesce(la.pos_y,0), coalesce(la.pos_x,0)
    </querytext>
  </fullquery>
</queryset>