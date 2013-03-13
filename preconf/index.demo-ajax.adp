<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"> 

<%
   set version "\]po\[ V4.0:"
   switch [ns_info server] {
   l10n      { set page_title "$version L10n - Localization Server" }
   po40cons  { set page_title "$version PSA - Profesional Services Automation" }
   po40demo  { set page_title "$version All - Features Demo Server" }
   po40epm   { set page_title "$version EPM - Enterprise Project Management" }
   po40itsm  { set page_title "$version ITSM - IT Services Management" }
   po40psa   { set page_title "$version PSA - Profesional Services Automation" }
   po40pmo   { set page_title "$version PMO - Project Management Office" }
   po40trans { set page_title "$version Trans - Translation" }
   po40ts    { set page_title "$version Simple Timesheet Management" }
   default   { set page_title "$version Demo" }
   }
%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<!--[if lt IE 7.]>
<script defer type='text/javascript' src='/intranet/js/pngfix.js'></script>
<![endif]-->
<meta name="generator" content="OpenACS version 5.7.0" lang="en">
<title>@page_title@</title>
<link rel="stylesheet" type="text/css" href="index.css" media="all">
<style type="text/css">
div.outer {
	float: left;
	width: 75px;
	height: 75px;
}
div.outer a {
	display: block;
	margin: 0;
	padding:0;
	width:100%;
	height:100%;
	overflow:hidden;
}
div.login {
	margin-right: 20px;
	float: right;
	width: 47px;
	height: 20px;
	background: url('/intranet/images/demoserver/login.jpg' ) 0 -0px no-repeat;
}
div.login a {
	display: block;
	margin: 0;
	padding:0;
	width:100%;
	height:100%;
	overflow:hidden;
	background: url('/intranet/images/demoserver/login_bw.jpg') top left no-repeat;
}
div.outer1 {
	background: url('/intranet/images/demoserver/ben_bigboss.jpg' ) 0 -0px no-repeat;
}
div.outer1 a {
	background: url('/intranet/images/demoserver/ben_bigboss.jpg' ) top left no-repeat;
}
div.outer2 {
	background: url('/intranet/images/demoserver/samuel_salesmanager.jpg' ) 0 -0px no-repeat;
}
div.outer2 a {
	background: url('/intranet/images/demoserver/samuel_salesmanager_bw.jpg' ) top left no-repeat;
}
div.outer3 {
	background: url('/intranet/images/demoserver/andrew_accounting.jpg' ) 0 -0px no-repeat;
}
div.outer3 a {
	background: url('/intranet/images/demoserver/andrew_accounting_bw.jpg' ) top left no-repeat;
}
div.outer4 {
	background: url('/intranet/images/demoserver/petra_projectmanager.jpg' ) 0 -0px no-repeat;
}
div.outer4 a {
	background: url('/intranet/images/demoserver/petra_projectmanager_bw.jpg' ) top left no-repeat;
}
div.outer5 {
	background: url('/intranet/images/demoserver/laura_leadarchitect.jpg' ) 0 -0px no-repeat;
}
div.outer5 a {
	background: url('/intranet/images/demoserver/laura_leadarchitect_bw.jpg' ) top left no-repeat;
}
div.outer6 {
	background: url('/intranet/images/demoserver/harry_helpdesk.jpg' ) 0 -0px no-repeat;
}
div.outer6 a {
	background: url('/intranet/images/demoserver/harry_helpdesk_bw.jpg' ) top left no-repeat;
}
div.outer9 {
	background: url('/intranet/images/demoserver/angelique_pickard.jpg' ) 0 -0px no-repeat;
}
div.outer9 a {
	background: url('/intranet/images/demoserver/angelique_pickard_bw.jpg' ) top left no-repeat;
}
div.outer8 {
	background: url('/intranet/images/demoserver/sheila_carter.jpg' ) 0 -0px no-repeat;
}
div.outer8 a {
	background: url('/intranet/images/demoserver/sheila_carter_bw.jpg' ) top left no-repeat;
}
div.outer span {
	display: block;
	margin:0;
	padding: 1px 0 0 1px;
}
div.outer a:hover {
	background-image: none;
}
tr.off {
	background:#ffffff
}
tr.on {
	background:#ffffcc
}
</style>
<script type="text/javascript">
function removeBgImage (id) {
	var element = document.getElementById("outer" + id);
	element.style.backgroundImage = "none";

	var element = document.getElementById("login" + id);
	element.style.backgroundImage = "none";
}

