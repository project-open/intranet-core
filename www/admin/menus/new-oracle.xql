<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="menu_insert">
        <querytext>

	declare
	
	begin
	    v_menu_id := im_menu.new (
	        package_name    => :package_name,
	        label           => :label,
	        name            => :name,
	        url             => :url,
	        sort_order      => :sort_order,
	        parent_menu_id  => :parent_menu_id
	    );
	end;

        </querytext>
</fullquery>

</queryset>
