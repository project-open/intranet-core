# /www/intranet/reports/multiple-group.tcl

ad_page_contract {
    umathur@arsdigita.com on May 1, 2000
    gives a list of people in more than one office
    or people in more than one team.
    it contains links for an administrator to modify this information

    @param group_type
    @author umathur@arsdigita.com 
    @creation-date May 1, 2000

    @csv-id multiple-group.tcl,v 1.9.2.9 2000/09/22 01:38:46 kevin Exp
} {
   {group_type "office"}
}

#we can add other parameters to the dimensional list corresponding to other
#parent_group_id

set dimensional {
    {group_type "Group Type" office {
	{office "Office" {} }
	{team "Team" {} }
    }
}
}

set table_def {
    {name "User Name" no_sort {<td><a href=/intranet/employees/admin/view?user_id=$user_id>$name</a></td>}}
    {user_id "User Id" no_sort}
}

if { [string compare $group_type "team"] == 0 } {
    set parent_group_id [im_team_group_id]
} else {
    set parent_group_id [im_office_group_id]
}

# this query finds all users in multiple groups of a fixed parent_group_id 
set user_list_query "select u.user_id as user_id 
   from im_employees im_ei, users u
   where im_ei.user_id = u.user_id
   and 1 < (select count(*) from user_group_map, user_groups 
              where user_group_map.user_id = im_ei.user_id 
              and user_group_map.group_id in 
                  (select group_id from user_groups where parent_group_id = :parent_group_id)
              and user_group_map.group_id = user_groups.group_id 
              and lower(user_group_map.role) != 'secondary')"
 
set context_bar [ad_context_bar [list [im_url_stub]/reports/ Reports] "Multiple $group_type"]

set return_html "[im_header "Multiple $group_type exceptions"]
[ad_dimensional $dimensional]
<form action=multiple-group-2?><ul>
[export_form_vars group_type]
"

set user_in_multiple_offices_list [db_list user_list_statement $user_list_query]

set counter 0
foreach user_in_multiple_offices $user_in_multiple_offices_list {
    append return_html "<li><a href=[im_url_stub]/employees/admin/view?user_id=$user_in_multiple_offices>[db_string select_name "select first_names||' '||last_name from users where user_id = $user_in_multiple_offices"]</a><br>"
    incr counter
    set group_list_for_user_query "select ug.group_id, ug.group_name 
                from user_groups ug, user_group_map ugm 
                where ugm.user_id = :user_in_multiple_offices and ug.group_id=ugm.group_id 
                and ug.parent_group_id = :parent_group_id
                and lower(ugm.role) != 'secondary'"

     set group_list [db_list_of_lists multible_offices_user_statement $group_list_for_user_query]
    
    foreach group $group_list {
    append return_html "<input type=radio name=user.$user_in_multiple_offices value=[lindex $group 0]>[lindex $group 1] &nbsp;"
    }
}

if {$counter == 0 } {
    append return_html "</ul>No users found"
} else {
    append return_html "</ul>
<center>
<input type=submit value=Update>
</center>"
}

append return_html "
<p>
Select primary group for each user above.<br> 
The role in the remaining groups will be updated to 'secondary' so that
the user doesn't show up in reports of office size. 
If no group is selected, the user's information will remain unchanged
[im_footer]"

doc_return  200 text/html $return_html

