# /tcl/intranet-design.tcl

ad_library {
    Design related functions
    Code based on work from Bdoesborg@comeptitiveness.com

    @author Frank Bergmann (fraber@fraber.de)
    @creation-date  January 2004
}

ad_proc -public im_gif { name {alt ""} { border 0} {width 0} {height 0} } {
    Create an <IMG ...> tag to correctly render a range of GIFs
    frequently used by the Intranet
} {
    set url "/intranet/images"
    switch [string tolower $name] {
	"delete" 	{ return "<img src=$url/delete.gif width=14 heigth=15 border=$border alt='$alt'>" }
	"help"		{ return "<img src=$url/help.gif width=16 height=16 border=$border alt='$alt'>" }
	"new"		{ return "<img src=$url/new.gif width=13 height=15 border=$border alt='$alt'>" }
	"open"		{ return "<img src=$url/open.gif width=16 height=15 border=$border alt='$alt'>" }
	"save"		{ return "<img src=$url/save.gif width=14 height=15 border=$border alt='$alt'>" }
	"incident"	{ return "<img src=$url/incident.gif width=20 height=20 border=$border alt='$alt'>" }
	"1102"		{ return "<img src=$url/incident.gif width=20 height=20 border=$border alt='$alt'>" }
	"discussion"	{ return "<img src=$url/discussion.gif width=20 height=20 border=$border alt='$alt'>" }
	"1106"		{ return "<img src=$url/discussion.gif width=20 height=20 border=$border alt='$alt'>" }
	"task"		{ return "<img src=$url/task.gif width=24 height=20 border=$border alt='$alt'>" }
	"1104"		{ return "<img src=$url/task.gif width=24 height=20 border=$border alt='$alt'>" }
	"news"		{ return "<img src=$url/news.gif width=20 height=20 border=$border alt='$alt'>" }
	"1100"		{ return "<img src=$url/task.gif width=24 height=20 border=$border alt='$alt'>" }
	"note"		{ return "<img src=$url/note.gif width=20 height=20 border=$border alt='$alt'>" }
	"1108"		{ return "<img src=$url/note.gif width=20 height=20 border=$border alt='$alt'>" }
	"reply"		{ return "<img src=$url/reply.gif width=22 height=20 border=$border alt='$alt'>" }
	"1190"		{ return "<img src=$url/reply.gif width=22 height=20 border=$border alt='$alt'>" }
	"tick"		{ return "<img src=$url/tick.gif width=14 heigth=15 border=$border alt='$alt'>" }
	"wrong"		{ return "<img src=$url/delete.gif width=14 heigth=15 border=$border alt='$alt'>" }
	"turn"		{ return "<img src=$url/turn.gif widht=15 height=15 border=$border alt='$alt'>" }
	"exp-folder"	{ return "<img src=$url/exp-folder.gif width=19 heigth=16 border=$border alt='$alt'>" }
	"exp-minus"	{ return "<img src=$url/exp-minus.gif width=19 heigth=16 border=$border alt='$alt'>" }
	"exp-unknown"	{ return "<img src=$url/exp-unknown.gif width=19 heigth=16 border=$border alt='$alt'>" }
	"exp-line"	{ return "<img src=$url/exp-line.gif width=19 heigth=16 border=$border alt='$alt'>" }

	default		{ 
	    set result "<img src=\"$url/$name.gif\" border=$border "
	    if {$width > 0} { append result "width=$width " }
	    if {$height > 0} { append result "height=$height " }
	    append result "alt=\"$alt\">"
	    return $result
	}
    }
}

ad_proc -public im_gif_cleardot { {width 1} {height 1} {alt ""} } {
    Creates an &lt;IMG ... &gt; tag of a given size
} {
    set url "/intranet/images"
    return "<img src=$url/cleardot.gif width=$width height=$height alt=\"$alt\">"
}


