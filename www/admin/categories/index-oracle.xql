<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="category_select">
        <querytext>

	select
		c.*,
		h.parent_id,
		im_category_from_id(h.parent_id) as parent
	from 
		im_categories c,
		im_category_hierarchy h
	where 
		$category_type_criterion
		and c.category_id = h.child_id(+)
	order by
		category_type,
		category_id

        </querytext>
</fullquery>

</queryset>
