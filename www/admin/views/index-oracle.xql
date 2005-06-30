<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_views">
    <querytext>
	select 	v.view_id,
		v.view_name,
		c.category as view_type,
		c2.category as view_status,
		v.view_sql,
		v.sort_order
	from IM_VIEWS v,
	     IM_CATEGORIES c,
	     IM_CATEGORIES c2
	where v.view_type_id = c.category_id (+)
	and v.view_status_id = c2.category_id (+)
		order by v.view_name

    </querytext>
</fullquery>

</queryset>
