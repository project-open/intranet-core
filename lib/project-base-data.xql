<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">


<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>8.1</version>
  </rdbms>

  <fullquery name="column_list_sql">
    <querytext>
      select	w.deref_plpgsql_function,
      		aa.attribute_name
      from    	im_dynfield_widgets w,
      		im_dynfield_attributes a,
      		acs_attributes aa
      where   	a.widget_name = w.widget_name and
      		a.acs_attribute_id = aa.attribute_id and
      		aa.object_type = 'im_project'
      
    </querytext>
  </fullquery>

  <fullquery name="project_info_query">
    <querytext>
	select
		ip.*,
		ic.company_name,
		ic.company_path,
		to_char(ip.end_date, 'HH24:MI') as end_date_time,
		to_char(ip.start_date, 'YYYY-MM-DD') as start_date_formatted,
		to_char(ip.end_date, 'YYYY-MM-DD') as end_date_formatted,
		to_char(ip.percent_completed, '999990.9%') as percent_completed_formatted,
		ic.primary_contact_id as company_contact_id,
		im_name_from_user_id(ic.primary_contact_id) as company_contact,
		im_email_from_user_id(ic.primary_contact_id) as company_contact_email,
		im_name_from_user_id(ip.project_lead_id) as project_lead,
		im_name_from_user_id(ip.supervisor_id) as supervisor,
		im_name_from_user_id(ic.manager_id) as manager,
		$extra_select
	from
		im_projects ip, 
		im_companies ic
	where 
		ip.project_id = :project_id and
		ip.company_id = ic.company_id
      
    </querytext>
  </fullquery>

  <fullquery name="dynfield_attribs_sql">
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
      		aa.object_type = 'im_project'
      order by
    		coalesce(la.pos_y,0), coalesce(la.pos_x,0)

    </querytext>
  </fullquery>

</queryset>

