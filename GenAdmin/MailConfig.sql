:setvar servername "sending_host_name"
:setvar client_email_suffix "client.com"
:setvar smtp_server_name "192.168.1.1"
:setvar smtp_port "25"

exec sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
exec sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE
GO
use msdb;
go
declare @accountid int
, @profileid int
, @servername varchar(255) = '$(servername)'

exec sysmail_add_account_sp  @account_name = 'Relay'
, @email_address =  'noreply@$(client_email_suffix)'
, @display_name =  @servername
, @replyto_address =  'noreply@$(client_email_suffix)'
, @mailserver_name =  '$(smtp_server_name)'
, @mailserver_type =  'SMTP'
, @port = $(smtp_port)
, @account_id = @accountid OUTPUT;

exec sysmail_add_profile_sp @profile_name = 'DBA Alerts'
, @profile_id = @profileid OUTPUT

exec sysmail_add_profileaccount_sp @profile_id = @profileid
, @account_id = @accountid
, @sequence_number = 1
