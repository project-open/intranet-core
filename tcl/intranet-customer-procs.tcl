# /tcl/intranet-customer-components.tcl

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Customers.
    @author fraber@fraber.de
    @creation-date  27 June 2003
}


ad_proc -public im_customer_type_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the project_types in the system
} {
    return [im_category_select "Intranet Customer Type" $select_name $default]
}


ad_proc -public im_customer_contact_select { select_name { default "" } {customer_id "201"} } {
    Returns an html select box named $select_name and defaulted to 
    $default with the list of all avaiable contact persons of a given
    customer
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars customer_id $customer_id

    set query "
select
        u.user_id,
        u.first_names||' '||u.last_name as user_name
from
        users u,
        user_group_map m
where
        u.user_id = m.user_id and
        group_id=:customer_id and
	u.user_id not in (
		select u.user_id
		from users u, user_group_map m
		where	u.user_id=m.user_id and
			m.group_id=9
	)
"
    return [im_selection_to_select_box $bind_vars customer_contact_select $query $select_name $default]
}


ad_proc -public im_customer_select { select_name { default "" } { status "" } { exclude_status "" } } {
    
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the customers in the system. If status is
    specified, we limit the select box to customers that match that
    status. If exclude status is provided, we limit to states that do not
    match exclude_status (list of statuses to exclude).

} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars customer_group_id [im_customer_group_id]

    set sql "
select
	c.customer_id,
	c.customer_name
from
	im_customers c
where
	c.customer_status_id!=48
"
    if { ![empty_string_p $status] } {
	ns_set put $bind_vars status $status
	append sql " and customer_status_id=(select customer_status_id from im_customer_status where customer_status=:status)"
    }

    if { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars customer_status_type $exclude_status]
	append sql " and customer_status_id in (select customer_status_id 
                                                  from im_customer_status 
                                                 where customer_status not in ($exclude_string)) "
    }
    append sql " order by lower(c.customer_name)"
    return [im_selection_to_select_box $bind_vars "customer_status_select" $sql $select_name $default]
}


ad_proc -public im_customer_status_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to 
    $default with a list of all the customer status_types in the system
} {
    return [im_category_select "Intranet Customer Status" $select_name $default]
}


ad_proc -public im_customer_type_select { select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the customer types in the system} {
    return [im_category_select "Intranet Customer Type" $select_name $default]
}







