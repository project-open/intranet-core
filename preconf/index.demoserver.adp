
<% set page_title " &\#93;po&\#91; V[string range [im_core_version] 0 5] $servername Demo Server" %>
<%= [im_header -loginpage "\]project-open\[ $page_title"] %>
<%= [im_navbar -loginpage "home"] %>

<div id="slave">
<div id="fullwidth-list-no-side-bar" class="fullwidth-list-no-side-bar" style="visibility: visible;">

<table cellSpacing=5 cellPadding=5 width="70%" border=0>
  <tr valign=top >
    <td vAlign=top width="50%">

<table cellSpacing=0 cellPadding=0 border=0>
<tr valign=top>
<td>
      
        <table cellSpacing=3 cellPadding=3 border=0 width="100%">
        <tr>
          <td class=tablebody><nobr><A href="become?user_id=8864&url=/intranet/"><b>Login as Ben Bigboss</b></a></nobr></td>
          <td class=tablebody><nobr>(Senior Manager)</nobr></td>
        </tr>
        <tr>
          <td class=tablebody><nobr><A href="become?user_id=8875&url=/intranet/">Login as Samuel Salesmanager</a></nobr></td>
          <td class=tablebody>(Sales Manager)</td>
        </tr>
        <tr>
          <td class=tablebody><nobr><A href="become?user_id=8869&url=/intranet/">Login as Andrew Accounting</a></nobr></td>
          <td class=tablebody>(Accounting)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=8843&url=/intranet/">Login as Petra Projectmanager</a></td>
          <td class=tablebody><nobr>(Project Manager)</nobr></td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=8858&url=/intranet/">Login as Laura Leadarchitect</a></td>
          <td class=tablebody>(Employee)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=27484&url=/intranet/">Login as Harry Helpdesk</a></td>
          <td class=tablebody>(Helpdesk)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=8811&url=/intranet/">Login as Angelique Picard</a></td>
          <td class=tablebody><nobr>(Freelance Provider)</nobr></td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=9203&url=/intranet/">Login as Sheila Carter</a></td>
          <td class=tablebody>(Customer)</td>
        </tr>
	</table>
	<br>     


	<p>
	Please select one of the demo accounts in order to login.
	</p>
	<br>&nbsp;<br>
	<h3>Please note:</h3>
	<ul>
	<li><strong>Shared Resource</strong>:<br>
	    This demo server is a shared resource:<br>
	    Other users may have changed demo projects and the configuration.
	<li><strong>Localization</strong>:<br>
	    The ]po[ language settings depend on browser settings and are cached.
	    These chached settings are cleared every 15 minutes.
	<li><strong>Server Reset</strong>:<br>
	    Once a day we will reset the server and any data entered will be deleted.
	<li><strong>Administrator Permissions</strong>:<br>
	   Please note that you won't get Admin permissions on this demo server. <br>
	   <a href="http://www.project-open.org/en/install_main">
	   Please download and install ]po[ </A>
	   in your own server in order to test administration functionality.


</td></tr>
</table>



    </td>
    <td align=left>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
    </td>
    <td align=left>


      <table cellSpacing=5 cellPadding=5 border=0>
	<tr>
	<td>

		<table>
		<tr>
		<td>
		<include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@" &="__adp_properties">
		</td>
		</tr>
		</table>

	<br>&nbsp;<br>
	<h2>Other Demo Server</h2>
	<p>
	Please see the other available demo servers:<br>
	<ul>
	<li><a href="http://po40demo.project-open.net">All-Features Demo Server</h1></li>
	<li><a href="http://po40ppm.project-open.net">Project & Portfolio Management Demo Server</h1></li>
	<li><a href="http://po40itsm.project-open.net">IT Services Management Demo Server</h1></li>
	<li><a href="http://po40cons.project-open.net">Consuling Companies Demo Server</h1></li>
<!--	<li><a href="http://po40trans.project-open.net">Translation Companies Demo Server</h1></li>	-->
	</ul>

	</td>
	</tr>
      </table>

    </td>
  </tr>
</table>

<table cellSpacing=0 cellPadding=5 width="100%" border=0>
  <tr><td>
    Comments? Contact: 
    <A href="mailto:support@project-open.com">support@project-open.com</A>
  </td></tr>
</table>


</div>
</div>

<%= [im_footer] %>
