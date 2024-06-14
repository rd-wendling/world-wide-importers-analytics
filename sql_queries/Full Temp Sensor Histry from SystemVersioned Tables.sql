
/******************************************************************************************
This is just to practice working with system version tables, in this case the script has 
little functional purpose, so just hardcoding some arbitrary dates to work between here.
*******************************************************************************************/
declare @end_date   date = '2016-03-10'
	,	@start_date date = '2015-12-30'
	,	@cold_sensor int = 1
	,	@min_coldRoomTempID int
	,	@max_coldRoomTempID int
	

/******************************************************************************************
Grab Max and Min Cold Room Temp ID based on Date Parameters

	Getting these IDs so we can filter the select we're using later into our unioned
	full history table. Doing it this way because the ColdRoomTemperatureID is an indexed
	column so it will be faster to filter on this than on the ValidFrom/ValidTo columns.
	This dataset is so small it doesn't make much functional difference, but I have run
	into situations in the past where it certainly does. 

	We first try to set these variables using only the current active table since it is
	smaller and quicker. If it works the code will move on, if not it will try again on
	the version history tables. Since between is inclusive we not only filter where a
	date is between ValidFrom and ValidTo we also use min/max functions to get the desired
	single interger ID outputs. In this case we know the start and end dates are not
	in the active table, only because we hardcoded them. Still wrote the script as if
	our date parameters were dynamic and we might not be sure of this 100% of the time.
*******************************************************************************************/

set @min_coldRoomTempID = (
	select min(ct.ColdRoomTemperatureID)
	from WideWorldImporters.Warehouse.ColdRoomTemperatures ct
	where 1=1
		and @start_date between ct.ValidFrom and ct.ValidTo
		and ct.ColdRoomSensorNumber = @cold_sensor
)
set @max_coldRoomTempID = (
	select max(ct.ColdRoomTemperatureID)
	from WideWorldImporters.Warehouse.ColdRoomTemperatures ct
	where 1=1
		and @end_date between ct.ValidFrom and ct.ValidTo
		and ct.ColdRoomSensorNumber = @cold_sensor
)

if @min_coldRoomTempID is null
	set @min_coldRoomTempID = (
		select min(cta.ColdRoomTemperatureID)
		from WideWorldImporters.Warehouse.ColdRoomTemperatures_Archive cta
		where 1=1
			and @start_date between cta.ValidFrom and cta.ValidTo
			and cta.ColdRoomSensorNumber = @cold_sensor
	)

if @max_coldRoomTempID is null
	set @max_coldRoomTempID = (
		select max(cta.ColdRoomTemperatureID)
		from WideWorldImporters.Warehouse.ColdRoomTemperatures_Archive cta
		where 1=1
			and @end_date between cta.ValidFrom and cta.ValidTo
			and cta.ColdRoomSensorNumber = @cold_sensor
	)


/******************************************************************************************
Now get full history for the desired sensor into a temp table to work with

There will not be any duplicate records due to the nature of the system version tables 
(that simply would not be possible) so we can use union all to speed this up.
*******************************************************************************************/
drop table if exists #ColdRoomSensorOne

	select *
	into #ColdRoomSensorOne
	from WideWorldImporters.Warehouse.ColdRoomTemperatures ct
	where 1=1
		and ct.ColdRoomSensorNumber = @cold_sensor

union all

	select *
	from WideWorldImporters.Warehouse.ColdRoomTemperatures_Archive cta
	where 1=1
		and cta.ColdRoomSensorNumber = @cold_sensor


/******************************************************************************************
Now we have a single table with the entire history of this particular cold sensors 
readings to work off of.
*******************************************************************************************/
select *
from #ColdRoomSensorOne c
order by
	c.ValidFrom desc
