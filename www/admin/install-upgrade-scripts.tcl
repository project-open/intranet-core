ad_page_contract {

    Run upgrade scripts.

    This is part of the V3.3 installer that allows to check for non-run
    upgrade scripts during an update from V3.1 - V3.3

    @author frank.bergmann@project-open.com
    @creation-date Mon Oct  9 00:13:43 2008
    @cvs-id $Id$
} {
    {upgrade_script:multiple ""}
}

# Write out HTTP headers. The db_source_sql_file script will write
# into the session directly via ns_write...
set output_format "html"
set content_type "text/html"
set http_encoding "utf-8"
append content_type "; charset=$http_encoding"
set all_the_headers "HTTP/1.0 200 OK\nMIME-Version: 1.0\nContent-Type: $content_type\r\n"
util_WriteWithExtraOutputHeaders $all_the_headers
ReturnHeaders $content_type

ns_write [im_header]
ns_write [im_navbar]
ns_write "<h1>Running Upgrade Scripts</h1>\n"
ns_write "<ul>\n"

foreach script [lsort $upgrade_script] {

    # Add the "/packages/..." part to hash-array for fast comparison.
    if {[regexp {(/packages.*)} $script match script_body]} {

	set script_file "[acs_root_dir]$script_body"
	ns_write "<li>$script_file\n"
	ns_write "<pre>\n"
	db_source_sql_file -callback apm_ns_write_callback $script_file
	ns_write "</pre>\n"
    }
}

ns_write "</ul>\n"
ns_write "<p>Successfully finished running upgrade scripts.</p>\n"
ns_write [im_footer]
