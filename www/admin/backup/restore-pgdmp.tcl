ad_page_contract {
    Takes a database dump and loads the dump into the database.
    @param drop_cascade_p will perform a "drop cascade" on several
    tables that might resist the normal restore process if they
    were created with a different ]po[ version
} {
    filename
    return_url
    { drop_cascade_p 1 }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set server_name [ns_info server]
set filename [im_backup_path]/[file tail $filename]
set extension [file extension $filename]
set err ""

# Determine platfor (Windows/Linux/...)
global tcl_platform
set platform [lindex $tcl_platform(platform) 0]

ns_log Debug "restoring pgdmp file: $filename"


# Delete important system tables in order to avoid restore issues
if {$drop_cascade_p} {
    catch { db_dml drop_im_projects "drop table im_project CASCADE" }
    catch { db_dml drop_im_categories "drop table im_categories CASCADE" }
    catch { db_dml drop_parties "drop table parties CASCADE" }
    catch { db_dml drop_acs_objects "drop table acs_objects CASCADE" }

    # Drop any remaining table
    set tables [db_list tables "select tablename from pg_tables where tablename not like 'pg_%' and tablename not like 'sql_%'"]
    foreach table $tables {
	catch { db_dml drop_$table "drop table $table CASCADE" }
    }
}

switch $extension {
    ".pgdmp" {
	switch $platform {
	    windows { catch { exec pg_restore -U postgres --dbname $server_name --no-owner --clean $filename } err }
	    default { catch { exec pg_restore --dbname $server_name --no-owner --clean $filename } err }
	}
    }
    ".sql" {
	switch $platform {
	    windows { catch { exec psql -U postgres --dbname $server_name --file $filename } err }
	    default { catch { 
		exec psql --dbname $server_name --file $filename 
	    } err }
	}
    }
    ".bz2" {
	set err "File in '.bz2' format: Please uncompress manually and retry"
    }
    ".gz" {
	set err "File in '.gz' format: Please uncompress manually and retry"
    }
    default {
	set err "pg_dump format '$extension' not supported"
    }
}

if {$err==""} {
    ad_returnredirect
} else {
    ad_return_top_of_page "[im_header]\n[im_navbar]"
    
    ns_write "<h2>Messages During Import</h2><pre>$err</pre>"
    ns_write "<a href=\"$return_url\">back to list</a>"
    ns_write [im_footer]
}


