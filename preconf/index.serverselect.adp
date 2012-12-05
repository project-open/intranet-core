<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"> 
<%
   set page_title "\]po\[ V4.0 Demo Server Farm"
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
	width: 150px;
	height: 75px;
        vertical-align:top;
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
div.outer0 { background: url('/intranet/images/demoserver/timesheet.jpg' ) 0 -0px no-repeat; }
div.outer0 a { background: url('/intranet/images/demoserver/timesheet_bw.jpg' ) top left no-repeat; }
div.outer1 { background: url('/intranet/images/demoserver/cons.gif' ) 0 -0px no-repeat; }
div.outer1 a { background: url('/intranet/images/demoserver/cons_bw.gif' ) top left no-repeat; }
div.outer2 { background: url('/intranet/images/demoserver/samuel_salesmanager.jpg' ) 0 -0px no-repeat; }
div.outer2 a { background: url('/intranet/images/demoserver/samuel_salesmanager_bw.jpg' ) top left no-repeat; }
div.outer3 { background: url('/intranet/images/demoserver/epm.jpg' ) 0 -0px no-repeat; }
div.outer3 a { background: url('/intranet/images/demoserver/epm_bw.jpg' ) top left no-repeat; }
div.outer4 { background: url('/intranet/images/demoserver/petra_projectmanager.jpg' ) 0 -0px no-repeat; }
div.outer4 a { background: url('/intranet/images/demoserver/petra_projectmanager_bw.jpg' ) top left no-repeat; }
/*
div.outer5 { background: url('/intranet/images/demoserver/pmo.jpg' ) 0 -0px no-repeat; }
div.outer5 a { background: url('/intranet/images/demoserver/pmo_bw.jpg' ) top left no-repeat; }
*/
div.outer5 { background: url('/intranet/images/project-open-logo-pmo-edition.jpg' ) 0 -0px no-repeat; }
div.outer5 a { background: url('/intranet/images/demoserver/project-open-logo-pmo-edition_bw.jpg' ) top left no-repeat; }

div.outer6 { background: url('/intranet/images/demoserver/harry_helpdesk.jpg' ) 0 -0px no-repeat; }
div.outer6 a { background: url('/intranet/images/demoserver/harry_helpdesk_bw.jpg' ) top left no-repeat; }
div.outer9 { background: url('/intranet/images/demoserver/itil.jpg' ) 0 -0px no-repeat; }
div.outer9 a { background: url('/intranet/images/demoserver/itil_bw.jpg' ) top left no-repeat; }

/*
div.outer11 { background: url('/intranet/images/demoserver/all.gif' ) 0 -0px no-repeat; }
div.outer11 a { background: url('/intranet/images/demoserver/all_bw.gif' ) top left no-repeat; }
*/ 

div.outer11 { background: url('/intranet/images/demoserver/project-open-logo-plain.jpg' ) 0 -0px no-repeat; }
div.outer11 a { background: url('/intranet/images/demoserver/project-open-logo-plain_bw.jpg' ) top left no-repeat; }

div.outer8 { background: url('/intranet/images/demoserver/sheila_carter.jpg' ) 0 -0px no-repeat; }


