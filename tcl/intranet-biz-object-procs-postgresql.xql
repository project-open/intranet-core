<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-biz-object-procs-postgresql.xql -->
<!-- @author  (nsadmin@barna.competitiveness.com) -->
<!-- @creation-date 2004-09-09 -->
<!-- @arch-tag 761b5534-d01b-4538-bd3d-4b3df8f10419 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>postgresql</type>
    <version>7.2</version>
  </rdbms>
  

  <fullquery name="im_biz_object_add_role.del_users">
    <querytext>
      DECLARE 
	 row RECORD;
      BEGIN
	 for row in
		select
			object_id_one as object_id,
			object_id_two as user_id
		from
			acs_rels r
		where   r.object_id_one=:object_id
			and r.object_id_two=:user_id
	 loop
		PERFORM im_biz_object_member__delete(row.object_id, row.user_id);
	 end loop;
	 return 0;
      END;
    </querytext>
  </fullquery>

  <fullquery name="im_biz_object_add_role.add_im_biz_object_members">
    <querytext>
	DECLARE
		v_rel_id	integer;
	BEGIN
		v_rel_id := im_biz_object_member__new (
			null,
			'im_biz_object_member',
			:object_id,
			:user_id,
			:role_id,
			:user_id,
			:user_ip
		);

		UPDATE im_biz_object_members SET 
			percentage = :percentage 
		WHERE rel_id = v_rel_id;

		RETURN v_rel_id;
	END;
    </querytext>
  </fullquery>


</queryset>