function setBgImage (id,img) {
	var element = document.getElementById("outer" + id);
	element.style.backgroundImage = "url(" + img + ")";

	var element = document.getElementById("login" + id);
	element.style.backgroundImage = "url('/intranet/images/demoserver/login_bw.jpg')";
}

</script>
</head>

<body bgcolor="white" text="black">
<div id="header_class">
  <div id="header_logo"> <a href="http://www.project-open.org/"><img id="intranetlogo" src="logo.gif" alt="logo" border="0"></a> </div>
  <div id="header_plugin_left"> </div>
  <div id="header_plugin_right"> </div>
  <div id="header_skin_select"> </div>
</div>
<div id="main">
  <div id="navbar_main_wrapper">
    <ul id="navbar_main">
    </ul>
  </div>
  <div id="main_header">
    <div id="main_title">@page_title@</div>
    <div id="main_context_bar"> <a class="contextbar" href="http://po40demo.project-open.net/intranet/">]project-open[</a> : <span class="contextbar">@page_title@</span> </div>
    <div id="main_maintenance_bar"> </div>
    <div id="main_header_deco"></div>
  </div>
</div>
<div id="slave">
<div style="visibility: visible; width:900px; margin:0px auto;" >
<div style="text-align: left">
  <h2>Please select one of the demo accounts in order to login:</h2>
  <p>
    The different users have different permissions. Please choose "Ben Bigboss"
    for maximum permissions.
  </p>
</div>
<br>
<table border="0" cellpadding="10" cellspacing="10" width="100%">
  <tr>
  <td>
  <table border="0" cellpadding="0" cellspacing="0">
    <colgroup>
    <col width="80px">
    <col width="230px">
    </colgroup>
    <tr class="on">
      <td><div class="outer outer1"><a id="outer1" href="/become?user_id=8864&amp;url=/intranet/" ><span></span></a></div></td>
      <td><a href="/become?user_id=8864&amp;url=/intranet/"><b>Login as Ben Bigboss</b><br>
        (Senior Manager)</a></nobr>
    </div>
    <br>
    <br>
    <div style="margin-right: 20px;float: right;width: 47px;height: 20px;background: url('/intranet/images/demoserver/login.jpg') top left no-repeat;"><a href="/become?user_id=8864&amp;url=/intranet/"></a></div>
    </td>
    </tr>  
  </table>
  </a>
  
  </td>
  
  <td>
    <table border="0" cellpadding="0" cellspacing="0">
      <colgroup>
      <col width="80px">
      <col width="230px">
      </colgroup>
      <tr class="off" onmouseover="this.className='on';removeBgImage('2')" onmouseout="this.className='off';setBgImage('2','/intranet/images/demoserver/samuel_salesmanager_bw.jpg')">
        <td><div class="outer outer2"><a href="/become?user_id=8875&amp;url=/intranet/" id="outer2"><span></span></a></div></td>
        <td><a href="/become?user_id=8875&amp;url=/intranet/"><b>Login as Samuel Salesmanager</b><br>
          (Sales Manager)</a></nobr>
      </div>
      <br>
      <br>
      <div class="login"><a href="/become?user_id=8875&amp;url=/intranet/" id="login2"><span></span></a></div>
      </td>
      
      </tr>
      
    </table>
    </a>
    </td>
  </tr>
  <tr>
  
  <td>
  
  <table cellpadding="0" cellspacing="0" border="0">
    <colgroup>
    <col width="80px">
    <col width="230px">
    </colgroup>
    <tr class="off" onmouseover="this.className='on';removeBgImage('3')" onmouseout="this.className='off';setBgImage('3','/intranet/images/demoserver/andrew_accounting_bw.jpg')">
      <td><div class="outer outer3"><a href="/become?user_id=8869&amp;url=/intranet/" id="outer3"><span></span></a></div></td>
      <td><a href="/become?user_id=8869&amp;url=/intranet/"><b>Login as Andrew Accounting</b><br>
        (Accounting)</a></nobr>
    </div>
    <br>
    <br>
    <div class="login"><a href="/become?user_id=8869&amp;url=/intranet/" id="login3"><span></span></a></div>
    </td>
    
    </tr>
    
  </table>
  </td>
  
  <td><table cellpadding="0" cellspacing="0" border="0">
        <colgroup>
        <col width="80px">
        <col width="230px">
        </colgroup>
        <tr class="off" onmouseover="this.className='on';removeBgImage('4')" onmouseout="this.className='off';setBgImage('4','/intranet/images/demoserver/petra_projectmanager_bw.jpg')">
          <td><div class="outer outer4"><a href="/become?user_id=8834&amp;url=/intranet/" id="outer4"><span></span></a></div></td>
          <td><a href="/become?user_id=8843&amp;url=/intranet/"><b>Login as Petra Projectmanager</b><br>
            (Project Manager)</a></nobr>
            </div>
            <br>
            <br>
            <div class="login"><a href="/become?user_id=8843&amp;url=/intranet/" id="login4"><span></span></a></div></td>
        </tr>
      </table></td>
  </tr>
  <tr>
    <td><table cellpadding="0" cellspacing="0" border="0">
        <colgroup>
        <col width="80px">
        <col width="230px">
        </colgroup>
        <tr class="off" onmouseover="this.className='on';removeBgImage('5')" onmouseout="this.className='off';setBgImage('5','/intranet/images/demoserver/laura_leadarchitect_bw.jpg')">
          <td><div class="outer outer5"><a href="/become?user_id=8858&amp;url=/intranet/" id="outer5"><span></span></a></div></td>
          <td><a href="/become?user_id=8858&amp;url=/intranet/"><b>Login as Laura Leadarchitect</b><br>
            (Employee)</a></nobr>
            </div>
            <br>
            <br>
            <div class="login"><a href="/become?user_id=8858&amp;url=/intranet/" id="login5"><span></span></a></div></td>
        </tr>
      </table></td>
    <td><table cellpadding="0" cellspacing="0" border="0">
        <colgroup>
        <col width="80px">
        <col width="230px">
        </colgroup>
        <tr class="off" onmouseover="this.className='on';removeBgImage('6')" onmouseout="this.className='off';setBgImage('6','/intranet/images/demoserver/harry_helpdesk_bw.jpg')">
          <td><div class="outer outer6"><a href="/become?user_id=27484&amp;url=/intranet/" id="outer6"><span></span></a></div></td>
          <td><a href="/become?user_id=27484&amp;url=/intranet/"><b>Login as Harry Helpdesk</b><br>
            (Helpdesk)</a></nobr>
            </div>
            <br>
            <br>
            <div class="login"><a href="/become?user_id=27484&amp;url=/intranet/" id="login6"><span></span></a></div></td>
        </tr>
      </table></td>
  </tr>
  <tr><td colspan=2><hr style="width:740px" align="left"></td></tr>
  <tr>
    <td><table cellpadding="0" cellspacing="0" border="0">
        <colgroup>
        <col width="80px">
        <col width="230px">
        </colgroup>
        <tr class="off" onmouseover="this.className='on';removeBgImage('9')" onmouseout="this.className='off';setBgImage('9','/intranet/images/demoserver/angelique_pickard_bw.jpg')">
          <td><div class="outer outer9"><a href="/become?user_id=8811&amp;url=/intranet/" id="outer9"><span></span></a></div></td>
          <td><a href="/become?user_id=8811&amp;url=/intranet/"><b>Login as Angelique Picard</b><br>
            (External Freelancer)</a></nobr>
            </div>
            <br>
            <br>
            <div class="login"><a href="/become?user_id=8811&amp;url=/intranet/" id="login9"><span></span></a></div></td>
        </tr>
      </table></td>
    <td><table cellpadding="0" cellspacing="0" border="0">
        <colgroup>
        <col width="80px">
        <col width="230px">
        </colgroup>
        <tr class="off" onmouseover="this.className='on';removeBgImage('8')" onmouseout="this.className='off';setBgImage('8','/intranet/images/demoserver/sheila_carter_bw.jpg')">
          <td><div class="outer outer8"><a href="/become?user_id=9203&amp;url=/intranet/" id="outer8"><span></span></a></div></td>
          <td><a href="/become?user_id=9203&amp;url=/intranet/"><b>Login as Sheila Carter</b><br>
            (Customer)</a></nobr>
            </div>
            <br>
            <br>
            <div class="login"><a href="/become?user_id=9203&amp;url=/intranet/" id="login8"><span></span></a></div></td>
        </tr>
      </table></td>
  </tr>
  <tr><td colspan=2><hr style="width:740px" align="left"></td></tr>
  </tbody>
</table>

<table border="0" cellpadding="5" cellspacing="0" width="100%">
  <tbody>
    <tr>
      <td> Comments? Contact: <a href="mailto:support@project-open.com">support@project-open.com</a> </td>
    </tr>
  </tbody>
</table>
<!-- monitor_frame -->
<div class="footer_hack">&nbsp;</div>
<div id="footer"> Comments? Contact: <a href="mailto:sysadmin@tigerpond.com"> sysadmin@tigerpond.com </a> </div>
</body>
</html>
