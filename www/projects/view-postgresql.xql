<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/www/projects/view-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-15 -->
<!-- @arch-tag 1e80c386-a933-4be1-96f0-1b0d93b50ab7 -->
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
	tree_level(children.tree_sortkey) -
        tree_level(parent.tree_sortkey) as subproject_level
from
        im_projects parent,
        im_projects children
where
        children.project_status_id not in ([im_project_status_deleted],[im_project_status_canceled])
        and children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
        and parent.tree_sortkey <> children.tree_sortkey
        and parent.project_id = :super_project_id

    </querytext>
  </fullquery>
</queryset>
