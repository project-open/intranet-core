<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-office-procs-oracle.xql -->
<!-- @author  (juanjoruizx@yahoo.es) -->
<!-- @creation-date 2004-09-08 -->
<!-- @arch-tag 0d8fbbc3-1f1e-4962-91c9-a1f413229c18 -->
<!-- @cvs-id $Id$ -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  
  <fullquery name="office::new.create_new_office">
    <querytext>
      begin
        :1 := im_office.new(
        object_type     => 'im_office'
        , office_name     => :office_name
        , office_path     => :office_path
        , creation_date => :creation_date
        , creation_user => :creation_user
        , creation_ip => :creation_ip
        , context_id => :context_id
        , office_type_id => :office_type_id
        , office_status_id => :office_status_id
	, company_id => :company_id
	);
    end;
    </querytext>
  </fullquery>
  
</queryset>