#ad_proc -public im_employee_submenu { current_url } {
#    Displays a submenu that lets the user choose between
#    various views to the users of the system
#} {
#	
#}


ad_proc -public im_portrait_html { user_id } {
    Return a HTML piece that renders the original Portrait file
    that the user has provided.
    Or "" if there was not portrait.
} {

    if {![db_0or1row get_user_info "
select
	u.first_names, 
	u.last_name, 
	gp.portrait_id,
	gp.portrait_upload_date,
	gp.portrait_comment,
	gp.portrait_original_width,
	gp.portrait_original_height,
	gp.portrait_client_file_name
from 
	users u,
	general_portraits gp
where
	u.user_id = :user_id
	and u.user_id = gp.on_what_id(+)
	and 'USERS' = gp.on_which_table(+)
	and 't' = gp.portrait_primary_p(+)"]} { return "" }
    if  {[empty_string_p $portrait_id]} { return "" }
    
    if { ![empty_string_p $portrait_original_width] && ![empty_string_p $portrait_original_height] } {
	set widthheight "width=$portrait_original_width height=$portrait_original_height"
    } else {
	set widthheight ""
    }

    return "<img $widthheight src=\"/shared/portrait-bits.tcl?[export_url_vars portrait_id]\">"
}


# 2003.06.09 SLS international Design
#
ad_proc -public im_return_template {} {
    Wrapper that adds page contents to header and footer 
} {
    uplevel { 

	return "  
[im_header]
[im_navbar]
[value_if_exists page_body]
[value_if_exists page_content]
[im_footer]
"
    }

}


ad_proc -public im_user_navbar { default_letter base_url next_page_url prev_page_url export_var_list } {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/users/.
    The lower part of the navbar also includes an Alpha bar.

    Default_letter==none marks a special behavious, printing no alpha-bar.

} {
    # -------- Compile the list of parameters to pass-through-------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	    ns_log Notice "im_ustomer_navbar: $var <- $value"
        }
    }

    # --------------- Determine the calling page ------------------
    set user_id [ad_get_user_id]
    set section ""
    set url_stub [im_url_with_query]

    switch -regexp $url_stub {
	{index$} { set section "Employees" }
	{Employees} { set section "Employees" }
	{Customers} { set section "Customers" }
	{All} { set section "All Users" }
	{org-chart} { set section "Org Chart" }
	{group_id\=14} { set section "Externals" }
	{/intranet/users/expense*} { set section "Expense" }
	default {
	    # Default: Employees
	}
    }

    set alpha_bar [im_alpha_bar $base_url $default_letter $bind_vars]
    if {[string equal "none" $default_letter]} { set alpha_bar "&nbsp;" }
    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    set all_users "$tdsp$nosel<a href='index?user_group_name=All'>All Users</a></td>"
    set employee "$tdsp$nosel<a href=index?user_group_name=Employees>Employees</a></td>"
    set customers "$tdsp$nosel<a href=index?user_group_name=Customers>Clients</a></td>"
    set externals "$tdsp$nosel<a href=index?user_group_name=Freelancers>Freelance</a></td>"
    set expense "$tdsp$nosel<a href='expense'>Expense</a></td>"

    switch $section {
"All Users" {set all_users "$tdsp$sel All Users</td>"}
"Expense" {set expense "$tdsp$sel Expense</td>"}
"Employees" {set employee "$tdsp$sel Employees</td>"}
"Customers" {set customers "$tdsp$sel Clients</td>"}
"Externals" {set externals "$tdsp$sel Freelance</td>"}
default {
    # Nothing - just let all sections deselected
}
    }

    set navbar "
<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td colspan=6 align=right>
      <table cellpadding=1 cellspacing=0 border=0>
        <tr>"
append navbar "$employee\n"
if {[im_permission $user_id view_customer_contacts]} { append navbar $customers }
if {[im_permission $user_id view_freelancers]} { append navbar $externals }
if {[im_permission $user_id view_customer_contacts]} { append navbar $all_users }
#if {[im_permission $user_id view_finance]} { append navbar $expense }
append navbar "
          $tdsp$nosel<a href=new>[im_gif new "Add a new user"]</a></td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=6 class=tabnotsel align=center>"
if {![string equal "" $prev_page_url]} {
    append navbar "<A HREF=$prev_page_url>&lt;&lt;</A>\n"
}
append navbar $alpha_bar
if {![string equal "" $next_page_url]} {
    append navbar "<A HREF=$next_page_url>&gt;&gt;</A>\n"
}
append navbar "
    </td>
  </tr>
</table>
"
    return $navbar
}


