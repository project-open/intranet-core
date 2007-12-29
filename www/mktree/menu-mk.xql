<?xml version="1.0"?>
<queryset>

<fullquery name="get_org_id">
  <querytext>
	select 
		org_id 
	from 
		ims_cp_organizations 
	where 
		man_id = :man_id	
  </querytext>
</fullquery>

<fullquery name="organizations">
  <querytext>
    select 
       org.org_id,
       org.org_title as org_title,
       org.hasmetadata,
       tree_level(o.tree_sortkey) as indent
    from
       ims_cp_organizations org, acs_objects o
    where
       org.org_id = o.object_id
     and
       man_id = :man_id
    order by
       org_id
  </querytext>
</fullquery>

<fullquery name="get_fs_package_id">
  <querytext>
	select 
		fs_package_id 
	from 
		ims_cp_manifests 
	where 
		man_id = :man_id
  </querytext>
</fullquery>


</queryset>