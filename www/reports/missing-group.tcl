# /www/intranet/reports/missing-group.tcl

ad_page_contract {

    gives a list of people in no offices  or people on no teams.
    it contains links for an administrator to modify this information
    we will simply change the constaint on parent_group_id between [im_office_group_id] and [im_team_group_id]
    May 5, 2000 we will add a convenient way to update information. We will create
    a select list from the database query of office names and group names. 
    we will present a separate checklist for every user, and let the users submit
    this form that will update information for all indicated users.

    @author umathur@arsdigita.com 
    @creation-date May 4, 2000
    @cvs-id missing-group.tcl,v 1.9.2.8 2000/09/22 01:38:46 kevin Exp
} {
    {group_type "office"}
}

set dimensional {
    {group_type "Group Type" office {
	{office "Office" {} }
	{team "Team" {} }
    }
}
}

if { [string compare $group_type "team"] == 0 } {
    set parent_group_id [im_team_group_id]
} else {
    set parent_group_id [im_office_group_id]
}



# here we set the values for the option list 
# we select all the names from the database of the type in question
set option_list_html "<option value=no_update>Update this User</option>"
set bind_vars [ad_tcl_vars_to_ns_set parent_group_id]
append option_list_html [ad_db_optionlist -bind $bind_vars optionlist_group_name_id_statement \
                         "select group_name, group_id 
                          from user_groups 
                          where parent_group_id = :parent_group_id 
                          order by lower(group_name)"]

# we select the option_list_html from the table because we need as a query var to make ad_table work.

set sql_query "select [ns_dbquotevalue $option_list_html] as option_list_from_db, u.first_names ||' '|| u.last_name as name, u.user_id as user_id from im_employees im_ei, users_active u
  where im_ei.user_id = u.user_id
   and 1 > (select count(*) from user_group_map, user_groups               
where user_group_map.user_id = im_ei.user_id 
and user_group_map.group_id in (select group_id from user_groups where parent_group_id = $parent_group_id)
and user_group_map.group_id = user_groups.group_id)
and exists (select 1 from user_group_map, user_groups
where user_group_map.user_id = im_ei.user_id
and user_group_map.group_id = [im_employee_group_id])
order by lower(last_name)"

set sql_query "select [ns_dbquotevalue $option_list_html]  as option_list_from_db, 
                      u.first_names ||' '|| u.last_name as name, u.user_id as user_id 
               from im_employees im_ei, users_active u
               where im_ei.user_id = u.user_id
                     and 1 > (select count(*) from user_group_map, user_groups               
		              where user_group_map.user_id = im_ei.user_id 
	                            and user_group_map.group_id in (select group_id 
                                                                    from user_groups 
                                                                    where parent_group_id = $parent_group_id)
	                            and user_group_map.group_id = user_groups.group_id)
	              and exists (select 1 from user_group_map, user_groups
	                          where user_group_map.user_id = im_ei.user_id
	                                and user_group_map.group_id = [im_employee_group_id])
                      order by lower(last_name)"


set table_def {
    {name "User Name" no_sort {<td><a href=[im_url_stub]/employees/admin/view?user_id=$user_id>$name</a></td>}}
    {user_id "Modify This User" no_sort {<td><select name=user.$user_id>$option_list_from_db</select></td> }}
}

set context_bar [ad_context_bar [list [im_url_stub]/reports/ Reports] "Missing $group_type"]

set return_html "[im_header "Missing $group_type exceptions"]
[ad_dimensional $dimensional]
<form action=missing-group-2>
[export_form_vars group_type]
[ad_table -Tmissing_text "<em>No employees were found that didn't belong to a $group_type</em><br>" \
          table_statement_1 $sql_query $table_def]
<br>
<input type=submit value=\"Update Information\">
</form>
[im_footer]"


doc_return  200 text/html $return_html

