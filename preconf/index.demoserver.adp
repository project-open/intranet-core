
<% set page_title "V[string range [im_core_version] 0 5] Demo Server" %>
<%= [im_header -loginpage "\]project-open\[ $page_title"] %>
<%= [im_navbar -loginpage "home"] %>

<div id="slave">
<div id="fullwidth-list-no-side-bar" class="fullwidth-list-no-side-bar" style="visibility: visible;">

<table cellSpacing=5 cellPadding=5 width="100%" border=0>
  <tr valign=top >
    <td vAlign=top width="50%">

<table cellSpacing=0 cellPadding=0 border=0>
<tr valign=top>
<td>
      
        <table cellSpacing=3 cellPadding=3 border=0 width="100%">
        <tr>
          <td colspan=2><h1>Consulting</h1></td>
        </tr>
        <tr>
          <td colspan=2 class=tableheader><b>]po[ <a href="http://www.project-open.com/en/solutions/project-open-consulting.html">Consulting</a> Demo Accounts<b></td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=8864&url=/intranet/"><b>Login as Ben Bigboss</b></a></td>
          <td class=tablebody>(Senior Manager)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=8898&url=/intranet/">Login as Bobby Bizconsult</a></td>
          <td class=tablebody>(Project Manager)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=8881&url=/intranet/">Login as Sally Sales</a></td>
          <td class=tablebody>(Sales)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=9037&url=/intranet/">Login as David Rolland</a></td>
          <td class=tablebody>(Customer)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=8869&url=/intranet/">Login as Andrew Accounting</a></td>
          <td class=tablebody>(Accounting)</td>
        </tr>
	</table>
	<br>

        <table cellSpacing=3 cellPadding=3 border=0 width="100%">
        <tr>
          <td colspan=2><h1>IT Service Management</h1></td>
        </tr>
        <tr>
          <td colspan=2 class=tableheader><b>]po[ <a href="http://www.project-open.com/en/solutions/itsm/index.html">ITSM</a> Demo Accounts</b></td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=8887&url=/intranet/">Login as Garry Groupmanager</a></td>
          <td class=tablebody>(Senior Manager)</td>
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
          <td class=tablebody><A href="become?user_id=8823&url=/intranet/">Login as David Developer</a></td>
          <td class=tablebody>(Linux Admin)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=9107&url=/intranet/">Login as Eva Baziere</a></td>
          <td class=tablebody>(Customer)</td>
        </tr>
	</table>
	<br>

        <table cellSpacing=3 cellPadding=3 border=0 width="100%">
        <tr>
          <td colspan=2><h1>Translation</h1></td>
        </tr>
        <tr>
          <td colspan=2 class=tableheader><b>]po[ <a href="http://www.project-open.com/en/solutions/project-open-translation-mangement-system.html">Translation</a> Demo Accounts</b></td>
        </tr>
<!--
        <tr>
          <td class=tablebody><A href="become?user_id=8799&url=/intranet/">Login as Tracy Translationmanager</a></td>
          <td class=tablebody>(Senior Manager)</td>
        </tr>
-->
        <tr>
          <td class=tablebody><A href="become?user_id=8843&url=/intranet/">Login as Petra Projectmanager</a></td>
          <td class=tablebody>(Project Manager)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=9063&url=/intranet/">Login as Ester Arenas</a></td>
          <td class=tablebody>(Freelancer)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=8811&url=/intranet/">Login as Angelique Picard</a></td>
          <td class=tablebody>(Freelancer)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=9203&url=/intranet/">Login as Sheila Carter</a></td>
          <td class=tablebody>(Customer)</td>
        </tr>
        <tr>
          <td class=tablebody><A href="become?user_id=8875&url=/intranet/">Login as Samuel Salesmanager</a></td>
          <td class=tablebody>(Sales)</td>
        </tr>
	</table>
	<br>     
</td></tr>
</table>



    </td>
    <td>
      <table cellSpacing=5 cellPadding=5 border=0>
        <tr><td class=tableheader><b>Demo Server Login Notes</b></td></tr>
        </tr>
        <tr><td class=tablebody>
         </td>
        </tr>
	<tr>
	<td>

		<p>
		Please select one of the demo accounts at the left hand side and 
		click on the link in order to login.
		</p>
		<p>
		The demo accounts on the left hand side allow you to
		test the application in configurations specific to the
		following business sectors:
		</p>
		<ul>
		<li>Consulting - generic consulting companies
		<li>ITSM - IT departments and IT services management
		<li>Translation - Translation agencies and departments
		</ul>
		&nbsp;<br>
		<p>
		<b>Please note:</b><br>
		<ul>
		<li>This demo server is a shared resource:<br>
		    Other users may have changed demo projects and the configuration.
		<li>Localization:<br>
		    The ]po[ language settings depend on browser settings and are cached.
		    These chached settings are cleared every 15 minutes.
		<li>Server Reset:<br>
		    Once a day we will reset the server and any data entered will be deleted.
		<li>Administrator Permissions:<br>
		   Please note that you won't get Admin permissions on this demo server. <br>
		   <a href="http://www.project-open.org/documentation/install_main">
		   Please download and install ]po[ </A>
		   in your own server in order to test administration functionality.
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
