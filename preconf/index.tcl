ad_page_contract {
    Prompt the user for email and password.
    @cvs-id $Id$
} {
    {authority_id ""}
    {username ""}
    {email ""}
    {return_url "/intranet/"}
}

set email_org $email
set username_org $username

# ------------------------------------------------------
# Multirow
# Users defined in the database
# ------------------------------------------------------

set query "
        select
		p.*,
		u.*,
		pa.*,
		im_name_from_user_id(p.person_id) as user_name
        from
		persons p,
		parties pa,
		users u
        where
		p.person_id = pa.party_id
		and p.person_id = u.user_id
		and demo_password is not null
        order by
		demo_sort_order,
		u.user_id
	LIMIT 20
"

set old_demo_group ""
db_multirow -extend {view_url} users users_query $query {
    set view_url ""
}

# ------------------------------------------------------
# Get current user email

set username $username_org
set email $email_org
set current_user_id [ad_conn untrusted_user_id]

if {"" == $email} {
    set email [db_string email "
	select email 
	from parties 
	where party_id = :current_user_id and party_id > 0
    " -default ""]
}

if {"" == $username} {
    set username [db_string username "
	select username 
	from users
	where user_id = :current_user_id and user_id > 0
    " -default ""]
}

