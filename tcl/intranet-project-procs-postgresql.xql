<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-project-procs-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-14 -->
<!-- @arch-tag d1c9394b-28cd-48f1-836e-c4fe4ade9b26 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  
  <fullquery name="project::new.create_new_project">
    <querytext>

select im_project__new (
        NULL,         -- project_id
        'im_project', -- object_type
        :creation_date, -- creation_date
        :creation_user, -- creation_user
        :creation_ip, -- creation_ip
        :context_id, -- context_id

        :project_name, -- project_name
        :project_nr, -- project_nr
        :project_path, -- project_path
        :parent_id, -- parent_id
        :company_id, -- company_id
        :project_type_id, -- project_type_id
        :project_status_id -- project_status_id
);

    </querytext>
  </fullquery>
</queryset>
