<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/www/offices/index-postgresql.xql -->
<!-- @author  (frank.bergmann@project-open.com) -->

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  

  <fullquery name="perm_sql">
    <querytext>
    
	(
		select	
		        c.*
		from
		        im_companies c,
			acs_rels r
		where
		        c.company_id = r.object_id_one
			and r.object_id_two = :user_id
			$where_clause
	) c
	        
	        
    </querytext>
  </fullquery>

</queryset>
