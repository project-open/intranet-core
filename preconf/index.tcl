ad_page_contract {
    Prompt the user for email and password.
    @cvs-id $Id$
} {
    {authority_id ""}
    {username ""}
    {email ""}
    {return_url "/intranet/"}
}

# ------------------------------------------------------
# Multirow
# Users defined in the database
# ------------------------------------------------------

set query "
        select
		p.*,
		u.*,
		pa.*,
		CASE WHEN demo_group = 'Administrators' THEN 10
		     WHEN demo_group = 'Senior Managers' THEN 20
		     WHEN demo_group = 'Accounting' THEN 30
		     WHEN demo_group = 'Sales' THEN 40
		     WHEN demo_group = 'Project Managers' THEN 50
		ELSE 100 END as sort_order
        from
		persons p,
		parties pa,
		users u
        where
		p.person_id = pa.party_id
		and p.person_id = u.user_id
		and p.demo_password is not null
        order by
		sort_order,
                p.demo_group,
		u.user_id
"

set demo_group_exists_p [db_string dg "select count(*) from user_tab_columns where table_name = 'PERSONS' and column_name = 'DEMO_GROUP'"]

if {!$demo_group_exists_p} {
    set query "
        select
		p.*,
		u.*,
		pa.*,
		p.person_id as sort_order,
		'Default Group' as demo_group,
		'-' as demo_password
        from
		persons p,
		parties pa,
		users u
        where
		p.person_id = pa.party_id
		and p.person_id = u.user_id
        order by
		sort_order,
		u.user_id
	LIMIT 20
    "
}



set old_demo_group ""
db_multirow -extend {view_url} users users_query $query {
    set view_url ""
}


# ------------------------------------------------------
# Get current user email

set email [db_string email "select email from parties where party_id=[ad_get_user_id]" -default ""]

