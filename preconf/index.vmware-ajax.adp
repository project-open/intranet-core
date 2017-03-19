<%= [im_header -loginpage $page_title] %>
<%= [im_navbar -loginpage_p 1] %>

<!-- <link rel="stylesheet" type="text/css" href="index.css" media="all"> -->

<script type="text/javascript">
// Set a specific image src
function setImage (id,img) {
	var element = document.getElementById(id);
	element.src = img;

	var loginEl = document.getElementById("login-table");
	loginEl.style.borderWidth="0px";
}

// Write the email/pwd into the OpenACS login area
function setCredentials (email, password) {
	var emailEl = document.getElementById("email");
	var pwdEl = document.getElementById("password");
	emailEl.value = email;
	pwdEl.value = password;

	var loginEl = document.getElementById("login-table");
	loginEl.style.borderWidth="5px";
	loginEl.style.borderColor="#F00";
	loginEl.style.borderStyle="solid";	

	$('html, body').animate({ scrollTop: 0 }, 'fast');

	document.getElementById('login').submit();

}

</script>


<div id="slave">
  <div id="fullwidth-list-no-side-bar" class="fullwidth-list-no-side-bar" style="visibility: visible;">

<if @cnt@ gt 1>

    <table width=100% cellspacing=0 cellpadding=0>
      <tr vAlign="top">
	<td width="50%">

	  <div style="text-align: left">
	    <h2>Please select one of the demo accounts</h2>
	    <p>
	      The users belong to different groups and have different permissions. <br>
	      Please choose "System Administrators" for maximum permissions.
	    </p>
	    <br>
	  </div>


	  <table border=0 bordercolor=red><tr><td>
	  
	  <multiple name=users>
	    @users.before_html;noquote@
	    <table border="0" cellpadding="0" cellspacing="0" style="cursor:pointer"><colgroup><col width="80px"><col width="230px"></colgroup>
	      <tr class="off" 
		  onmouseover="this.className='on';setImage('@users.lower_name@', '/intranet/images/demoserver/@users.lower_name@.jpg')" 
		  onmouseout="this.className='off';setImage('@users.lower_name@','/intranet/images/demoserver/@users.lower_name@_bw.jpg')"
		  onclick="setCredentials('@users.email@', '@users.demo_password@')"
		  >
		<td><img id="@users.lower_name@" src="/intranet/images/demoserver/@users.lower_name@_bw.jpg"></td>
		<td>
		  <b>@users.user_name@</b><br>
		  <nobr>Group: @users.demo_group@<br>
		  <nobr>Login: @users.email@</nobr><br>
		  <nobr>Password: @users.demo_password@</nobr><br>
		</td>
	      </tr>
	    </table>
	    @users.after_html;noquote@
	  </multiple>
	  
	  </table>


	</td>
	<td width="50%">


</if>

	  <table cellSpacing=1 cellPadding=1 border="0">
	    <tr>
	      <td class=tableheader><b>Intranet Login</b></td>
	    </tr>
	    <tr>
	      <td class=tablebody>
	        <table id="login-table" border=0><tr><td>
		  <include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@" &="__adp_properties"/>
		</td></tr></table>
	      </td>
	    </tr>
	    <tr><td>
		<font color=red>
		  &nbsp;<br>
		  Please select one of the demo accounts from the left hand side<br>
		  and click on the "Log In" button.<br>
		</font>
	    </td></tr>
	  </table>
	  
	  <br>&nbsp;<br>


<if @cnt@ gt 1>

      <table cellSpacing=1 cellPadding=1 border="0">
	<tr><td colspan="2" class=tableheader><b>Browser URL</b></td></tr>
	<tr>
	  <td class=tablebody>Browser URL</td>
	  <td class=tablebody><%= $url %></td>
	</tr>
	<tr>
	  <td colspan="2" class=tablebody><small>
	      Please enter this URL into the browser on your desktop computer<br>
	      in order to access the application.
	  </small></td>
	</tr>
      </table>
      
      <br>&nbsp;<br>
      
      <table cellSpacing=1 cellPadding=1 border="0">
	<tr><td colspan="2" class=tableheader><b>System Parameters</b></td></tr>
	<tr>
	  <td class=tablebody>IP-Address</td>
	  <td class=tablebody><%= $ip_address %></td>
	</tr>
	<tr>
	  <td colspan="2" class=tablebody><small>
	      This is the IP address that this Virtual Machine has obtained automatically via DHCP.
	  </small></td>
	</tr>
	<tr>
	  <td class=tablebody>Total Memory</td>
	  <td class=tablebody><%= $total_memory %> MByte</td>
	</tr>
	<tr>
	  <td colspan="2" class=tablebody><small>
	      The total memory of the server.<br>
	      We recommend atleast 1024 MByte for a production server.
	  </small></td>
	</tr>
      </table>
      
      
	  
	<td>
      </tr>
    </table>

</if>


  </div>
</div>

<%= [im_footer] %>
