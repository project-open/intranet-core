<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>

	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<title>@title;noquote@</title>
        <meta name="keywords" content="Open Source, Project Management, Project Portfolio Management, ERP, Financial Management, Professional Service Automation, Knowledge Management, Workflow, Project Collaboration, Business Process Automatization, Information Management, Invoicing">
        <meta name="description" content="]project-open[ is an Open Source Project Management/ERP tool">
	<meta name='language' content='en'>
	<meta name='generator' lang='en' content='OpenACS version 5.4.0'>

	<link href='/intranet/style/style.saltnpepper.css' rel='stylesheet'  type='text/css' media='screen'>
	<link href='/resources/acs-templating/mktree.css' rel='stylesheet'  type='text/css' media='screen'>
	<link href="/resources/xowiki/xowiki.css" rel='stylesheet' type="text/css" media="all" >
	<link href='/resources/xowiki/cattree.css' rel='stylesheet' media='all' >
	<link href='/resources/acs-templating/lists.css' rel='stylesheet' type="text/css" media='all' >
	
	<!--[if lt IE 7.]>
	<script defer type='text/javascript' src='/intranet/js/pngfix.js'></script>
	<![endif]-->
	<script type='text/javascript' src='/intranet/js/jquery-1.2.3.pack.js'></script>
	<script type='text/javascript' src='/resources/acs-templating/mktree.js'></script>
	<script type='text/javascript' src='/intranet/js/rounded_corners.inc.js'></script>
	<script type='text/javascript' src='/resources/diagram/diagram/diagram.js'></script>
	<script type='text/javascript' src='/intranet/js/showhide.js'></script>
	<script type='text/javascript' src='/resources/acs-subsite/core.js'></script>
	<script type='text/javascript' src='/intranet/js/style.saltnpepper.js'></script>
	<script type='text/javascript' src='/resources/acs-templating/mktree.js'></script>

	<!-- header stuff -->
	@header_stuff;noquote@
	<!-- /header stuff -->

	<script type="text/javascript">
	function get_popular_tags(popular_tags_link, prefix) {
	  var http = getHttpObject();
	  http.open('GET', popular_tags_link, true);
	  http.onreadystatechange = function() {
	    if (http.readyState == 4) {
	      if (http.status != 200) {
		alert('Something wrong in HTTP request, status code = ' + http.status);
	      } else {
	       var e = document.getElementById(prefix + '-popular_tags');
	       e.innerHTML = http.responseText;
	       e.style.display = 'block';
	      }
	    }
	  };
	  http.send(null);
	}
	</script>

</head>
<body bgcolor="white" text="black">


<!-- ---------------------------------------------------- -->
<!-- Body						  -->
<!-- ---------------------------------------------------- -->

	<div id="monitor_frame">
	   <div id="header_class">
	      <div id="header_logo">
		<a href="http://www.project-open.org/"><img src="/intranet/images/logo.default.gif" alt="intranet logo" border=0></a>
	      </div>
	      <div id="header_plugin_left">	 
	      </div>
	      <div id="header_plugin_right">
	      </div>

	      
      <div id="header_buttons">
	<div id="header_logout_tab">
	    <div id="header_logout">
	    </div>
	</div>
	 <div id="header_settings_tab">
	    <div id="header_settings">
	    </div>
	 </div>
      </div>      
	      <div id="header_skin_select">
	      </div>   
	   </div>
	    <div id="main">
	       <div id="navbar_main_wrapper">
	       </div>

	       <div id="main_header">
		  <div id="main_title">
		  </div>
		  <div id="main_context_bar">
		     <a class=contextbar href="/intranet/">&#93;project-open&#91;</a> : <span class=contextbar>@This Wiki</span>
		  </div>
		  <div id="main_maintenance_bar">

		     
		  </div>
		  <div id="main_portrait_and_username">
		  <div id="main_portrait">
		    <img width=98 height=98 src="/intranet/images/anon_portrait.gif" border=0 title="Portrait" alt="Portrait">
		  </div>
		  <p id="main_username">
		    Welcome, Unregistered Visitor
		  </p>
		  </div>
  
		  <div id="main_header_deco"></div>
	       </div>
	    </div>

<div class="fullwidth-list-no-side-bar" id="fullwidth-list">

<!-- ---------------------------------------------------- -->

<!-- The following DIV is needed for overlib to function! -->
<div id="overDiv" style="position:absolute; visibility:hidden; z-index:1000;"></div>	

<!-- ---------------------------------------------------- -->
<div class='xowiki-content'>
<div id='wikicmds'>
  ...
  <if @view_link@ not nil><a href="@view_link@" accesskey='v' title='#xowiki.view_title#'>#xowiki.view#</a> &middot; </if>
  <if @edit_link@ not nil><a href="@edit_link@" accesskey='e' title='#xowiki.edit_title#'>#xowiki.edit#</a> &middot; </if>
  <if @rev_link@ not nil><a href="@rev_link@" accesskey='r' title='#xowiki.revisions_title#'>#xotcl-core.revisions#</a> &middot; </if>
  <if @new_link@ not nil><a href="@new_link@" accesskey='n' title='#xowiki.new_title#'>#xowiki.new_page#</a> &middot; </if>
  <if @delete_link@ not nil><a href="@delete_link@" accesskey='d' title='#xowiki.delete_title#'>#xowiki.delete#</a> &middot; </if>
  <if @admin_link@ not nil><a href="@admin_link@" accesskey='a' title='#xowiki.admin_title#'>#xowiki.admin#</a> &middot; </if>
  <if @notification_subscribe_link@ not nil><a href='/notifications/manage' title='#xowiki.notifications_title#'>#xowiki.notifications#</a> 
      <a href="@notification_subscribe_link@">@notification_image;noquote@</a> &middot; </if>  
  <if @index_link@ not nil><a href="@index_link@" accesskey='i' title='#xowiki.index_title#'>#xowiki.index#</a></if>
  &middot; 
  <if @login_link@ not nil><a href="@login_link@" accesskey='l' title='#xowiki.login_title#'>#xowiki.login#</a></if>
  <if @logout_link@ not nil><a href="@logout_link@" accesskey='l' title='#xowiki.logout_title#'>#xowiki.logout#</a></if>

