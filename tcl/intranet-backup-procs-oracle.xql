<?xml version="1.0"?>
<!DOCTYPE queryset PUBLIC "-//OpenACS//DTD XQL 1.0//EN" "/usr/share/emacs/DTDs/xql.dtd">
<!-- packages/intranet-core/tcl/intranet-backup-procs-oracle.xql -->
<!-- @author  (avila@digiteix.com) -->
<!-- @creation-date 2004-10-19 -->

<queryset>
  
  
  <rdbms>
    <type>oracle</type>
    <version>8.1.6</version>
  </rdbms>
  
  <fullquery name="im_import_users.create_user">
    <querytext>
      
    BEGIN
    :1 := acs_user.new(
	username      => :username,
	email	 => :email,
	first_names   => :first_names,
	last_name     => :last_name,
	password      => :password,
	salt	  => :salt
      );
    END;
    </querytext>
  </fullquery>

</queryset>
