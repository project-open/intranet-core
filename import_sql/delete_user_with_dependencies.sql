-- In this file we try to delete a user that is 
-- referenced in many parts of the system.


delete from persons where person_id in (8892,13958,8898,11180,18025);

delete from users where user_id in (8892,13958,8898,11180,18025);
update acs_objects set modifying_user = 24332 where modifying_user in (8892,13958,8898,11180,18025);
update im_forum_topics set asignee_id = 24332 where asignee_id in (8892,13958,8898,11180,18025);
update im_projects set project_lead_id = 24332 where project_lead_id in (8892,13958,8898,11180,18025);
NOTICE:  im_project_project_cache_up_tr: 11682
update im_user_absences SET owner_id = 24332 where owner_id in (8892,13958,8898,11180,18025);
update lang_messages_audit set overwrite_user = 24332 where overwrite_user in (8892,13958,8898,11180,18025);
update lang_messages set creation_user = 24332 where creation_user in (8892,13958,8898,11180,18025);
delete from im_fs_folder_status ;
delete from users where user_id in (8892,13958,8898,11180,18025);
delete from persons where person_id in (8892,13958,8898,11180,18025);

