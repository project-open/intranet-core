################################################################
#   (c)  klaus.hofeditz@project-open.com and
#        frank.bergmann@project-open.com
# 
#   v0.3  - USE WITH CAUTION
#
#   Last changed: 2017-02-20
#
#   restores po50demo, daily cronjob  
#
################################################################

echo "******************************************"
echo "restore-po50demo.sh"
echo "******************************************"



echo "svc -d /web/service/po50demo"
/usr/local/bin/svc -d /web/service/po50demo
sleep 3

echo "killall -9 nsd; dropdb po50demo"
/bin/su --login po50demo --command "rm /web/po50demo/log/error*.*"
/bin/su --login po50demo --command "killall -9 nsd; dropdb po50demo"
sleep 1

echo "createdb --owner po50demo po50demo --encoding=utf8"
/bin/su --login po50demo --command "createdb --owner po50demo po50demo --encoding=utf8"
sleep 1

echo "sed -i 's/projop/po50demo/g' /web/po50demo/filestorage/backup/po50demo.default.sql"
/bin/su --login po50demo --command "/bin/sed -i 's/projop/po50demo/g' /web/po50demo/filestorage/backup/po50demo.default.sql"

echo "psql -f po50demo.default.sql"
/bin/su --login po50demo --command "/usr/local/pgsql95/bin/psql -f /web/po50demo/filestorage/backup/po50demo.default.sql > /web/po50demo/filestorage/backup/import.log 2>&1 "

echo "psql -c 'update persons set demo_password = null where ...'"
/bin/su --login po50demo --command "psql -c '
update persons set demo_password = null where person_id in (select member_id from group_distinct_member_map where group_id = 459)'"

echo "psql -c 'update persons set demo_group = ...'"
/bin/su --login po50demo --command "psql -c \"
update persons set demo_group = '1st - Senior Managers' where demo_group = 'Senior Managers'\""

echo "psql -c 'update users set password, salt = ...'"
/bin/su --login po50demo --command "psql -c \"
update users set
	password = 'F0C92552298A6F2E831F31BEA324E7988FB47E8A',
	salt = '015330F10DAAE596590EAB22EE460FFF840B6884'
where user_id in (
	select member_id from group_distinct_member_map where group_id = 459
)\""

echo "psql -c 'update apm_parameters where ...parameter_name = 'SuppressHttpPort''"
/bin/su --login po50demo --command "psql -c \"update apm_parameter_values set attr_value = '1' where parameter_id in (select parameter_id from apm_parameters where parameter_name = 'SuppressHttpPort')\""


echo "svc -u /web/service/po50demo"
/usr/local/bin/svc -u /web/service/po50demo