</div>
  <div id='do_search'> 
    <FORM action='/search/search'><div><label for='do_search_q'>#xowiki.search#:&nbsp;</label><INPUT id='do_search_q' name='q' type='text'><INPUT type="hidden" name="search_package_id" value="@package_id@" ></div>
    </FORM> 
  </div>

<div style="float:left; width: 25%; font-size: 85%;
     background: url(/resources/xowiki/bw-shadow.png) no-repeat bottom right;
     margin-left: 2px; margin-top: 2px; padding: 0px 6px 6px 0px;			    
">

<div style="margin-top: -2px; margin-left: -2px; border: 1px solid #a9a9a9; padding: 5px 5px; background: #f8f8f8;">
<include src="/packages/xowiki/www/portlets/include" 
	 &__including_page=page 
	 portlet="categories -open_page @name@  -decoration plain">
</div></div>
<div style="float:right; width: 70%;">
@top_includelets;noquote@
<h1>@title@</h1>

<%




%>


@content;noquote@
</div>


<!--<div class='item-footer'>-->
<form enctype="multipart/form-data" method="post" action="/simple-survey/process-response">
<input value="@survey_id@" name="survey_id" type="hidden">
<input value="@system_id@" name="response_to_question.@system_id_question_id@" type="hidden">
<input value="@item_id@" name="response_to_question.@item_id_question_id@" type="hidden">
<input value="@title@" name="response_to_question.@title_question_id@" type="hidden">
<input value="http://www.project-open.net/en/contact_thanks" name="return_url" type="hidden">
<script language="javascript" type="text/javascript">
document.write('<input type="hidden" name="response_to_question.@url_question_id@" value="'+location.href+'" >');
</script>

<table width="100%" border=0 cellspacing="6" cellpadding="6">
<tr valign="top">
	<td colspan="2">
	Please take a moment to complete this form to help us improve our service.
	</td>
</tr>
<tr valign="top"><td colspan=2></td></tr>
<tr valign="top">
	<td width="100"><p>Did this page help you to achieve your goal?</p></td>
	<td width="303">
		<table cellspacing="0" cellpadding="0" border="0">
		<tr>
		<td width="60"><input value="9" name="response_to_question.@goal_question_id@" type="radio">&nbsp;Yes</td>
		<td width="60"><input value="10" name="response_to_question.@goal_question_id@" type="radio">&nbsp;No</td>
		<td width="160"><input value="11" name="response_to_question.@goal_question_id@" type="radio">&nbsp;Don't know</td>
		</tr>
		</table>
	</td>
</tr>
<tr valign="top"><td colspan=2></td></tr>
<tr valign="top">
	<td><p>Please provide us with comments to improve this page:</p></td>
	<td>
		<table width="100%" cellspacing="0" cellpadding="0" border="0">
		<tr>
		<td><textarea cols="35" rows="2" wrap="virtual" name="response_to_question.@comment_question_id@"></textarea></td>
		</tr>
		</table>
	</td>
</tr>
<tr valign="top"><td colspan=2></td></tr>
<tr valign="top">
	<td><p>How useful is the information?</p></td>
	<td>
		<table cellspacing="0" cellpadding="0" border="0">
		<tr>
		<td align="left" width="60"><input value="1" name="response_to_question.@rating_question_id@" type="radio">&nbsp;1</td>
		<td align="left" width="60"><input value="2" name="response_to_question.@rating_question_id@" type="radio">&nbsp;2</td>
		<td align="left" width="60"><input value="3" name="response_to_question.@rating_question_id@" type="radio">&nbsp;3</td>
		<td align="left" width="60"><input value="4" name="response_to_question.@rating_question_id@" type="radio">&nbsp;4</td>
		<td align="left" width="60"><input value="5" name="response_to_question.@rating_question_id@" type="radio">&nbsp;5</td>
		</tr>
		<tr>
		<td align="left" width="60"><span class="greytext">Not</span><br ><span class="greytext">useful</span></td>
		<td align="left" width="60">&nbsp;</td>
		<td align="left" width="60">&nbsp;</td>
		<td align="left" width="60">&nbsp;</td>
		<td align="left" width="60"><span class="greytext">Extremely<br >useful</span></td>
		</tr>
		</table>
	</td>
</tr>
<tr valign="top"><td colspan=2></td></tr>
<tr valign="top">
	<td>&nbsp;</td>
	<td><input type=submit name=Submit value="&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Submit&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"></td>

</tr>
</table>
</form>
<!--</div>-->


@footer;noquote@


</div> <!-- class='xowiki-content' -->
</div>
</div> <!-- monitor_frame -->

</BODY>
</HTML>
