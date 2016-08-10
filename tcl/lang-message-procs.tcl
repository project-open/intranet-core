#/packages/acs-lang/tcl/lang-message-procs.tcl
ad_library {  

    Additional ]po[ routines for acs-lang messages.
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @cvs-id $Id$
}

namespace eval lang::message {}


ad_proc -public lang::message::register_remote {
    {-update_sync:boolean}
    {-upgrade_status "no_upgrade"}
    {-conflict:boolean}
    {-comment ""}
    locale
    package_key
    message_key
    message
} {
    <p>
    Submits the translation to the translation server.
    </p>
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @see lang::message::register for parameters
} {
    # Send a message to the language server
    set http_response ""
    if {[catch {
	set package_version [db_string package_version "select max(version_name) from apm_package_versions where package_key = :package_key" -default ""]
	set system_owner_email [parameter::get_from_package_key -package_key "acs-kernel" -parameter "SystemOwner" -default [ad_system_owner]]
	set sender_email [db_string sender_email "select email as sender_email from parties where party_id = [auth::require_login]" -default $system_owner_email]
	set sender_first_names [db_string sender_email "select first_names from persons where person_id = [auth::require_login]" -default "System"]
	set sender_last_name [db_string sender_email "select last_name from persons where person_id = [auth::require_login]" -default "Administrator"]
	set lang_server_base_url "http://l10n.project-open.net/acs-lang-server/lang-message-register"
	set lang_server_base_url [parameter::get_from_package_key -package_key "acs-lang" -parameter "LangServerURL" -default $lang_server_base_url]
	set lang_server_timeout [parameter::get_from_package_key -package_key "acs-lang" -parameter "LangServerTimeout" -default 5]
	set lang_server_url [export_vars -base $lang_server_base_url {locale package_key message_key message comment package_version sender_email sender_first_names sender_last_name}]

	set http_response [ns_httpget $lang_server_url $lang_server_timeout]

    } err_msg]} {

	ad_return_complaint 1 "<b>lang::message::register_remote: Error Submitting Translation</b>:$
		<pre>$err_msg</pre>
		While executing the command:<br>
		<pre>ns_httpget $lang_server_url $lang_server_timeout</pre>
	"
	ad_script_abort
    }

    return http_response
}


