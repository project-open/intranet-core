<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="menu_insert">
	<querytext>

    BEGIN
	PERFORM im_menu__new (
		null,			-- p_menu_id
		'im_menu',		-- object_type
		now(),			-- creation_date
		null,			-- creation_user
		null,			-- creation_ip
		null,			-- context_id
		:package_name'',	-- package_name
		:label,			-- label
		:name,			-- name
		:url,			-- url
		:sort_order,		-- sort_order
		:parent_menu_id,		-- parent_menu_id
		null			-- p_visible_tcl
	);
	return 0;
    END;

	</querytext>
</fullquery>

</queryset>