ad_proc -public im_project_navbar { default_letter base_url next_page_url prev_page_url export_var_list} {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/projects/.
    The lower part of the navbar also includes an Alpha bar.

    Default_letter==none marks a special behavious, hiding the alpha-bar.
} {
    # -------- Compile the list of parameters to pass-through-------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	    ns_log Notice "im_ustomer_navbar: $var <- $value"
        }
    }

    # --------------- Determine the calling page ------------------
    set user_id [ad_get_user_id]
    set section ""
    set url_stub [im_url_with_query]

    switch -regexp $url_stub {
	{project%5flist} { set section "Standard" }
	{project%5fstatus} { set section "Status" }
	{project%5fcosts} { set section "Costs" }
	{index$} { set section "Standard" }
	{/intranet/projects/$} { set section "Standard" }
	default {
	    set section "Standard"
	}
    }

    set alpha_bar [im_alpha_bar $base_url $default_letter $bind_vars]
    if {[string equal "none" $default_letter]} { set alpha_bar "&nbsp;" }
    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    set standard "$tdsp$nosel<a href='index?view_name=project_list'>Standard</a></td>"
    set status "$tdsp$nosel<a href='index?view_name=project_status'>Status</a></td>"
    set costs "$tdsp$nosel<a href='index?view_name=project_costs'>Costs</a></td>"

    switch $section {
"Standard" {set standard "$tdsp$sel Standard</td>"}
"Status" {set status "$tdsp$sel Status</td>"}
"Costs" {set costs "$tdsp$sel Costs</td>"}
default {
    # Nothing - just let all sections deselected
}
    }

    set navbar "
<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td colspan=6 align=right>
      <table cellpadding=1 cellspacing=0 border=0>
        <tr> 
          $standard"
if {[im_permission $user_id view_hours]} { append navbar $status }
if {[im_permission $user_id view_finance]} { append navbar $costs }

if {[im_permission $user_id add_projects]} { 
    append navbar "$tdsp$nosel<a href=new>[im_gif new "Add a new project"]</a></td>\n"
}
append navbar "
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=6 class=tabnotsel align=center>"
if {![string equal "" $prev_page_url]} {
    append navbar "<A HREF=$prev_page_url>&lt;&lt;</A>\n"
}
append navbar $alpha_bar
if {![string equal "" $next_page_url]} {
    append navbar "<A HREF=$next_page_url>&gt;&gt;</A>\n"
}
append navbar "
    </td>
  </tr>
</table>
"
    return $navbar
}


