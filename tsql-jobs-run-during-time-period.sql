/*
Get any job steps that ran at some point during the given period of time.

Note:
Job history is only kept for a certain period of time which depends on your settings.
This script is assuming the job history still exists.
*/

use msdb
go

declare
	@start_date datetime = '2021-05-11 14:37',
	@end_date datetime = '2021-05-11 14:38'

select
	j.[name] as job_name,
	h.step_name,
	h.step_id,
	d1.step_start_date,
	d2.step_end_date,
	*
from
	dbo.sysjobhistory as h
	inner join dbo.sysjobs as j on j.job_id = h.job_id
	cross apply (
		select
			dbo.agent_datetime(h.run_date, h.run_time) AS step_start_date
		) as d1
	cross apply (
		select
			/* run_duration - int - elapsed time in the execution of the job or step in HHMMSS format */ 
			dateadd(hour, (h.run_duration / 10000), dateadd(minute, ((h.run_duration % 10000) / 100), dateadd(second, (h.run_duration % 100), d1.step_start_date))) as step_end_date
		) as d2
where 
	h.step_id <> 0
	and (
		( d1.step_start_date <= @start_date and d2.step_end_date > @start_date )
		or ( d1.step_start_date <= @end_date and d2.step_end_date > @end_date )
		or ( d1.step_start_date <= @start_date and d2.step_end_date >= @end_date )
		or ( d1.step_start_date >= @start_date and d2.step_end_date <= @end_date )
	)
order by
	d1.step_start_date
