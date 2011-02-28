<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">


<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>8.1</version>
  </rdbms>
  <fullquery name="select_projects">
    <querytext>

	select
		p.*,
		1 as llevel
	from
		im_projects p
	where 
		p.company_id = :company_id
	        and p.parent_id is null
		and p.project_status_id not in (
		:where_clause1
		:where_clause2
		)
		and p.project_type_id not in (
		:where_clause3
		:where_clause4
		)
		
	order by p.project_nr DESC

    </querytext>
  </fullquery>
</queryset>