div.outer8 a { background: url('/intranet/images/demoserver/sheila_carter_bw.jpg' ) top left no-repeat; }
div.outer span {
	display: block;
	margin:0;
	padding: 1px 0 0 1px;
}
div.outer a:hover { background-image: none; }
tr.off { background:#ffffff }
tr.on { background:#ffffcc }
td { vertical-align: top }
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
      <div id="main_maintenance_bar"> </div>
      <div id="main_header_deco"></div>
    </div>
  </div>
  <div id="slave">
    <div style="visibility: visible; width:900px; margin:0px auto;" >
      <div style="text-align: left">
	<h2>One ]project-open[ -- many configurations:</h2>
	<p>
	  ]project-open[ is the most powerful and complete open-source project management software around.<br>
	  In order to reduce the complexity we have prepared several "configuration templates" for you:
	</p>
      </div>
      <br>

<!-- -->

      <table border="0" cellpadding="10" cellspacing="10" width="100%">

	<tr>
	  <td>
	    <table border="0" cellpadding="0" cellspacing="0">
	      <colgroup>
		<col width="150px">
		<col width="450px">
		<col width="100px">
	      </colgroup>
	      <tr class="off" onmouseover="this.className='on';removeBgImage('0')" onmouseout="this.className='off';setBgImage('0','/intranet/images/demoserver/timesheet_bw.jpg')">
		<td>
		  <div class="outer outer0"><a id="outer0" href="http://po40ts.project-open.net/index-userselect" ></a></div>
		</td>
		<td>
		  <a href="http://po40ts.project-open.net/index-userselect" style="text-decoration: none; color: #000000">
		    <b>Simple Timesheet Tracking</b><br>
	            You just want to track the hours logged on projects?<br>
		    Choose this template to get started quickly.
		    <br><br>
		    <div style="background: url('/intranet/images/demoserver/easy-darkgreen-1.jpg') 0 -0px no-repeat;position:relative; opacity:0.8;background-size: 180px 16px;">
		      <span style="font-weight:bold; color:#FFFFFF;height:16px; margin-left:25px">Easy</span>
		    </div>
		  </a><br>
		  <div class="login"><a href="http://po40cons.project-open.net/index-userselect" id="login0"></a></div>
		</td>
	      </tr>  
	    </table>
	  </td>
	</tr>


	<tr>
	  <td>
	    <table border="0" cellpadding="0" cellspacing="0">
	      <colgroup>
		<col width="150px">
		<col width="450px">
		<col width="100px">
	      </colgroup>
	      <tr class="off" onmouseover="this.className='on';removeBgImage('1')" onmouseout="this.className='off';setBgImage('1','/intranet/images/demoserver/cons_bw.gif')">
		<td>
		  <div class="outer outer1"><a id="outer1" href="http://po40cons.project-open.net/index-userselect" ></a></div>
		</td>
		<td>
		  <a href="http://po40cons.project-open.net/index-userselect" style="text-decoration: none; color: #000000"">
		    <b>PSA - Professional Services Automation</b><br>
	            You are a small or medium company providing professional services.<br>
		    ]po[ allows you to manage your finances and to invoice your services.
		  </a>
		     <br><br>
		    <div style="background: url('/intranet/images/demoserver/medium-yellow-3.jpg' ) 0 -0px no-repeat;position:relative;opacity:0.8;background-size: 180px 16px;">
		      <span style="font-weight:bold; color:#000000;height:16px; margin-left:60px">Medium</span>
		    </div>
		  <div class="login"><a href="http://po40cons.project-open.net/index-userselect" id="login1"></a></div>
		</td>
	      </tr>  
	    </table>
	  </td>
	</tr>
<!--
	<tr>
	  <td>
	    <table cellpadding="0" cellspacing="0" border="0">
	      <colgroup>
		<col width="150px">
		<col width="450px">
	      </colgroup>
	      <tr class="off" onmouseover="this.className='on';removeBgImage('3')" onmouseout="this.className='off';setBgImage('3','/intranet/images/demoserver/epm_bw.jpg')">
		<td><div class="outer outer3"><a href="http://po40ppm.project-open.net/index-userselect" id="outer3"></a></div></td>
		<td>
		  <a href="http://po40ppm.project-open.net/index-userselect" style="text-decoration: none; color: #000000">
		    <b>EPM - Enterprise Project Management</b><br>
	            You are a department of a larger enterprise.<br>
		    Example: IT department, research and development, product development, ...
		  </a>
		  <br>
		  <br>
		  <div class="login"><a href="http://po40ppm.project-open.net/index-userselect" id="login3"></a></div>
		</td>
	      </tr>
	    </table>
	  </td>
	</tr>

-->

	<tr>
	  <td>
	    <table cellpadding="0" cellspacing="0" border="0">
	      <colgroup>
	        <col width="150px">
	        <col width="450px">
	      </colgroup>
	      <tr class="off" onmouseover="this.className='on';removeBgImage('5')" onmouseout="this.className='off';setBgImage('5','/intranet/images/demoserver/project-open-logo-pmo-edition_bw.jpg')">
	        <td><div class="outer outer5"><a href="http://po40pmo.project-open.net/index-userselect" id="outer5"></a></div></td>
	        <td>
		  <b>
		  <a href="http://po40pmo.project-open.net/index-userselect" style="text-decoration: none; color: #000000">PMO - Project Management Office</a>
		  </b><br>
	          <a href="http://po40pmo.project-open.net/index-userselect" style="text-decoration: none; color: #000000">
		    Everything you need in order to run your PMO.<br>Edition provided in collaboration with </a> <a href="http://www.pentamino.de/" target="_">Pentamino</a>
		  <br><br>
		    <div style="background: url('/intranet/images/demoserver/medium-yellow-3.jpg' ) 0 -0px no-repeat;position:relative; opacity:0.8;background-size: 180px 16px;">
		      <span style="font-weight:bold; color:#000000;height:16px; margin-left:60px">Medium</span>
		    </div>
		  <br>
	          <div class="login"><a href="http://po40pmo.project-open.net/index-userselect" id="login5"></a></div>
		</td>
	      </tr>
	    </table>
	</td></tr>
	<tr>
	  <td>
	    <table cellpadding="0" cellspacing="0" border="0">
	      <colgroup>
	        <col width="150px">
	        <col width="450px">
	      </colgroup>
	      <tr class="off" onmouseover="this.className='on';removeBgImage('9')" onmouseout="this.className='off';setBgImage('9','/intranet/images/demoserver/itil_bw.jpg')">
	        <td><div class="outer outer9"><a href="http://po40itsm.project-open.net/index-userselect" id="outer9"></a></div></td>
	        <td><a href="http://po40itsm.project-open.net/index-userselect" style="text-decoration: none; color: #000000">
		    <b>ITSM and ITIL - IT Services Management</b><br>
		    You are running a help desk or service desc for <br>
		    internal or external customers.
		  </a>
	          <br><br>
                    <div style="background: url('/intranet/images/demoserver/medium-yellow-3.jpg' ) 0 -0px no-repeat;position:relative;opacity:0.8;background-size: 180px 16px;">
                      <span style="font-weight:bold; color:#000000;height:16px; margin-left:60px">Medium</span>
                    </div>
	          <div class="login"><a href="http://po40itsm.project-open.net/index-userselect" id="login9"></a></div>
		</td>
	      </tr>
	    </table>
	  </td>
	</tr>
	<tr>
	  <td>
	    <table cellpadding="0" cellspacing="0" border="0">
	      <colgroup>
	        <col width="150px">
	        <col width="450px">
	      </colgroup>
	      <tr class="off" onmouseover="this.className='on';removeBgImage('11')" onmouseout="this.className='off';setBgImage('11','/intranet/images/demoserver/project-open-logo-plain_bw.jpg')">
	        <td><div class="outer outer11"><a href="http://po40demo.project-open.net/index-userselect" id="outer11"></a></div></td>
	        <td><a href="http://po40demo.project-open.net/index-userselect"  style="text-decoration: none; color: #000000"">
		    <b>All ]po[ Functionality </b><br>
		    This demo server contains all ]po[ functionality.
		    <br><br>
		    <div style="background: url('/intranet/images/demoserver/high-red-5.jpg' ) 0 -0px no-repeat;position:relative;opacity:0.8;background-size: 180px 16px;">
		      <span style="font-weight:bold; color:#FFFFFF;height:16px; margin-left:95px">Complex</span>
		    </div>
		  </a>
	          <br>
	          <div class="login"><a href="http://po40itsm.project-open.net/index-userselect" id="login11"></a></div>
		</td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>

<!-- -->
    </div>
  </div>
      
  <br>
  <br>
  
  <hr style="width:740px" align="left">
  
  <table border="0" cellpadding="5" cellspacing="0" width="100%">
    <tbody>
      <tr>
	<td> Comments? Contact: <a href="mailto:support@project-open.com">support@project-open.com</a> </td>
      </tr>
    </tbody>
  </table>
  <!-- monitor_frame -->
  <div class="footer_hack">&nbsp;</div>
</body>
</html>
