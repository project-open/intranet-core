<html>
<head>
<title></title>
<script language="javascript" type="text/javascript" src="/resources/acs-templating/mktree.js"></script>

<script language="JavaScript">
//<!--
record_view_url="record-view?man_id=@man_id@&item_id=@ims_item_id@";
applet_url="applet?man_id=@man_id@&return_url=@return_url@<if @ims_item_id@ defined>&item_id=@ims_item_id@</if><if @ims_id@ defined>&ims_id=@ims_item_id@</if>&track_id=@track_id@<if @menu_off@ defined>&menu_off=@menu_off@</if>";
return_url="@return_url@";
menu_off=@menu_off@+0;
debuglevel=@debuglevel@+0;
//-->
</script>

<script language="JavaScript" src="menu.js"></script>

<link rel="stylesheet" type="text/css" href="/resources/acs-templating/mktree.css" type="text/css"> 
<link rel="stylesheet" type="text/css" href="scorm.css" media="all">
</head>

<if @rte@ true>
	<BODY onload="return menu_init();">
</if>
<else>
	<BODY>
</else>
	
<div id="usermessage" class="usermessage_class">
	<if @debuglevel@ gt 0>
	debug is: ON <br>
	delivery is: @deliverymethod@
	</if>
</div>

<div id="abort" onclick="return selfcheck();">
</div>

<div id="btn_finish">
</div>

<div id="menudiv">
<if @menu_off@ lt 1>

<div id="upperbutton">
<a onclick="return selfcheck();" href="exit?man_id=@man_id@&track_id=@track_id@&return_url=@return_url@"
class="button" target="_top">#lorsm.Exit_Course# <br> #lorsm.return_to_LRN#</a>
</div>
<div id="spacer">
<br><br><br>
</div>
<!-- beware the weird hr closing is necessary for mktree to work correctely -->
<div id="tree-within-menu">
<hr size="1" />
<ul class="mktree" id="tree1">
<multiple name="tree_items">
<if @tree_items.indent@ gt @tree_items.last_indent@><ul></if>
<if @tree_items.indent@ lt @tree_items.last_indent@></li></ul></if>
<if @tree_items.indent@ eq @tree_items.last_indent@ and @tree_items.rownum@ ne 1></li></if>
<if @tree_items.link@ not nil>
	</li><li id="@man_id@-@return_url@-@tree_items.rownum@" remember="1">@tree_items.icon;noquote@
	<a href="@tree_items.link@" 
	<if @tree_items.target@ not nil>target="@tree_items.target@"</if>>@tree_items.label@ </a></if>
<else>
	</ul></ul>
	<ul class="mktree" id="@man_id@-@return_url@-@tree_items.rownum@">
	<li id="@man_id@-@return_url@-@tree_items.rownum@" remember="1">@tree_items.icon;noquote@
	<span class="organization_class">@tree_items.label@</span>
</else>
	<if @tree_items.rownum@ eq @tree_items:rowcount@></li></if>
</multiple>
	</ul>
	</li>
	</ul>
</if>
<else>
Menu not available.
</else>
</div>

</div>
</body>
</html>