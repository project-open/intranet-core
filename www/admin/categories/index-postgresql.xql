<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="category_select">
	<querytext>

	select
		c.*,
		h.parent_id,
		im_category_from_id(h.parent_id) as parent
	from 
		im_categories c 
			left outer join	im_category_hierarchy h
			on (c.category_id = h.child_id)
	where 
		$category_type_criterion
	order by
		category_type,
		category_id

	</querytext>
</fullquery>

</queryset>