ad_proc -public im_invoice_navbar { default_letter base_url next_page_url prev_page_url export_var_list} {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/projects/.
    The lower part of the navbar also includes an Alpha bar.

    Default_letter==none marks a special behavious, hiding the alpha-bar.
} {
    # -------- Compile the list of parameters to pass-through-------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	    ns_log Notice "im_ustomer_navbar: $var <- $value"
        }
    }

    # --------------- Determine the calling page ------------------
    set user_id [ad_get_user_id]
    set section ""
    set url_stub [im_url_with_query]

    switch -regexp $url_stub {
	{/intranet/invoicing/$} { set section "Invoices" }
	{/intranet/invoicing/new} { set section "New Invoice" }
	{/intranet/invoicing/payments} { set section "Payments" }
	{invoice%5fnew} { set section "New Invoice" }
	{invoice%5flist} { set section "Invoices" }
	{invoice%5fpayments} { set section "Payments" }
	{index$} { set section "New Invoice" }
	default {
	    set section "none"
	}
    }

    set alpha_bar [im_alpha_bar $base_url $default_letter $bind_vars]
    if {[string equal "none" $default_letter]} { set alpha_bar "&nbsp;" }
    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    set status "$tdsp$nosel<a href='index?view_name=invoice_list'>Invoices</a></td>"
    set new_invoice "$tdsp$nosel<a href='new'>New Invoice</a></td>"
    set payments "$tdsp$nosel<a href='payments'>Payments</a></td>"

    switch $section {
	"Invoices" {set status "$tdsp$sel Invoices</td>"}
	"New Invoice" {set new_invoice "$tdsp$sel New Invoice</td>"}
	"Payments" {set payments "$tdsp$sel Payments</td>"}
	default {
	    # Nothing - just let all sections deselected
	}
    }

    set navbar "
<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td colspan=6 align=right>
      <table cellpadding=1 cellspacing=0 border=0>
        <tr>\n"
if {[im_permission $user_id view_finance]} { append navbar $status }
if {[im_permission $user_id view_finance]} { append navbar $payments }
if {[im_permission $user_id view_finance]} { append navbar $new_invoice }
append navbar "
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=6 class=tabnotsel align=center>"
if {![string equal "" $prev_page_url]} {
    append navbar "<A HREF=$prev_page_url>&lt;&lt;</A>\n"
}
append navbar $alpha_bar
if {![string equal "" $next_page_url]} {
    append navbar "<A HREF=$next_page_url>&gt;&gt;</A>\n"
}
append navbar "
    </td>
  </tr>
</table>
"
    return $navbar
}


ad_proc -public im_customer_navbar { default_letter base_url next_page_url prev_page_url export_var_list } {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet/projects/.
    The lower part of the navbar also includes an Alpha bar.

    Default_letter==none marks a special behavious, hiding the alpha-bar.

} {
    # -------- Compile the list of parameters to pass-through-------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	    ns_log Notice "im_ustomer_navbar: $var <- $value"
        }
    }

    # --------------- Determine the calling page ------------------
    set user_id [ad_get_user_id]
    set section ""
    set url_stub [im_url_with_query]

    switch -regexp $url_stub {
	{project%5flist} { set section "Standard" }
	{project%5fstatus} { set section "Status" }
	{project%5fcosts} { set section "Costs" }
	{index$} { set section "Standard" }
	{/intranet/projects/$} { set section "Standard" }
	default {
	    set section "Standard"
	}
    }

    ns_log Notice "url_stub=$url_stub"
    ns_log Notice "section=$section"

    set alpha_bar [im_alpha_bar $base_url $default_letter $bind_vars]

    if {[string equal "none" $default_letter]} { set alpha_bar "&nbsp;" }
    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    set standard "$tdsp$nosel<a href='index?view_name=project_list'>Standard</a></td>"
    set status "$tdsp$nosel<a href='index?view_name=project_status'>Status</a></td>"
    set costs "$tdsp$nosel<a href='index?view_name=project_costs'>Costs</a></td>"

    switch $section {
"Standard" {set standard "$tdsp$sel Standard</td>"}
"Status" {set status "$tdsp$sel Status</td>"}
"Costs" {set costs "$tdsp$sel Costs</td>"}
default {
    # Nothing - just let all sections deselected
}
    }

    set navbar "
<table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td colspan=6 align=right>
      <table cellpadding=1 cellspacing=0 border=0>
        <tr> 
          $standard"
