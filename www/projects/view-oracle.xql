<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/www/projects/view-oracle.xql -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-10-07 -->
<!-- @arch-tag 2a30e494-185c-461d-88be-8b863f5372a7 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  
  <fullquery name="project_hierarchy">
    <querytext>
      select
        children.project_id as subproject_id,
        children.project_nr as subproject_nr,
        children.project_name as subproject_name,
        tree.tree_level(children.tree_sortkey) -
        tree.tree_level(parent.tree_sortkey) as subproject_level
      from
        im_projects parent,
        im_projects children
      where
        children.project_status_id not in ([im_project_status_deleted],[im_project_status_canceled])
        and children.tree_sortkey between parent.tree_sortkey and tree.right(parent.tree_sortkey)
        and parent.project_id = :super_project_id
      order by children.tree_sortkey
     </querytext>
    </fullquery>
</queryset>
