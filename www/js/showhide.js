function initPortlet(){
	if (navigator.userAgent.indexOf("Opera")!=-1
		&& document.getElementById) type="OP";
	if (document.all) type="IE";
	if (document.layers) type="NN";
	if (!document.all && document.getElementById) type="MO";
/*	ShowLayer('showPortletButn_1', 'hidden');      */
};

function ShowLayer(id, action){

  if (navigator.userAgent.indexOf("Opera")!=-1
	&& document.getElementById) type="OP";
  if (document.all) type="IE";
  if (document.layers) type="NN";
  if (!document.all && document.getElementById) type="MO";

  if (type=="IE") eval("document.all." + id + ".style.visibility='" + action + "'");
  if (type=="NN") eval("document." + id + ".visibility='" + action + "'");
  if (type=="MO" || type=="OP")
    eval("document.getElementById('" + id + "').style.visibility='" + action + "'");
}