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
ad_proc im_send_alert {target_id frequency subject {message ""} } {
    Add a new alert to the queue for a specific user.
    The idea is to aggregate several alerts into a single email,
    to avoid hundereds or emails, for example if a user has been
    assigned a lot of tasks.
    So "subject" in not suposed to go into the subject of the message
    (except if there is a mail with a single alert), but as an
    intermediate header.
    The "message" is suposed to be plain text only. We are going to
    preserve line break, but we will add a "\t" before each line.
    "Frequency" can be one of: now (minutely), hourly, daily, weekly,
    biweekly, monthly, trimesterly, semesterly, yearly.
} {
    # Quick & Dirty implementation: just send out the mail immediately,
    # until there is more time...

    set current_user_id [ad_get_user_id]

    # Get the email of the target user
    set user_email_sql "select email from parties where party_id = :target_id"
    db_transaction {
        db_1row user_email $user_email_sql
    } on_error {
        ad_return_complaint 1 "<li>[_ intranet-core.lt_Error_getting_the_ema]"
        return
    }

    # Determine the sender address
    set sender_email [ad_parameter -package_id [ad_acs_kernel_id] SystemOwner "" "webmaster@local\
host"]
    if [catch {
        set sender_email [db_string sender_email "select email as sender_email from parties where\
 party_id = :current_user_id" -default "asfd@asdf.com"]
    } errmsg] {
        # nothing - use default
    }


    # Send out the mail
    if [catch {
        ns_sendmail $email $sender_email $subject $message
    } errmsg] {
        ns_log Notice "im_send_alert: Error sending to \"$email\": $errmsg"
    } else {
        ns_log Notice "im_send_alert: Sent mail to $email\n"
    }
}