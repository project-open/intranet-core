ad_page_contract {

} {
    { return_url "" }
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
if {"" == $return_url} { set return_url "/intranet/admin/backup/index" }


set content_type "text/html"
set http_encoding "iso8859-1"

append content_type "; charset=$http_encoding"

set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"

util_WriteWithExtraOutputHeaders $all_the_headers
ns_startcontent -type $content_type

ns_write "[im_header] [im_navbar]"
ns_write "<pre>"


# ---------------------------------------------------------------
# Install TSearch2
# ---------------------------------------------------------------


set psql_version [im_database_version]
set pageroot [ns_info pageroot]
set serverroot [join [lrange [split $pageroot "/"] 0 end-1] "/"]
set search_sql_dir "$serverroot/packages/intranet-search-pg/sql/postgresql"


ns_write "<br><h1>Uninstall the search tables</h1>\n"
set sql_file "$search_sql_dir/intranet-search-pg-drop.sql"
set result ""
catch { db_source_sql_file -callback apm_ns_write_callback $sql_file } err

ns_write "<br><h1>Uninstall the previous TSearch2 engines</h1>\n"
set sql_file "$search_sql_dir/untsearch2.8.0.8.sql"
ns_write "<li>Uninstall $sql_file</li>\n"
catch { db_source_sql_file $sql_file } err
set sql_file "$search_sql_dir/untsearch2.8.1.23.sql"
ns_write "<li>Uninstall $sql_file</li>\n"
catch { db_source_sql_file $sql_file } err
set sql_file "$search_sql_dir/untsearch2.8.2.15.sql"
ns_write "<li>Uninstall $sql_file</li>\n"
catch { db_source_sql_file $sql_file } err
set sql_file "$search_sql_dir/untsearch2.8.4.9.sql"
ns_write "<li>Uninstall $sql_file</li>\n"
catch { db_source_sql_file $sql_file } err


ns_write "<br><h1>Install the right TSearch2 version</h1>\n"
set sql_file "$search_sql_dir/tsearch2.${psql_version}.sql"
if {[catch { 
    ns_write "<li>Install $sql_file</li>\n"
    db_source_sql_file -callback apm_ns_write_callback $sql_file
} err]} {
    ns_write "<liError:<pre>$err</pre></li>\n"
}

ns_write "<br><h1>Install triggers etc.</h1>\n"
set sql_file "$search_sql_dir/intranet-search-pg-create.sql"
catch { db_source_sql_file -callback apm_ns_write_callback $sql_file } err


ns_write "</pre><h1>Finished</h1>\n"
ns_write "<p><a href=$return_url>Return to the previous page</h1></p>\n"
ns_write "[im_footer]\n"

