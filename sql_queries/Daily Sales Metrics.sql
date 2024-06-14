/*******************************************************************************

Author: Ryan W.

Date: 2024-06-13

Goal: Get data on sales made, items sold, revenue and profit per sales-person,
	  product, invoice date.
********************************************************************************/

declare @end_date   date = getdate()
declare @year_override int = 2015
declare @start_date date 
	
set @end_date	= datefromparts(@year_override, month(@end_date), day(@end_date))
set @start_date = datefromparts(@year_override-4, 1, 1)


select 

		i.InvoiceDate
	,	dateadd(d, 1 - datepart(weekday, i.InvoiceDate), i.InvoiceDate)								as InvoiceWeekStart
	,	dateadd(d, 1, eomonth(i.InvoiceDate, -1))													as InvoiceMonthStart
	,	o.SalespersonPersonID
	,	p.FullName																					as SalesPerson
	,	il.StockItemID
	,	i.InvoiceID																	
	,	sum(il.Quantity)																			as QuantitySold
	,	sum(il.ExtendedPrice)																		as Revenue
	,	sum(il.LineProfit)																			as Profit

from WideWorldImporters.Sales.InvoiceLines il

join WideWorldImporters.Sales.Invoices i 
	on il.InvoiceID = i.InvoiceID

join WideWorldImporters.Sales.Orders o
	on o.OrderID = i.OrderID

join WideWorldImporters.Application.People p
	on p.PersonID = o.SalespersonPersonID

where 1=1
	and i.InvoiceDate between @start_date and @end_date

group by
		i.InvoiceDate
	,	o.SalespersonPersonID
	,	p.FullName
	,	il.StockItemID
	,	i.InvoiceID	