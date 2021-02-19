# expects:
# object_id
# return_url
# privs:optional, defaults to 'read', 'write', 'admin'
# user_add_url: URL to the page for adding users
# mode 


if { "datatable" == $mode} {
	template::head::add_javascript -src "/intranet/js/jquery.dataTables.js" -order 1
	template::head::add_javascript -src "/intranet/js/FixedColumns.js" -order 1
}

set user_id [ad_conn user_id]

set admin_p [permission::permission_p -object_id $object_id -privilege admin]

if { (![info exists return_url] || $return_url eq "") } {
    set return_url [ad_return_url]
}

if { (![info exists privs] || $privs eq "") } {
    set privs { read create write admin }
}

db_1row object_info {}

set elements [list]
lappend elements grantee_name { 
    label "Name" 
    link_url_col name_url
    display_template {
	<if @permissions.any_perm_p_@ true>
		<nobr>
		@permissions.grantee_name@
		<if "person" eq @permissions.object_type@>
			<a href=perm-delete?party_id=@permissions.grantee_id@>[im_gif del]</a>
		</if>
		</nobr>
	</if>
        <else>
          <font color="gray">@permissions.grantee_name@</font>
        </else>
    }
}

foreach priv $privs { 
    lappend select_clauses "sum(ptab.${priv}_p) as ${priv}_p"
    lappend select_clauses "(case when sum(ptab.${priv}_p) > 0 then 'checked' else '' end) as ${priv}_checked"
    lappend from_all_clauses "(case when privilege='${priv}' then 2 else 0 end) as ${priv}_p"
    lappend from_direct_clauses "(case when privilege='${priv}' then -1 else 0 end) as ${priv}_p"
    lappend from_dummy_clauses "0 as ${priv}_p"

    set priv_subs [string map {_ { }} $priv]
    set priv_help_url "https://www.project-open.com/en/list-privileges#$priv"
    set priv_html "<a href='$priv_help_url' target=' '>[im_gif help]</a> $priv_subs"

    lappend elements ${priv}_p \
        [list \
             html { align center } \
             label [string totitle $priv_html] \
             display_template "
               <if @permissions.${priv}_p@ ge 2>
                 <img src=\"/shared/images/checkboxchecked\" border=\"0\" height=\"13\" width=\"13\" alt=\"X\" title=\"This permission is inherited, to remove, click the 'Do not inherit ...' button above.\">
               </if>
               <else>
                 <input type=\"checkbox\" name=\"perm\" value=\"@permissions.grantee_id@,${priv}\" @permissions.${priv}_checked@>
               </else>
             " \
            ]
}

# Remove all
lappend elements remove_all {
    html { align center } 
    label "Remove All"
    display_template {<input type="checkbox" name="perm" value="@permissions.grantee_id@,remove">}
}



set perm_url "[lindex [site_node::get_url_from_object_id -object_id [site_node::closest_ancestor_package -include_self -package_key [subsite::package_keys]]] 0]permissions/"

if { (![info exists user_add_url] || $user_add_url eq "") } {
    set user_add_url "${perm_url}perm-user-add"
}
set user_add_url [export_vars -base $user_add_url { object_id expanded {return_url "[ad_return_url]"}}]


set actions [list "Add user" $user_add_url "Grant permissions to a new user"]

if { $context_id ne "" } {
    set inherit_p [permission::inherit_p -object_id $object_id]

    if { $inherit_p } {
        lappend actions "Do not inherit from $parent_object_name" [export_vars -base "${perm_url}toggle-inherit" {object_id {return_url [ad_return_url]}}] "Stop inheriting permissions from the $parent_object_name"
    } else {
        lappend actions "Inherit from $parent_object_name" [export_vars -base "${perm_url}toggle-inherit" {object_id {return_url [ad_return_url]}}] "Inherit permissions from the $parent_object_name"
    }
}

# TODO: Inherit/don't inherit
if { "datatable" == $mode} {
	template::list::create \
		-name permissions \
		-multirow permissions \
		-actions $actions \
		-elements $elements \
		-class "jq-datatable"
} else {
	template::list::create \
		-name permissions \
		-multirow permissions \
		-actions $actions \
		-elements $elements 
}

set perm_form_export_vars [export_vars -form {object_id privs return_url}]
set perm_modify_url "${perm_url}perm-modify"
set application_group_id [application_group::group_id_from_package_id -package_id [ad_conn subsite_id]]


# PERMISSION: yes = 2, no = 0
# DIRECT:     yes = 1, no = -1

# 3 = permission + direct
# 2 = permission, no direct
# 1 = no permission, but direct (can't happen)
# 0 = no permission


# 2 = has permission, not direct => inherited
# 1 = has permission, it's direct => direct
# -1 = no permission 

# NOTE:
# We do not include site-wide admins in the list

db_multirow -extend { name_url } permissions permissions {} {
    if { $object_type eq "user" && $grantee_id != 0 } {
        set name_url [acs_community_member_url -user_id $grantee_id]
}
}


ad_return_template

