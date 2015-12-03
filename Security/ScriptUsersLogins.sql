/*
Run in text mode with 8192 characters
Output is a script to create existing logins
*/

CREATE PROCEDURE dbo.recovery_create_server_logins
   @login_name varchar(256) = null
    , @database_name varchar(256) = null
    , @set_master_as_default int = null
as
begin
    set nocount on
    select [sid] into #sids from sys.server_principals where 1 = 2
    select @login_name = isnull(@login_name, '') 
    select @database_name = isnull(@database_name, '') 
    if isnull(@login_name, '') <> ''
    insert #sids select [sid] from sys.server_principals where name = @login_name and name <> 'sa'
    if isnull(@database_name, '') <> ''
    begin
        declare @dbcmd varchar(1000)
        set @dbcmd = 'select p.sid from sys.server_principals p join ' + quotename(@database_name) + '.sys.database_principals d on p.sid = d.sid where p.name <> ''sa'''
        insert #sids exec(@dbcmd)
    end
    if isnull(@login_name, '') = '' and isnull(@database_name, '') = ''
        insert #sids select [sid] from sys.server_principals where is_disabled = 0 and name <> 'sa'
    select @set_master_as_default = isnull(@set_master_as_default,0)
    select '--Executed by login:    ' + cast(suser_name() as varchar(255)) as [/* Script Info */] union all
    select '--Script Generated on:    ' + cast(getdate() as varchar(255)) union all
    select '--Specified Login:        ' + cast(@login_name as varchar(255)) union all
    select '--Specified Database:    ' + cast(@database_name as varchar(255)) 

    declare @binvalue varbinary(256)
    declare @pwdhash varchar(514)
    declare @sidhash varchar(514)
    declare @login varchar(256)
    declare @defdb varchar(256)
    declare @chkpol varchar(3)
    declare @chkexp varchar(3)

    select cast(null as varchar(max)) as [/* Script Enabled Logins */] into #tmp 

    declare acursor cursor for 
    select 
         name
        , case @set_master_as_default when 0 then default_database_name else 'master' end as default_database_name
        , case is_policy_checked when 1 then 'ON' when 0 then 'OFF' else '' end
        , case is_expiration_checked when 1 then 'ON' when 0 then 'OFF' else '' end
    from sys.sql_logins
    where type = 'S'
    and is_disabled = 0
    and [sid] in (select [sid] from #sids)

    open acursor 
    fetch acursor into @login , @defdb , @chkpol , @chkexp 
    while @@fetch_status = 0
    begin

        /* Password Hash */
        select @binvalue = cast(loginproperty(@login, 'passwordhash') as varbinary(256)) ;
        with 
         bintab ([int], [pos], [div], [mod], [vals]) as (
            select cast(substring(@binvalue,1,1) as int)
            , 1
            , cast(floor(cast(substring(@binvalue,1,1) as int)/16) as int)
            , cast((cast(substring(@binvalue,1,1) as int) % 16) as int)
            , cast('0123456789ABCDEF' as char(16)) 
            union all
            select cast(substring(@binvalue,b.[pos] + 1,1) as int)
            , b.[pos] + 1
            , cast(floor(cast(substring(@binvalue,b.[pos] + 1,1) as int)/16) as int)
            , cast((cast(substring(@binvalue,b.[pos] + 1,1) as int) % 16) as int)
            , cast('0123456789ABCDEF' as char(16)) 
            from bintab b
            where b.[pos] < datalength(@binvalue)
         )
        , vals as (
            select [pos]
            , substring([vals],[div]+1,1) + substring([vals],[mod]+1,1) as [val]
            from bintab
         )
        , cte as (
            select pos, cast('0x' + val as varchar(514)) as val
            from vals
            where pos = 1
            union all
            select vals.pos, cast(cte.val + vals.val as varchar(514))
            from cte 
            join vals on cte.pos = vals.pos - 1
         )

        select top 1 @pwdhash = val
        from cte order by pos desc
        option (maxrecursion 0);

        /* SID Hash */
        select @binvalue = sid from sys.server_principals where name = @login;
        with 
         bintab ([int], [pos], [div], [mod], [vals]) as (
            select cast(substring(@binvalue,1,1) as int)
            , 1
            , cast(floor(cast(substring(@binvalue,1,1) as int)/16) as int)
            , cast((cast(substring(@binvalue,1,1) as int) % 16) as int)
            , cast('0123456789ABCDEF' as char(16)) 
            union all
            select cast(substring(@binvalue,b.[pos] + 1,1) as int)
            , b.[pos] + 1
            , cast(floor(cast(substring(@binvalue,b.[pos] + 1,1) as int)/16) as int)
            , cast((cast(substring(@binvalue,b.[pos] + 1,1) as int) % 16) as int)
            , cast('0123456789ABCDEF' as char(16)) 
            from bintab b
            where b.[pos] < datalength(@binvalue)
         )
        , vals as (
            select [pos]
            , substring([vals],[div]+1,1) + substring([vals],[mod]+1,1) as [val]
            from bintab
         )
        , cte as (
            select pos, cast('0x' + val as varchar(514)) as val
            from vals
            where pos = 1
            union all
            select vals.pos, cast(cte.val + vals.val as varchar(514))
            from cte 
            join vals on cte.pos = vals.pos - 1
         )

        select top 1 @sidhash = val
        from cte order by pos desc
        option (maxrecursion 0);

        insert #tmp values(
        'print ''Creating login ' + quotename(@login) + '''
        if not exists(select 1 from sys.server_principals where name = ''' + @login + ''')
        create login ' + quotename(@login) + ' with password = ' + @pwdhash + ' hashed'
        + ', SID = ' + @sidhash 
        + ', DEFAULT_DATABASE = ' + quotename(@defdb) 
        + ', CHECK_POLICY = ' + @chkpol 
        + ', CHECK_EXPIRATION = ' + @chkexp + '
        else
        print ''Login ' + quotename(@login) + ' exists.''
        GO'
        )

    fetch acursor into @login , @defdb , @chkpol , @chkexp 
    end
    close acursor
    deallocate acursor

    insert #tmp
    select 'print ''Creating login ' + quotename(name) + '''
        if not exists(select 1 from sys.server_principals where name = ''' + name + ''')
        create login ' + quotename(name) + ' from windows with DEFAULT_DATABASE = ' + 
        case @set_master_as_default when 0 then quotename(default_database_name) else quotename('master') end 
        --quotename(default_database_name) 
        
        + '
        else
        print ''Login ' + quotename(name) + ' exists.''
        GO'
    from sys.server_principals 
    where type in ('U', 'G')
    and is_disabled = 0
    and [sid] in (select [sid] from #sids)

    select * from #tmp where [/* Script Enabled Logins */] is not null
    drop table #tmp
    drop table #sids 
end





