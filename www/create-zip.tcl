# /packages/intranet-core/www/create-zip.tcl
#
# Copyright (C) 1998-2004 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

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
