<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<link rel=StyleSheet type=text/css href="/calendar/resources/calendar.css" media=screen>
<link rel=StyleSheet type=text/css href="/intranet/style/style.left.css" media=screen>
<link rel=StyleSheet type=text/css href="/resources/acs-templating/mktree.css" media=screen>
<script type=text/javascript src="/intranet/js/jquery-1.2.3.pack.js"></script>
<script type=text/javascript src="/intranet/js/showhide.js"></script>
<script type=text/javascript src="/resources/diagram/diagram/diagram.js"></script>
<script type=text/javascript src="/resources/core.js"></script>
<script type=text/javascript src="/intranet/js/rounded_corners.inc.js"></script>
<script type=text/javascript src="/resources/acs-templating/mktree.js"></script>
<script type=text/javascript src="/intranet/js/style.left.js"></script>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<!--[if lt IE 7.]>
<script defer type='text/javascript' src='/intranet/js/pngfix.js'></script>
<![endif]-->

<title>Login</title>
</head>
<body bgcolor="white" text="black" >

	<div id="monitor_frame">
	   <div id="header_class">
	      <div id="header_logo">         
<a href="http://www.genedata.com/"><img src="/genedata_logo.gif" alt="intranet logo" border=0></a>
	      </div>      
      <div id="header_buttons">
         <div id="header_logout_tab">
            <div id="header_logout">
	       <a class="nobr" href='/register/logout'>Log Out</a>
            </div>
         </div>


         <div id="header_settings_tab">
            <div id="header_settings">              
	<a href="/intranet/users/view?user_id=30413">My Account</a> |
    <a href="/intranet/users/password-update?user_id=30413">Change Password</a> | 
               <a href="/intranet/components/component-action?return%5furl=%2fintranet%2f&amp;action=reset&amp;plugin%5fid=0&amp;page%5furl=%2fintranet%2findex">Reset Stuff</a> |
	       <a href="/intranet/components/add-stuff?return%5furl=%2fintranet%2f&amp;page%5furl=%2fintranet%2findex">Add Stuff</a>
            </div>
         </div>
      </div>
       
	      <div id="header_skin_select">
	         Skin: 
       <form method="GET" action="/intranet/users/select-skin">
       <input type="hidden" name="return_url" value="/intranet/" />
<input type="hidden" name="user_id" value="30413" />

       <select name="skin">
    <option value=0 selected=selected>Default</option><option value=1 >Light Green</option><option value=2 >Right Blue</option><option value=4 >SaltnPepper</option>
       </select>
       <input type=submit value="Change">
       </form>
    
      </div>   
   </div>


    
	    <div id="main">
	       <div id="navbar_main_wrapper">
	          <ul id="navbar_main">
	             <li class="selected"><div class="navbar_selected"><a href="/intranet/"><span>Home</span></a></div></li>
	          </ul>
	       </div>
	       <div id="main_header">
	          <div id="main_title">
	             Home
	          </div>
	          <div id="main_context_bar">
	             <a class=contextbar href="/intranet/">&#93;project-open&#91;</a> : <span class=contextbar>Home</span>
	          </div>

	          <div id="main_portrait_and_username">
	          <div id="main_portrait">
	            <img width=98 height=98 src=/intranet/images/anon_portrait.gif border=0 title="Portrait" alt="Portrait">
	          </div>
	          </div>
	          
          <div id="main_users_and_search">
          </div>
    
	          <div id="main_header_deco"></div>
	       </div>
	    </div>
    

<div id="slave">
<div id="slave_content">



<!-- Include the login widget -->
<include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" &="__adp_properties">


</div>
</div>

</div> <!-- monitor_frame -->



    <div class="footer_hack">&nbsp;</div>	
    <div id="footer">
       Comments? Contact: 
       <a href="mailto:support@genedata.com">
          support@genedata.com
       </a> 
    </div>
  
</BODY>
</HTML>
