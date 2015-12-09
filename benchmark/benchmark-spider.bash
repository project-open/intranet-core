#!/bin/bash
# benchmark-spider.bash
# (c) 2015 Project Open Business Solutions, S.L.
# 
# Copy this script into ~/spider/ and execute there.
# The script spiders the entire server using a 
# recursive WGET call, while avoiding those admin 
# directories that can break the system like removing 
# site-map notes or deleting GUI components.
#
# You need to install a ~/www/become.tcl file
# ike this before executing:
#
# ad_page_contract {
#    Dangerous - remove before publishing
#} {
#    { user_id:integer,notnull 624 }
#    { url "/intranet/" }
#}
#
#ad_user_login $user_id
#ad_returnredirect $url

# Enabled all Portlets & Menus
#
psql -c "delete from im_component_plugin_user_map"
psql -c "update im_menus set enabled_p = 't'"
psql -c "update im_component_plugins set enabled_p = 't'"

# Delete WGET results
rm -rf ~/spider/localhost

wget -nv -r --exclude-directories=\
/admin/,\
/acs-admin/,\
/acs-admin/site-map/,\
/acs-admin/server-restart,\
/acs-lang/admin/,\
/ds/,\
/intranet/admin/backup/,\
/intranet/admin/toggle,\
/intranet/admin/toggle-enabled,\
/intranet/admin/categories/toggle,\
/intranet/admin/menus/toggle,\
/intranet/admin/views/del-column,\
/intranet/components/component-action,\
/intranet-sysconfig/,\
/intranet-security-update-client/get-exchange-rate,\
/permissions/,\
/simple-survey/admin/,\
/xotcl/ \
http://localhost/become > ~/spider/spider.log 2>&1 &

