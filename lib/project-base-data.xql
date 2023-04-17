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

  <fullquery name="dynfield_attribs_sql">
    <querytext>
      select
		aa.attribute_id as acs_attribute_id,
		a.attribute_id as dynfield_attribute_id,
      		aa.pretty_name as attribute_pretty_name,
      		aa.attribute_name,
		w.*
      from
      		im_dynfield_type_attribute_map m,
      		im_dynfield_widgets w,
      		acs_attributes aa,
      		im_dynfield_attributes a
      		LEFT OUTER JOIN (
      			select *
      			from im_dynfield_layout
      			where page_url = ''
      		) la ON (a.attribute_id = la.attribute_id)
      where
      		m.attribute_id = a.attribute_id and
		m.object_type_id = :project_type_id and
      		a.widget_name = w.widget_name and
      		a.acs_attribute_id = aa.attribute_id and
      		aa.object_type = 'im_project' and
		(a.also_hard_coded_p is NULL or a.also_hard_coded_p = 'f')
      order by
    		coalesce(la.pos_y,0), coalesce(la.pos_x,0)

    </querytext>
  </fullquery>
</queryset>

