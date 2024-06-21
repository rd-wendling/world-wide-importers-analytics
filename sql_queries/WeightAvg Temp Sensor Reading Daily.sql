
/******************************************************************************************
Get avg. temp reading of each sensor each date between start_date and end_date

Considerations:
	- Need to get the full sensor reading history from the versioned tables
	- Need to account for differences between reading times when calculation the avg.
*******************************************************************************************/

declare @end_date   date = '2016-03-10'
	,	@start_date date = '2015-12-30'

	

/******************************************************************************************
Get full reading history for all system times, and set us up to be able to calculate the
duration between readings by getting the next reading datetime
*******************************************************************************************/
;with full_history as
(
select 

		ct.ColdRoomSensorNumber
    ,	ct.RecordedWhen
    ,	ct.Temperature
    ,	lead(ct.RecordedWhen) over (partition by ct.ColdRoomSensorNumber order by ct.RecordedWhen)	as NextRecordedWhen

from WideWorldImporters.Warehouse.ColdRoomTemperatures for system_time all ct

where 1=1
	and cast(ct.RecordedWhen as date) between @start_date and @end_date
),

/******************************************************************************************
Get duration between current and next reading calculated for each reading timestamp
to use as our weight when calculating the avgerages
*******************************************************************************************/
durations as 
(
	select

			fh.ColdRoomSensorNumber
		,	cast(fh.RecordedWhen as date)										as RecordDate
		,	fh.Temperature
		,	isnull(datediff(second, fh.RecordedWhen, fh.NextRecordedWhen), 0)	as DurationSeconds

	from full_history fh

	where 1=1
		and fh.NextRecordedWhen is not null
)

/******************************************************************************************
Final Daily Readout showing Weight Avgerage Temp Reading of each sensor
*******************************************************************************************/
select

		d.ColdRoomSensorNumber
    ,	d.RecordDate
    ,	sum(cast(d.DurationSeconds as float) * d.Temperature) / sum(d.DurationSeconds)	as WeightedAvgTemperature

from durations d

group by
		d.ColdRoomSensorNumber
    ,	d.RecordDate

order by
		d.ColdRoomSensorNumber
    ,	d.RecordDate