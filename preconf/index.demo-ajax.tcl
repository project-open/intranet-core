

# ---------------------------------------------------------
# Get the first part of the host name from the HTTP headers
#
set header_vars [ns_conn headers]
set host ""
foreach var [ad_ns_set_keys $header_vars] {
    if {"Host" == $var} { 
	set host [ns_set get $header_vars $var]
    }
}
set host [lindex [split $host "."] 0]


# ---------------------------------------------------------
# Get the server name from the configuration
#
set server [ns_info server]


# ---------------------------------------------------------
# Redirect to index-userselect if we're on the right server already
#
ns_log Notice "index.tcl: Host=$host"
ns_log Notice "index.tcl: Server=$server"
if {$host == $server} {
    ad_returnredirect "/index-userselect"
}

