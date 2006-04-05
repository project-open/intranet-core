<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="get_views">
    <querytext>
	select 	v.*,
		im_category_from_id(view_type_id) as view_type,
		im_category_from_id(view_status_id) as view_status
	from im_views v
	order by v.view_id
    </querytext>
</fullquery>

</queryset>
