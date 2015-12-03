set nocount on;
declare @cmd varchar(max);
declare @distributor varchar(255);
select @distributor = quotename(name,'[') from sys.databases where is_distributor = 1; 
select @cmd = '
with pubs as (
	select publisher_id, publisher_db, publication_id, publication
	, case publication_type when 0 then ''TRANS'' when 1 then ''SNPSH'' when 2 then ''MERGE'' end as publication_type
	from ' + @distributor + '..MSpublications)
, arts as (
	select publisher_id, publisher_db, publication_id, article_id , article, source_owner, source_object, destination_owner, destination_object 
	from ' + @distributor + '..MSarticles )
, subs as (
	select publisher_id, publisher_db, publication_id, publisher_database_id, article_id, subscriber_id, subscriber_db, agent_id
	, case subscription_type when 1 then ''PULL'' when 2 then ''ANON'' when 0 then ''PUSH'' end as subscription_type 
	from ' + @distributor + '..MSsubscriptions )
, servers as (
	select server_id, name from sys.servers )
, agents as (
	select ''Distribution'' as AgentType, id, name, publisher_db, publication, subscriber_id, subscriber_db from distribution..MSdistribution_agents union all 
	select ''LogReader'' as AgentType, id, name, publisher_db, publication, null, null from distribution..MSlogreader_agents union all 
	select ''Snapshot'' as AgentType, id, name, publisher_db, publication, null, null from distribution..MSsnapshot_agents
)
select @@SERVERNAME as server
, ''' + @distributor + ''' as distributor
, getdate() as collection_date
/* Publisher */
, p.name as publisher, pubs.publisher_db, arts.source_owner, arts.source_object
/* Subscriber */
, replace(servers.name,'','','':'') as subscriber, subs.subscriber_db, coalesce(arts.destination_owner, arts.source_owner) as destination_owner, arts.destination_object 
/* Subscription */
, pubs.publication, pubs.publication_type, arts.article, subscription_type
/* Distributor*/
, agents.name
from servers p
join pubs on p.server_id = pubs.publisher_id
left join (arts
join subs on arts.publisher_id = subs.publisher_id and arts.publication_id = subs.publication_id and arts.article_id = subs.article_id
join servers on subs.subscriber_id = servers.server_id
join agents on subs.agent_id = agents.id and agents.AgentType = ''Distribution'')   on pubs.publisher_id = arts.publisher_id and pubs.publication_id = arts.publication_id
'

exec (@cmd)



