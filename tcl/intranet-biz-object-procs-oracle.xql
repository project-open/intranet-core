<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-biz-object-procs-oracle.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-09 -->
<!-- @arch-tag e2c9dacc-aef1-4979-9d88-edc7bd67188f -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  
  <fullquery name="im_biz_object_add_role.del_users">
    <querytext>
      
    begin
        for row in (
                select
                        object_id_one as object_id,
                        object_id_two as user_id
                from
                        acs_rels r
                where   r.object_id_one=:object_id
                        and r.object_id_two=:user_id
        ) loop
                im_biz_object_member.del(row.object_id, row.user_id);
        end loop;
    end;

    </querytext>
  </fullquery>

  <fullquery name="im_biz_object_add_role.add_user">
    <querytext>

      begin
            :1 := im_biz_object_member.new(
                object_id       => :object_id,
                user_id         => :user_id,
                object_role_id  => :role_id,
                creation_user   => :user_id,
                creation_ip     => :user_ip 
            );
      end; 

    </querytext>
  </fullquery>
</queryset>
