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
    
	select
	        o.office_id,
		r.member_p as permission_member,
		see_all.see_all as permission_all
	from
	        im_offices o,
		(	select	count(rel_id) as member_p,
				object_id_one as object_id
			from	acs_rels
			where	object_id_two = :user_id
			group by object_id_one
		) r,
	        (       select  count(*) as see_all
	                from	acs_object_party_privilege_map
	                where   object_id=:subsite_id
	                        and party_id=:user_id
	                        and privilege='view_offices_all'
	        ) see_all
	where
	        o.office_id = r.object_id(+)
	        $where_clause
	        
	        
    </querytext>
  </fullquery>

</queryset>
