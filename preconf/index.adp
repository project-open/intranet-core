<%= [im_header -loginpage $title] %>
<%= [im_navbar -loginpage "home"] %>

<div id="slave">
<div id="slave_content">


<table cellSpacing=5 cellPadding=5 width="100%" border=0>
  <tr valign=top >
    <td vAlign=top width="50%">

      <%= [im_box_header "Default Logins" ] %>

	      <table cellSpacing=1 cellPadding=1 border=0 width="100%">
	        <tr>
	          <td class=tableheader align=center>Name</td>
	          <td class=tableheader align=center>Email</td>
	          <td class=tableheader align=center>Passwd</td>
	        </tr>
	
	
	        <multiple name=users>
	          <if @old_demo_group@ ne @users.demo_group@>
	            <tr><td class=tablebody colspan=3><b>@users.demo_group@</b></td></tr>
	          </if>
	          <% set old_demo_group $users(demo_group) %>
	          <tr>
	            <td class=tablebody>@users.first_names@ @users.last_name@</td>
	            <td class=tablebody>@users.email@</td>
	            <td class=tablebody>@users.demo_password@</td>
	          </tr>
	        </multiple>
	
	      </table>
	      

        <%= [im_box_footer] %>

    </td>
    <td>


   
    <%= [im_box_header "Intranet Login"] %>

      <table cellSpacing=0 cellPadding=5 border=0>
        <tr><td class=tablebody>
        <p>
	Please see the "Default Logins" on the left hand side<br>
	of this page for access to the built-in demo accounts.
	</p>

<!-- Include the login widget -->
<include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username_org;noquote@" email="@email_org;noquote@" &="__adp_properties">
        </td>
        </tr>

        <tr><td>


<%= 
    # Gather some information about the current system
    set ip_address "undefined"
    catch {set ip_address [exec /bin/bash -c "/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print \$1}'"]} ip_address

    set total_memory "undefined"
    catch {set total_memory [expr [exec /bin/bash -c "grep MemTotal /proc/meminfo | awk '{print \$2}'"] / 1024]} total_memory

    set url "<a href=\"http://$ip_address/\" target=_new>http://$ip_address/</a>\n"

    set result ""
    set header_vars [ns_conn headers]
    for { set i 0 } { $i < [ns_set size $header_vars] } { incr i } {
	set key [ns_set key $header_vars $i]
	set val [ns_set value $header_vars $i]
	if {"Cookie" == $key} { continue }
	if {"Connection" == $key} { continue }
	if {"Cache-Control" == $key} { continue }
	if {"User-Agent" == $key} { continue }
	if {[regexp {^Accept} $key match]} { continue }
	append result "<tr><td>$key</td><td>$val</td></tr>\n"
    }
%>

	</table>
	<%= [im_box_footer] %>
         
        <%= [im_box_header "Browser URL"] %>

	      <table cellSpacing=1 cellPadding=1 border=0 width="100%">
	        <tr>
	          <td class=tablebody>Browser URL</td>
	          <td class=tablebody><%= $url %></td>
	        </tr>
	        <tr>
	          <td colspan=2 class=tablebody><small>
		  Please enter this URL into the browser on your desktop computer
		  (running this VM) to access this application.
		  </small></td>
	        </tr>
              </table>
         <%= [im_box_footer] %>

         <%= [im_box_header "System Parameters"] %>

	     <table>

	        <tr>
	          <td class=tablebody>IP-Address</td>
	          <td class=tablebody><%= $ip_address %></td>
	        </tr>
	        <tr>
	          <td colspan=2 class=tablebody><small>
		  This is the IP address that this Virtual Machine has obtained automatically via DHCP.
		  </small></td>
	        </tr>
	        <tr>
	          <td class=tablebody>Total Memory</td>
	          <td class=tablebody><%= $total_memory %> MByte</td>
	        </tr>
	        <tr>
	          <td colspan=2 class=tablebody><small>
		  The total memory of the server. We recommend atleast 1024 MByte for a production server.
		  </small></td>
	        </tr>
             </table>


      <%= [im_box_footer] %>

    </td>
  </tr>
</table>

</div>
</div>

<%= [im_footer] %>