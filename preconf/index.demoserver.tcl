ad_page_contract {
    Index page for all po40xxxx.project-open.net demo servers.
    The page will provide the user with different texts depending
    on the server.
    @cvs-id $Id$
} {
    {authority_id ""}
    {username ""}
    {email ""}
    {return_url "/intranet/"}
}

# The (system) name of the server
set server [ns_info server]

switch $server {
    po40demo { set servername "All-Features" }
    po40cons { set servername "Consulting Companies" }
    po40itsm { set servername "IT Services Management" }
    po40ppm { set servername "Project &amp; Portfolio Management" }
    default { set servername $server }
}