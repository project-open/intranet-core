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

    @param user_id_from_search A user id
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
    user_id_from_search:integer,multiple
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

foreach uid $user_id_from_search {
    im_user_permissions $current_user_id $uid view read write admin
    if {!$read} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient]"
	return
    }
}

# ---------------------------------------------------------------
# Send to whom?
# ---------------------------------------------------------------


# Get user list and email list
set email_list [db_list email_list "select email from parties where party_id in ([join $user_id_from_search ","])"]

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

    db_transaction {

	# create the multipart message ('multipart/mixed')
	set multipart_id [acs_mail_multipart_new -multipart_kind "mixed"]
	ns_log Notice "member-notify: multipart_id=$multipart_id"

	# ---------------------------------------------------------------    
	# create an acs_mail_body (with content_item_id = multipart_id )
	set body_id [acs_mail_body_new \
			 -header_subject $subject \
			 -content_item_id $multipart_id]
	ns_log Notice "member-notify: body_id=$body_id"
	

	# ---------------------------------------------------------------    
	# Create the main mail "content_item" and
	# add the content_item to the multipart email
	set content_item_name "$subject $time_date $body_id"
	set content_item_id [content::item::new \
				 -name $content_item_name \
				 -title $subject \
				 -mime_type $message_mime_type \
				 -text $message_subst \
				 -storage_type text \
	]
	set sequence_num [acs_mail_multipart_add_content \
			      -multipart_id $multipart_id \
			      -content_item_id $content_item_id]

	ns_log Notice "member-notify: content_item_id=$content_item_id"
	ns_log Notice "member-notify: sequence_num=$sequence_num"

	# ---------------------------------------------------------------    
	# Create the attachment content_item and
	# add the content_item to the multipart email.
	# We execute the multipart-add "manually", because
	# we need to set the "mime_filename" field, so that
	# the attachment shows up with the right filename
	if {"" != $attachment_mime_type} {
	    set content_item_attach_id [content::item::new \
					    -name "$subject $time_date $body_id - attachment1" \
					    -title "$subject" \
					    -mime_type $attachment_mime_type \
					    -text $attachment \
					    -storage_type text \
            ]
	    # Get last multipart sequence no - should be 0
	    set sequence_num [db_string multipart_sequence_nr "
			select max(sequence_number) 
			from acs_mail_multipart_parts 
			where multipart_id = :multipart_id
            " -default 0]
	    db_dml insert_multipart_part "
		    insert into acs_mail_multipart_parts (
			multipart_id, mime_filename, sequence_number, content_item_id
		    ) values (
			:multipart_id, :attachment_filename, :sequence_num + 1, :content_item_attach_id
		    )
            "
	    ns_log Notice "member-notify: content_item_attach_id=$content_item_attach_id"
	    ns_log Notice "member-notify: sequence_num=$sequence_num"
	}
    
	set to_email $email
	if {"" == $to_email} { continue }
	ns_log notice "export-mail: Mailing contact '$email'"
	    
	# Create a message for Queuing 
	set message_id [im_exec_dml create_message "
	acs_mail_queue_message__new (
		null,			-- p_mail_link_id
		:body_id,		-- p_body_id
		null,			-- p_context_id
		now()::date,		-- p_creation_date
		:current_user_id,	-- p_creation_user
		null,			-- p_creation_ip
		'acs_mail_link'	-- p_object_type
	)"]
        ns_log Notice "member-notify: message_id=$message_id"
	    
	db_dml outgoing_queue "
		insert into acs_mail_queue_outgoing ( 
		    message_id, envelope_from, envelope_to 
		) values ( 
		    :message_id, :from_email, :to_email
		)
	"
	ns_log Notice "member-notify-attachment: Outgoing queued for '$email'"
    
    } on_error {
	ad_return_error "[_ parties-extension.unable_to_send_mailshot]" "<pre>$errmsg</pre>"
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

