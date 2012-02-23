# /packages/intranet-core/tcl/intranet-alert-procs.tcl
#
# Copyright (C) 1998-2006 various parties
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

ad_proc -public im_send_alert {target_id frequency subject {message ""} } {
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
    set sender_email [ad_parameter -package_id [ad_acs_kernel_id] SystemOwner "" [ad_system_owner]]
    if [catch {
        set sender_email [db_string sender_email "select email as sender_email from parties where party_id = :current_user_id" -default $sender_email]
    } errmsg] {
        ns_log Notice "im_send_alert: Error determining email for sender $current_user_id: $errmsg"
	ad_return_complaint 1 "Error determining email for sender $current_user_id:<br>
        <pre>$errmsg</pre>"
	return
    }

    # Send out the mail
    if [catch {
        ns_sendmail $email $sender_email $subject $message
    } errmsg] {
        ns_log Notice "im_send_alert: Error sending to \"$email\": $errmsg"

#	ad_return_complaint 1 " Error sending email to '$email':<br>
#        <pre>$errmsg</pre>"
#	return

    } else {
        ns_log Notice "im_send_alert: Sent mail to $email\n"
    }
}


ad_proc -public im_security_alert_check_integer {
    { -location "No location specified"}
    { -value "No value specified" }
} {
    Check of a parameter has the form of an integer list,
    which includes the empty list and a single integer.
} {
    foreach v $value {
	if {![string is integer $v]} {
	    im_security_alert \
		-location $location \
		-message "Found non-integer in integer argument" \
		-value $value \
		-severity "Normal" \
	}
    }
}


ad_proc -public im_security_alert_check_tmpnam {
    { -location "No location specified"}
    { -value "No value specified" }
} {
    Check a temporary file created from ns_tmpnam if it
    has been tempered with.
    We assume that temporary files are all created in the
    same folder, so we'll just check if the file contains
    the same folder prefix then a sample ns_tmpnam created
    here.
} {
    # Get a correct sample value
    set ref [ns_tmpnam]

    set value_path [lrange [split $value "/"] 0 end-1]
    set ref_path [lrange [split $ref "/"] 0 end-1]

    if {$value_path != $ref_path} {
	im_security_alert \
	    -location $location \
	    -message "Found a ns_tmpnam in a wrong folder" \
	    -value $value \
	    -severity "Normal" \
    }
}


ad_proc -public im_security_alert {
    { -location "No location specified"}
    { -message "No message specified"}
    { -value "No value specified" }
    { -severity "Normal" }
} {
    Message sent out to the SysAdmin in case of an attempted security breach.
} {
    # Information about the current system
    # That' interesting, if the security manager manages several systems
    set system_name [ad_system_name]
    set system_owner_email [ad_parameter -package_id [im_package_forum_id] ReportThisErrorEmail]

    # Send where?
    set target_email [ad_parameter -package_id [im_package_core_id] SecurityBreachEmail -default "frank.bergmann@project-open.com"]

    # Extract variables from form and HTTP header
    set header_vars [ns_conn headers]
    set url [ns_conn url]

    # Get intersting info
    set user_id [ad_get_user_id]
    set user_name [db_string uname "select im_name_from_user_id(:user_id)" -default "unknown"]
    set client_ip [ns_set get $header_vars "Client-ip"]
    set referer_url [ns_set get $header_vars "Referer"]
    set peer_ip [ns_conn peeraddr]
    set system_id [im_system_id]

    # Subject and body
    set subject [lang::message::lookup "" intranet-core.Security_breach_subject "%severity% Security Breach Attempt in %system_name%"]

    set body "$subject

In: $location
SystemID: $system_id
At: $system_name
Managed by: $system_owner_email
Message: $message
Value: $value
client_ip: $client_ip
referer_url: $referer_url
peer_ip: $peer_ip
"    
    
    append body "\nHTTP Header Vars:\n"
    foreach var [ad_ns_set_keys $header_vars] {
	set value [ns_set get $header_vars $var]
	append body "$var: $value\n"
    }

    # Ignore errors sending out mails...
    catch { 
	ns_sendmail $target_email $system_owner_email $subject $body 
    }


    # Write a log entry for the security alert
    set ip_addr $peer_ip
    if {[info exists header_vars(X-Forwarded-For)]} {
	set ip_addr $header_vars(X-Forwarded-For)
    }
    catch {
	db_string log_alert "SELECT acs_log__warn(:$ip_addr, 'Security breach: location: $location, value: $value, message: $message')"
    }

}


ad_proc -public im_send_alert_to_system_owner {subject message} {
    set system_owner_email [ad_parameter -package_id [im_package_forum_id] ReportThisErrorEmail]
    set current_user_id [ad_get_user_id]
    ns_sendmail $system_owner_email $system_owner_email $subject $message
}

