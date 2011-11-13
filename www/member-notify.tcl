# /packages/intranet-core/www/member-notify.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.


ad_page_contract {
    Sends an email with an attachment to a user

    @param user_id_from_search A list of user_id or note_ids
    @subject A subject line
    @message A message that can be either plain text or html
    @message_mime_type "text/plain" or "text/html"
    @attachment A plaint text file to attach. This only works
	if the file is a text file such as .txt or .pdf
    @attachment_filename How should the attachment appear in the
	user's mail client?
    @attachment_mime_type Should go together with the extension
	of the attachment_filename
    @send_me_a_copy Should be different from "" in order to send
	a copy to the sender.
    @return_url Where whould the script go after finishing its
	task?

    @author Frank Bergmann
} {
    user_id_from_search:integer,multiple,optional
    {subject:notnull "Subject"}
    {message:allhtml "Message"}
    {message_mime_type "text/plain"}
    {attachment:allhtml ""}
    {attachment_filename ""}
    {attachment_mime_type ""}
    {send_me_a_copy ""}
    return_url
    {process_mail_queue_now_p 1}
    {from_email ""}
}

if {![info exists user_id_from_search]} { set user_id_from_search "-999" }

ns_log Notice "subject='$subject'"
ns_log Notice "message_mime_type='$message_mime_type'"
ns_log Notice "attachment_filename='$attachment_filename'"
ns_log Notice "attachment_mime_type='$attachment_mime_type'"
ns_log Notice "send_me_a_copy='$send_me_a_copy'"
ns_log Notice "return_url='$return_url'"
ns_log Notice "process_mail_queue_now_p='$process_mail_queue_now_p'"
ns_log Notice "message='$message'"
ns_log Notice "attachment='$attachment'"


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set ip_addr [ad_conn peeraddr]
set locale [ad_conn locale]
set creation_ip [ad_conn peeraddr]

set time_date [exec date "+%s.%N"]

foreach oid $user_id_from_search {

    set object_type [util_memoize "acs_object_type $oid"]
    switch $object_type {
	user {
	    im_user_permissions $current_user_id $oid view read write admin
	}
	im_note {
	    set note_user_id [db_string note_user_id "select object_id from im_notes where note_id = :oid" -default ""]
	    im_user_permissions $current_user_id $note_user_id view read write admin
	}
	default {
	    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient]"
	}
    }

    if {!$read} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient]"
	return
    }
}


# Determine the sender address
set sender_email [ad_parameter -package_id [ad_acs_kernel_id] SystemOwner "" [ad_system_owner]]
catch {set sender_email [db_string sender_email "select email as sender_email from parties where party_id = :current_user_id" -default $sender_email]}

# Trim the subject. Otherwise we'll get MIME-garbage
set subject [string trim $subject]


# ---------------------------------------------------------------
# Deal with Attachments
# ---------------------------------------------------------------

# Save an text attachment to a temporary file

if {"" != $attachment} {
    set package_id [db_string package_id {select package_id from apm_packages where package_key='acs-workflow'}]
    set tmp_path [ad_parameter -package_id $package_id "tmp_path"]
    set tmp_file [ns_mktemp "$tmp_path/attachment_XXXXXX"]

    if {[catch {
	set fl [open $tmp_file "w"]
	puts $fl $attachment
	close $fl
    } err]} {
	ad_return_complaint 1 "<b>Unable to write to $tmp_file</b>:<br><pre>\n$err</pre>"
	ad_script_abort
    }

    if {"" == $attachment_filename} {
	set attachment_filename $tmp_file
    }
}

# Import the file into the content repository.
# This is necessary for sending it out via Email
set attachment_ci_id ""
if {"" != $attachment_filename && "" != $user_id_from_search} {

    # Remove strange characters from filename
    regsub -all {[^a-zA-Z0-9_\.]} $attachment_filename "_" attachment_filename

    # Check if the file is already there
    set parent_id [lindex $user_id_from_search 0]
    set attachment_ci_id [db_string attachment_exists "
	select	item_id
	from	cr_items
	where	parent_id = :parent_id and
		name = :attachment_filename
    " -default ""]

    if { "" != $attachment_ci_id } {
	if {[catch { db_dml delete_cr_item "select content_item__del($attachment_ci_id)" } errmsg ]} {}
    }

    set attachment_ci_id [cr_import_content \
				  -title $attachment_filename \
				  $parent_id \
				  $tmp_file \
				  [file size $tmp_file] \
				  $attachment_mime_type \
				  $attachment_filename \
    ]

    file delete $tmp_file
}


# ---------------------------------------------------------------
# Send to whom?
# ---------------------------------------------------------------


# Get user list and email list
set email_list [db_list email_list "
	select	lower(trim(email))
	from	parties
	where	party_id in ([join $user_id_from_search ","])
    UNION
	select	lower(trim(note))
	from	im_notes
	where	note_id in ([join $user_id_from_search ","])
"]


# Include a copy to myself?
if {"" != $send_me_a_copy} {
    lappend email_list [db_string user_email "select email from parties where party_id = :current_user_id"]
}

if {"" == $from_email} {
    set from_email [db_string from_email "select email from parties where party_id = :current_user_id"]
}



# ---------------------------------------------------------------
# Create the message and queue it
# ---------------------------------------------------------------


# send to contacts
foreach email $email_list {

    ns_log Notice "member-notify: Sending out to email: '$email'"

    # Replace message %xxx% variables by user's variables
    set message_subst $message
    set found_p 0
    db_0or1row user_info "
	select	pe.person_id as user_id,
		im_name_from_user_id(pe.person_id) as name,
		first_names,
		last_name,
		email,
		1 as found_p
	from	persons pe,
		parties pa
	where	pe.person_id = pa.party_id and
		lower(pa.email) = :email
    "

    if {$found_p} {
	set auto_login [im_generate_auto_login -user_id $user_id]
	set substitution_list [list \
				   name $name \
				   first_names $first_names \
				   last_name $last_name \
				   email $email \
				   auto_login $auto_login \
	]
	set message_subst [lang::message::format $message $substitution_list]
    }

    if {[catch {
	acs_mail_lite::send \
	    -send_immediately \
	    -to_addr $email \
	    -from_addr $sender_email \
	    -subject $subject \
	    -body $message_subst \
	    -file_ids $attachment_ci_id
    } errmsg]} {
        ns_log Error "member-notify: Error sending to \"$email\": $errmsg"
	ad_return_error $subject "<p>Error sending out mail:</p><div><code>[ad_quotehtml $errmsg]</code></div>"
	ad_script_abort
    }
}


# ---------------------------------------------------------------
# Process the mail queue right now
# ---------------------------------------------------------------

if {$process_mail_queue_now_p} {
    acs_mail_process_queue
}

# ---------------------------------------------------------------
# This page has not confirmation screen but just returns
# ---------------------------------------------------------------

ad_returnredirect $return_url

