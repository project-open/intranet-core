<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">


<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>8.1</version>
  </rdbms>
  <fullquery name="subproject_query">
    <querytext>

	select
		children.project_id as subproject_id,
		trim(children.project_nr) as subproject_nr,
		trim(children.project_name) as subproject_name,
		children.project_status_id as subproject_status_id,
		children.parent_id as subproject_parent_id,
		im_category_from_id(children.project_status_id) as subproject_status,
		im_category_from_id(children.project_type_id) as subproject_type,
		tree_level(children.tree_sortkey) -
		tree_level(parent.tree_sortkey) as subproject_level,
                $sort_order_sql as sort_order
		$extra_select
	from
		im_projects parent,
		$perm_sql children
	where
		children.project_type_id not in ([im_project_type_task])
		$subproject_status_sql
		and children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
		and parent.project_id = :super_project_id
	order by children.tree_sortkey

    </querytext>
  </fullquery>
  <fullquery name="column_list_sql">
    <querytext>
	select	*
	from	im_view_columns
	where	view_id = :view_id
	order by sort_order
    </querytext>
  </fullquery>
</queryset>