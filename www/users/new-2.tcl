# /www/admin/users/user-add-2.tcl

ad_page_contract {
    Add a new user to the database.
} {
    user_id:integer,notnull
    email:notnull
    first_names:notnull
    last_name:notnull
    {password ""}
    {password_confirmation ""}
    profile:multiple
}

set current_user_id [ad_maybe_redirect_for_registration]
set page_title "Add User (2)"
set context_bar [ad_context_bar [list "/intranet/users/index" "Users"] $page_title]
set page_focus "im_header_form.keywords"



# ---------------------------------------------------------------
# Checking info
# ---------------------------------------------------------------


# Input check error count and list
set exception_count 0
set exception_text ""

if {![info exists email] || ![philg_email_valid_p $email]} {
    incr exception_count
    append exception_text "
    <li>The email address that you typed doesn't look right to us.
    Examples of valid email addresses are  
    <ul>
    <li>Alice1234@aol.com
    <li>joe_smith@hp.com
    <li>pierre@inria.fr
    </ul>
    "
} else {

    set email_count [db_string count_users_by_email "
	select count(email)
	from   users where upper(email) = upper(:email) 
	and    user_id <> :user_id"]

    # note, we don't produce an error if this is a double click
    if {$email_count > 0} {
	incr exception_count
	append exception_text "<li> $email was already in the database."
    }
}

if {![info exists first_names] || [empty_string_p $first_names]} {
    incr exception_count
    append exception_text "<li> You didn't enter a first name."
}

if {![info exists last_name] || [empty_string_p $last_name]} {
    incr exception_count
    append exception_text "<li> You didn't enter a last name."
}

if { ![string equal $password $password_confirmation] } {
    incr exception_count
    append exception_text "<li> The two passwords didn't match."
}

# We've checked everything.
# If we have an error, return error page, otherwise, do the insert

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

if { [empty_string_p $password] } {
    set password [ad_generate_random_string]
}

# ---------------------------------------------------------------
# Inserting Baisic in users
# ---------------------------------------------------------------


# If we are encrypting passwords in the database, convert
if  [ad_parameter EncryptPasswordsInDBP "" 0] { 
    set password_for_database [ns_crypt $password [ad_crypt_salt]]
} else {
    set password_for_database $password
}

set registration_ip [ns_conn peeraddr]

set insert_statement  ""

if [catch { db_dml insert_user {
insert into users 
    (user_id,
     email,
     password,
     first_names,
     last_name,
     registration_date,
     registration_ip, 
     user_state) 
values 
    (:user_id,
     :email,
     :password_for_database, 
     :first_names,
     :last_name, 
      sysdate, 
     :registration_ip, 
     'authorized')
} } errmsg] {

# if it was not a double click, produce an error
    if { [db_string count_user_id "select count(user_id) from users where user_id = :user_id"] == 0 } {
	ad_return_error "
	<p>Insert Failed" "We were unable to create your user record
	in the database.  Here's what the error looked like: 
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>"
	return 
     }
}

# ----------------------------------------------------------
# add to groups from his profile
# ----------------------------------------------------------

foreach profile_group_id $profile {

    db_transaction {

	# don't allow for duplicate roles between user and group,
	# so just delete any previous relationships.
	#
	db_dml user_group_delete \
		"delete from user_group_map 
		where group_id = :profile_group_id
		and user_id = :user_id"
	
	db_dml user_group_insert \
		"insert into user_group_map values
		(:profile_group_id, :user_id, 'member',
		sysdate, 1, '0.0.0.0')"
    }
}

if { $profile_group_id==14 } {
    if [catch { db_dml insert_freelance {

insert into im_freelancers
    (user_id)
values
    (:user_id)
    } } errmsg] {

# if it was not a double click, produce an error
	if { [db_string count_freelance_id "select count(user_id) from im_freelancers where user_id = :user_id"] == 0 } {
        ad_return_error "
        <p>Insert Failed" "We were unable to create your user record
        in the database.  Here's what the error looked like:
        <blockquote>
        <pre>
        $errmsg
        </pre>
        </blockquote>"
        return
     }
    }
}


# 040208 fraber: Employees move to new HR module
if {0} {

# Add the user to "employees" if specified
if {[lsearch -exact $profile [im_employee_group_id]]} {
    db_dml insert_start_date {
            insert into im_employees (user_id, start_date)
            select :user_id, sysdate from dual
            where not exists (select user_id from im_employees
                              where user_id=:user_id)
    }
}

}

# ----------------------------------------------------------
# Prepare message to send the new member
# ----------------------------------------------------------

set administration_name [db_string user_name_select "
select first_names || ' ' || last_name 
from   users 
where  user_id = :current_user_id"]

set body_message_html "
<hr>

$first_names $last_name has been added to [ad_system_name].<BR>
Edit the message below and hit \"Send Email\" to notify this user.
<p>
<form method=POST action=new-3>
[export_form_vars email first_names last_name user_id]

<p>Message:

<blockquote>
<textarea name=message rows=10 cols=70 wrap=hard>
$first_names $last_name, 

You have been added as a user to [ad_system_name] 
at [ad_parameter SystemUrl].

Login information:
Email: $email
Password: $password 
(you may change your password after you log in)

Thank you,
$administration_name
</textarea>
</blockquote>

<p>

<center>
  <input type=submit name=submit value=\"Send Email\">
  <input type=submit name=submit value=\"Don't Send Email\">
</center>

</form>"

# ---------------------------------------------------------------
# Join all the parts together
# ---------------------------------------------------------------
set page_body "
$body_message_html
"

doc_return  200 text/html [im_return_template]
