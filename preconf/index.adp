<html><head><title>]project-open[ Intranet</title>
<meta http-equiv=Content-Type content="text/html; charset=iso-8859-1">

<link media=screen href="/intranet/style/style.default.css" type=text/css rel=StyleSheet>
<body text=black bgColor=white>

<table cellSpacing=0 cellPadding=0 width="100%" border=0>
  <tr>
    <td><A href="http://www.project-open.com/">
      <img src="/intranet/images/project_open.38.10frame.gif" border=0>
    </A></td>
    <td vAlign=center align=middle></td>
    <td vAlign=center align=right></td>
  </tr>
</table>

<table cellSpacing=0 cellPadding=0 width="100%" border=0>
  <tr>
    <td align=left>
      <table cellSpacing=0 cellPadding=0 border=0>
        <tr height=19>
          <td><img alt="" src="/intranet/images/navbar_default/left-sel.gif" width=19 border=0 heigth="19"></td>
          <td class=tabsel><A class=whitelink href="/intranet/index">Home</A></td>
          <td><img alt="" src="/intranet/images/navbar_default/right-sel.gif" width=19 border=0 heigth="19"></td>
          </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td class=pagedesriptionbar colSpan=2>
      <table cellPadding=1 width="100%">
        <tr><td class=pagedesriptionbar vAlign=center>
	  ]project-open[ Intranet
	</td></tr>
      </table>
    </td>
  </tr>
</table><br>

<table cellSpacing=5 cellPadding=5 width="100%" border=0>
  <tr valign=top >
    <td vAlign=top width="50%">

      <table cellSpacing=1 cellPadding=5 border=0 width="100%">
        <tr class=tableheader>
          <td class=tableheader>
            ]project-open[ Links
          </td>
        </tr>
        <tr><td class=tablebody>
            <LI><A href="/intranet/">]project-open[ Intranet</a><br>
            <LI><A href="http://www.project-open.com/">]project-open[ Web Site </a>
            <LI><A href="http://www.project-open.org/">]project-open[ Developer Community</a>
            <LI><A href="http://www.project-open.org/doc/">Documentation Home</a>
        </td></tr>
      </table>

      <br>
      <table cellSpacing=0 cellPadding=0 border=0 width="100%">
      <tr><td>
      
      <table cellSpacing=1 cellPadding=1 border=0 width="100%">
        <tr class=rowtitle>
          <td colspan=3 class=rowtitle align=center>Default Logins</td>
        </tr>
        <tr class=rowtitle>
          <td class=rowtitle align=center>Name</td>
          <td class=rowtitle align=center>Email</td>
          <td class=rowtitle align=center>Passwd</td>
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

      
      </td></tr>
      </table>



    </td>
    <td>
      <table cellSpacing=0 cellPadding=5 border=0>
        <tr><td class=tableheader>Intranet Login</td></tr>
        <tr><td class=tablebody>
        <p>
	Please see the "Default Logins" on the left hand side<br>
	of this page for access to the built-in demo accounts.
	</p>
        
<!-- Include the login widget -->
<include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@" &="__adp_properties">
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

</body>
</html>