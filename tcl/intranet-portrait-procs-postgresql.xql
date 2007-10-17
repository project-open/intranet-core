<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-freelance/tcl/intranet-freelance-procs-postgresql.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @author  (frank.bergmann@project-open.com) -->
<!-- @creation-date 2004-09-20 -->
<!-- @arch-tag 8c8ca7fd-e2e0-49a3-87c6-4566e4b921ea -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>

  <fullquery name="im_portrait_html.get_cr_item">
    <querytext>

        select
		im_name_from_user_id(u.user_id) as user_name,
                live_revision as revision_id,
                item_id
        from
                acs_rels a,
                cr_items c,
                cc_users u
        where
                a.object_id_two = c.item_id
                and a.object_id_one = :user_id
                and u.user_id = :user_id
                and a.rel_type = 'user_portrait_rel'

    </querytext>
  </fullquery>

</queryset>
