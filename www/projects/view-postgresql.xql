<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/www/projects/view-postgresql.xql -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-10-07 -->
<!-- @arch-tag e4114cf3-aa34-453a-88b5-c5c0190ab260 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="project_hierarchy">
    <querytext>
	select
		children.project_id as subproject_id,
		children.project_nr as subproject_nr,
		children.project_name as subproject_name,
		children.project_status_id as subproject_status_id,
		im_category_from_id(children.project_status_id) as subproject_status,
		im_category_from_id(children.project_type_id) as subproject_type,
		tree_level(children.tree_sortkey) -
		tree_level(parent.tree_sortkey) as subproject_level
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
</queryset>
