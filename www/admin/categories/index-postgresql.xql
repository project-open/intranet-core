<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="category_select">
	<querytext>

	select
		c.*,
		im_category_from_id(aux_int1) as aux_int1_cat,
		im_category_from_id(aux_int2) as aux_int2_cat,
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
