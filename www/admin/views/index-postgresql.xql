<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="get_views">
    <querytext>
	select 	v.view_id,
		v.view_name,
		c.category as view_type,
		c2.category as view_status,
		v.view_sql,
		v.sort_order
	from im_views v
		LEFT OUTER JOIN
	     im_categories c ON v.view_type_id = c.category_id
	     	LEFT OUTER JOIN
	     im_categories c2 ON v.view_status_id = c2.category_id
		order by v.view_name
	     
    </querytext>
</fullquery>

</queryset>
