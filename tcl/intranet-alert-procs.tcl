# /packages/intranet-core/tcl/intranet-alerts.tcl
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


ad_library {
    API for sending out email alerts for various Intranet functions
    
    @author unknown@arsdigita.com
    @author frank.bergmann@project-open.com
}

# -------------------------------------------------------------------
# Add an alert to the database alert queue
# -------------------------------------------------------------------

ad_proc im_send_alert {target_id frequency url subject {message ""} } {
    Add a new alert to the queue for a specific user.
    The idea is to aggregate several alerts into a single email,
    to avoid hundereds or emails, for example if a user has been
    assigned a lot of tasks.
    So "Subject" in not suposed to go into the subject of the message
    (except if there is a mail with a single alert), but as an
    intermediate header.
    The "url" has to be provided to the user, so that he gets directed
    to the right page immediately.
    The "message" is suposed to be plain text only. We are going to
    preserve line break, but we will add a "\t" before each line.
    "Frequency" can be one of: now (minutely), hourly, daily, weekly, 
    biweekly, monthly, trimesterly, semesterly, yearly.
} {
    # Quick & Dirty implementation: just send out the mail immediately,
    # until there is more time...

    # Get the email of the target user
    set user_email_sql "select email from users where user_id=:target_id"
    db_transaction {
	db_1row user_email $user_email_sql
    } on_error {
	set email "webmaster@project-open.com"
    }

    # Determine the sender address
    set sender_email [ad_parameter SystemOwner "" "webmaster@localhost"]

    # Compile the message from various alerts
    set msg_body "Subject: $subject
URL: $url
Message:
"
    # Append the message with tabulators "\t" before each line
    set message_lines [split $message "\n"]
    foreach message_line $message_lines {
	append msg_body "\t$message_line\n"
    }
    append msg_body "\n"

    # Send out the mail
    if [catch { 
	ns_sendmail $email $sender_email $subject $msg_body
    } errmsg] {
	ns_log Notice "im_send_alert: Error sending to \"$email\": $errmsg"
    } else {
	ns_log Notice "im_send_alert: Sent mail to $email\n"
    }
}
