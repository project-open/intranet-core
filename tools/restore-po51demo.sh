################################################################
#   (c)  klaus.hofeditz@project-open.com and
#        frank.bergmann@project-open.com
# 
#   v0.4  - USE WITH CAUTION
#
#   Last changed: 2020-12-17
#
#   restores po51demo, daily cronjob  
#
################################################################

echo "******************************************"
echo "restore-po51demo.sh"
echo "******************************************"



echo "systemctl stop po@po51demo"
systemctl stop po@po51demo
sleep 1

echo "killall -9 nsd; dropdb po51demo"
/bin/su --login po51demo --command "rm /web/po51demo/log/error*.*"
/bin/su --login po51demo --command "killall -9 nsd; dropdb po51demo"
sleep 1

echo "createdb --owner po51demo po51demo --encoding=utf8"
/bin/su --login postgres --command "createdb --owner po51demo po51demo --encoding=utf8"
sleep 1

# echo "sed -i 's/projop/po51demo/g' /web/po51demo/filestorage/backup/po51demo.default.sql"
# /bin/su --login po51demo --command "/bin/sed -i 's/projop/po51demo/g' /web/po51demo/filestorage/backup/po51demo.default.sql"

echo "psql -f po51demo.default.sql"
/bin/su --login po51demo --command "/usr/bin/psql -f /web/po51demo/filestorage/backup/po51demo.default.sql > /web/po51demo/filestorage/backup/import.log 2>&1 "

echo "psql -c 'update persons set demo_password = null where ...'"
/bin/su --login po51demo --command "psql -c '
update persons set demo_password = null where person_id in (select member_id from group_distinct_member_map where group_id = 459)'"

echo "psql -c 'update persons set demo_group = ...'"
/bin/su --login po51demo --command "psql -c \"
update persons set demo_group = '1st - Senior Managers' where demo_group = 'Senior Managers'\""

echo "psql -c 'update users set password, salt = ...'"
/bin/su --login po51demo --command "psql -c \"
update users set
	password = 'F0C92552298A6F2E831F31BEA324E7988FB47E8A',
	salt = '015330F10DAAE596590EAB22EE460FFF840B6884'
where user_id in (
	select member_id from group_distinct_member_map where group_id = 459
)\""

echo "psql -c 'update apm_parameters where ...parameter_name = 'SuppressHttpPort''"
/bin/su --login po51demo --command "psql -c \"update apm_parameter_values set attr_value = '1' where parameter_id in (select parameter_id from apm_parameters where parameter_name = 'SuppressHttpPort')\""
/bin/su --login po51demo --command "psql -c \"update apm_parameter_values set attr_value = '1' where parameter_id in (select parameter_id from apm_parameters where parameter_name = 'MoveDemoProjectsWithNextRestartP')\""


echo "systemctl start po@po51demo"
systemctl start po@po51demo