# if {[im_permission $user_id view_hours]} { append navbar $status }
# if {[im_permission $user_id view_finance]} { append navbar $costs }
if {[im_permission $user_id add_customers]} {
    append navbar "$tdsp$nosel<a href=new>[im_gif new "Add a new customer"]</a></td>"
}
append navbar "
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td colspan=6 class=tabnotsel align=center>"
if {![string equal "" $prev_page_url]} {
    append navbar "<A HREF=$prev_page_url>&lt;&lt;</A>\n"
}
append navbar $alpha_bar
if {![string equal "" $next_page_url]} {
    append navbar "<A HREF=$next_page_url>&gt;&gt;</A>\n"
}
append navbar "
    </td>
  </tr>
</table>
"
    return $navbar
}




ad_proc -public im_navbar { } {
    Setup a top navbar with tabs for each area, highlighted depending
    on the local URL and enabled depending on the user permissions.
} {
    set user_id [ad_get_user_id]
    set url_stub [ns_conn url]

    set context_bar [ad_partner_upvar context_bar]
    set page_title [ad_partner_upvar page_title]
    set section [ad_partner_upvar section]

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    set navbar ""

    # select the toplevel menu items
    set menu_select_sql "
select
        m.*
from
        im_menus m
where
        parent_menu_id is null
order by
        sort_order
"

set extra_sql "
        and im_permission_p(m.menu_id, :user_id, 'read') = 't'
"


    # make sure only one field gets selected..
    set found_selected 0
    db_foreach menu_select $menu_select_sql {
        set html "$nosel<a href=\"$url\">$name</a></td>$tdsp\n"
        if {!$found_selected && [string equal $url_stub $url]} {
            set html "$sel$a_white href=\"$url\"/>$name</a></td>$tdsp\n"
            set found_selected 1
        }
        append navbar $html
    }

    return "
      <table border=0 cellspacing=0 cellpadding=0 width='100%'>
        <TR>
          <TD align=left>
            <table border=0 cellspacing=0 cellpadding=3>
              <tr>
                $navbar
              </tr>
            </table>
          </TD>
          <TD align=right>
            $context_bar
          </TD>
        </TR>
        <TR>
          <td colspan=2 class=pagedesriptionbar>
            <table cellpadding=1 width='100%'>
              <tr>
                <td class=pagedesriptionbar valign=middle>
                  $page_title
                </td>
              </tr>
            </table>
          </td>
        </TR>
      </table>\n"
}


# 2003.06.09 Frank Bergmann
#
ad_proc -public im_header { { page_title "" } { extra_stuff_for_document_head "" } } {
    The header for SLS
} {
    set user_id [ad_get_user_id]
    set user_name [im_get_user_name $user_id]
    if { [empty_string_p $page_title] } {
	set page_title [ad_partner_upvar page_title]
    }
    set context_bar [ad_partner_upvar context_bar]
    set page_focus [ad_partner_upvar page_focus]
    if { [empty_string_p $extra_stuff_for_document_head] } {
	set extra_stuff_for_document_head [ad_partner_upvar extra_stuff_for_document_head]
    }
#   set logo [im_tablex [ad_parameter "SystemLogo" "" ""] "2" "\#cccccc"]
    set logo [ad_parameter "SystemLogo" "" ""]

    set search_form ""
    if {[ad_user_group_member [im_employee_group_id] $user_id]} {
	set search_form "
	    <form action=/intranet/search/go-search method=post name=surx>
              <input class=surx name=query_string size=15 value=Search>
              <select class=surx name=target>"
	if {[im_permission $user_id "search_intranet"]} {
	    append search_form "
                <option class=surx selected value=content>Intranet content</option>
                <option class=surx value=users>Intranet users</option>
                <option class=surx value=htsearch>All documents in H:</option>"
	}
	append search_form "
                <option class=surx value=google>The web with Google</option>
              </select>
              <input alt=go type=submit value=go name='image'>
            </form>
"
    }

    # Determine a pretty string for the type of user that it is:
    set user_profile "User"
    if {[im_permission $user_id "freelance"]} {
	set user_profile "Freelance"
    }
    if {[im_permission $user_id "client"]} {
	set user_profile "Client"
    }
    if {[im_permission $user_id "employee"]} {
	set user_profile "Employee"
    }
    if {[ad_user_group_member [im_admin_group_id] $user_id]} {
	set user_profile "Admin"
    }
    if {[im_site_wide_admin_p $user_id]} {
	set user_profile "SiteAdmin"
    }

    append extra_stuff_for_document_head [im_stylesheet]

    return "
[ad_header $page_title $extra_stuff_for_document_head]
<table border=0 cellspacing=0 cellpadding=0 width='100%'>
  <tr>
    <td> 
      <a href='index.html'> 
        [ad_parameter "SystemLogo" "" ""]
      </a> 
    </td>
    <td align=center valign=middle> 
      <span class=small>
        $user_profile: $user_name <BR>
        <a href='/register/logout'>Log Out</a> |
        <a href='/pvt/password-update'>Change Password</a> 
      </span>
    </td>
    <td valign=middle align=right> $search_form </TD>
  </tr>
</table>
"
}

