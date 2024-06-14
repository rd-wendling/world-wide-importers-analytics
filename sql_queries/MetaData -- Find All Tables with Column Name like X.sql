
/********************************************************************************************
Tried to write a script to help searching large servers for any table that has a user 
defined column name. For instance if you want all tables with a CustomerID and want to know
some basic information about the tables and that column in the table you could use this 
script to do that.

Declare loop start, using 5 to skip system databases like master, tempdb, etc.
*********************************************************************************************/
declare @i int = 5


/********************************************************************************************
Set up tables for results and errors

 -- must use a global temp for results given passing statement to exec sp_executesql
*********************************************************************************************/
if object_id('tempdb..##results') is not null
	drop table ##results;

create table ##results (
							 [ColumnName]				varchar(max)
						 ,	 [TableName]				varchar(max)
						 ,	 [DatabaseName]				varchar(max)
						 ,	 [DType]					varchar(max)
						 ,	 [MaxLength]				bigint
						 ,	 [ColumnIndexed?]			int
						 ,	 [IndexType]				varchar(12)
						 ,	 [IndexName]				varchar(max)
					   )

if object_id('tempdb..#errors') is not null
	drop table #errors;

create table #errors (
							 [Database_ErrorRaised] varchar(max)
						 ,	 [ErrorNumber] 			int
						 ,	 [ErrorSeverity] 		int
						 ,	 [ErrorState]  			varchar(max)
						 ,	 [ErrorLine]  			int
						 ,	 [ErrorMessage]			varchar(max)
					  )
		


/********************************************************************************************
Loop over each database in server

Can make changes to WHERE clause (starting line 89) if looking for something specific
*********************************************************************************************/	

while @i <= (select count(d.database_id) from sys.databases d)

begin 
	begin try
		declare @database varchar(max)
		set @database = (select concat('[', d.name, ']') from sys.databases d where d.database_id = @i)

		declare @strSQL nvarchar(max)
		set @strSQL = '

		use '+@database+';

		insert into ##results

		select 

				c.name														as [ColumnName]
			,	t.name														as [TableName]
			,	'+concat(char(39),@database,char(39))+'						as [DatabaseName]
			,	ty.name														as [DType]
			,	ty.max_length												as [MaxLength]
			,	case when ic.column_id is null then 0 else 1 end			as [ColumnIndexed?]
			,	i.type_desc													as [IndexType]
			,	i.name														as [IndexName]

		from sys.columns c

		join sys.tables  t   
			on c.object_id = t.object_id

		join sys.types ty
			on ty.user_type_id = c.user_type_id

		left join sys.index_columns ic
			on ic.object_id = t.object_id
			and ic.column_id = c.column_id

		left join sys.indexes i
			on ic.object_id = i.object_id
			and ic.index_id = i.index_id

		where 1=1
			and c.name like ''%CustomerID%''								-- Uncomment to help find tables/cols with column names containing input string(s)
		--	and ic.column_id is not null							-- Uncomment to only return columns that are indexed
		'
		
		exec sp_executesql @strSQL

		set @i = @i + 1

	end try
	begin catch

		insert into #errors
		select  

				@database			as [Database_ErrorRaised]
			,	error_number()		as [ErrorNumber] 
			,	error_severity()	as [ErrorSeverity]  
			,	error_state()		as [ErrorState]  
			,	error_line()		as [ErrorLine]  
			,	error_message()		as [ErrorMessage]
		
		set @i = @i + 1

	end catch
		
end



/********************************************************************************************
Show results and any errors encountered in the while loop
*********************************************************************************************/	
select * from ##results
select * from #errors


