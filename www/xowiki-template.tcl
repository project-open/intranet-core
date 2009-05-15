# /packages/intranet-core/www/xowiki-template.tcl

set system_id [im_system_id]

set survey_id [util_memoize [list db_string q1 "
	select survey_id 
	from survsimp_surveys 
	where short_name = 'xowiki_feedback'
" -default 0]]

set system_id_question_id [util_memoize [list db_string q2 "
	select question_id 
	from survsimp_questions 
	where survey_id = $survey_id and question_text = 'system_id'
" -default ""]]

set item_id_question_id [util_memoize [list db_string q3 "
	select question_id 
	from survsimp_questions 
	where survey_id = $survey_id and question_text = 'content_item_id'
" -default ""]]

set title_question_id [util_memoize [list db_string q4 "
	select question_id 
	from survsimp_questions 
	where survey_id = $survey_id and question_text = 'title'
" -default ""]]

set url_question_id [util_memoize [list db_string q5 "
	select question_id 
	from survsimp_questions 
	where survey_id = $survey_id and question_text = 'url'
" -default ""]]

set goal_question_id [util_memoize [list db_string q5 "
	select question_id 
	from survsimp_questions 
	where survey_id = $survey_id and question_text = 'goal'
" -default ""]]

set rating_question_id [util_memoize [list db_string q5 "
	select question_id 
	from survsimp_questions 
	where survey_id = $survey_id and question_text = 'rating'
" -default ""]]

set comment_question_id [util_memoize [list db_string q6 "
	select question_id 
	from survsimp_questions 
	where survey_id = $survey_id and question_text = 'comment'
" -default ""]]