ad_proc -public im_header_emergency { page_title } {
    A header to display for error pages that do not have access to the DB
    Only the parameter file is available by default.
} {
    set system_logo [ad_parameter "SystemLogo" "" ""]
    set system_css [ad_parameter "SystemCSS" "" ""]

    set html "
	<html>
	<head>
	  <title>$page_title</title>
	  $system_css
	</head>
	<body bgcolor=white text=black>
	<table>
	  <tr>
	    <td> 
	      <a href='index.html'>$system_logo</a> 
	    </td>
	  </tr>
	</table>

      <table border=0 cellspacing=0 cellpadding=0 width='100%'>
        <TR> 
          <TD align=left> 
            <table border=0 cellspacing=0 cellpadding=3>
              <tr> 
                <td class=tabnotsel><a href=/intranet/>Home</a></td><td>&nbsp;</td>
	        <td>&nbsp;</td>
	      </tr>

            </table>
          </TD>
          <TD align=right> 
          </TD>
        </TR>
        <TR>
          <td colspan=2 class=pagedesriptionbar>
            <table cellpadding=1 width='100%'>
              <tr>
                <td class=pagedesriptionbar valign=middle> 
	           $page_title
                </td>
              </tr>
            </table>
          </td>
        </TR>
      </table>\n"
    return $html
}




ad_proc -public im_footer {} {
    SLS Intranet footer.
} {

    return "
      <TABLE border=0 cellPadding=5 cellSpacing=0 width='100%'>
        <TBODY> 
          <TR>
            <TD>Comments? Contact: 
          <A href='mailto:[ad_parameter SystemOwner]'>
          [ad_parameter SystemOwner]
          </A> 
           </TD>
        </TR>
      </TBODY>
    </TABLE>
  </BODY>
</HTML>
"
}


ad_proc -public im_stylesheet {} {
    Intranet CSS style sheet. 
} {
    return "
    <link rel=StyleSheet href=/intranet/style/style.css type=text/css media=screen>
"
}


# 2002.06.06 Boris Doesborg
# Changing intranet design
#
ad_proc -public im_tablex {{content "no content?"} {pad "0"} {col ""} {spa "0"} {bor "0"} {wid "100%"}} {
    Make a quick table
} {

    return "
    <table cellpadding=$pad cellspacing=$spa border=$bor bgcolor=$col width=$wid>
    <tr>
    <td>
    $content
    </td>
    </tr>
    </table>"
    
}


ad_proc -public im_table_with_title { title body } {
    Returns a two row table with background colors
} {
    return "
<table cellpadding=5 cellspacing=0 border=0 width='100%'>
 <tr>
  <td bgcolor=#cccccc><b>$title</b></td>
 </tr>
 <tr>
  <td bgcolor=#dddddd><font size=-1>$body</font></td>
 </tr>
</table><br>
"
}


