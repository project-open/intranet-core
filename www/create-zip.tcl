set_the_usual_form_variables

ns_log notice "*** Doing TAR  $filename ***"

if [ catch {
    exec tar -czf /web/intranet/www/boris/$filename.tgz /home/cluster/Tech/Wemos/$filename/
} errmsg ] {
    ns_log Notice "*** $errmsg ***"
}

ns_log notice "*** After TAR  $filename  download ... ***"
ReturnHeaders

ns_write "

<html>
<head>
<title>Wemo succesfully zipped 
</title>

</head>
<body bgcolor=#FFFFFF>

<h1>You succesfully zipped the wemo into $filename.tgz</h1>

<p>You can either:

<ul>
<li><a href=/boris/$filename.tgz>Download $filename.tgz</a> now or </li>
<li><a href=wemo-list.tcl>Return to the list of wemos</a></li>
</ul>

Adios

</p>

</body>
</html>
"
#ns_httpget http://intranet.competitiveness.com/boris/$filename.tgz
