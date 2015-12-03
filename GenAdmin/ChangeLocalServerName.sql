:setvar old_name "virtual_template_name"
:setvar new_name "actual_server_name"
select @@servername
exec sp_dropserver '$(old_name)'
exec sp_addserver '$(new_name)', local
