
USE [dbaUtils_v2] ;
GO

-- enter start date -- format YYYYMMDD
DECLARE @start_date AS DATE = '20000101' ;
-- enter number of years
DECLARE @number_of_years AS INT = 50 ;

SET DATEFIRST 1 ;
SET DATEFORMAT dmy ;
SET LANGUAGE US_ENGLISH ;

IF
(
		( SELECT @@VERSION ) NOT LIKE '%2016%'
	AND	( SELECT @@VERSION ) NOT LIKE '%2017%'
	AND	( SELECT @@VERSION ) NOT LIKE '%2019%'
)
BEGIN
	IF 	( OBJECT_ID ( 'dbaUtils.dbo.Dates' ) IS NOT NULL )
		DROP TABLE dbo.Dates ;
END
ELSE
BEGIN
	DROP TABLE IF EXISTS dbo.Dates ;
END

CREATE TABLE [dbo].[Dates]
(
	[date_key]						INT				NOT NULL
		CONSTRAINT [PK_Dates]		PRIMARY KEY NONCLUSTERED	( [date_key] ASC )
	, [date]						DATE			NOT NULL
		CONSTRAINT [UX_Dates_date]	UNIQUE CLUSTERED			( [date] ASC )
	, [day_of_month]				TINYINT			NOT NULL
	, [day_suffix]					CHAR(2)			NOT NULL
	, [weekday_number]				TINYINT			NOT NULL
	, [day_name]					NVARCHAR(10)	NOT NULL
	, [is_weekend]					BIT				NOT NULL
	, [day_of_week_in_month]		TINYINT			NOT NULL
	, [day_of_year]					SMALLINT		NOT NULL
	, [week_of_month]				TINYINT			NOT NULL
	, [week_of_year]				TINYINT			NOT NULL
	, [iso_week_of_year]			TINYINT			NOT NULL
	, [month_number]				TINYINT			NOT NULL
	, [month_name]					NVARCHAR(10)	NOT NULL
	, [quarter_number]				TINYINT			NOT NULL
	, [quarter_name]				NVARCHAR(6)		NULL
	, [year]						INT				NOT NULL
	, [mmyyyy]						CHAR(6)			NOT NULL
	, [month_year]					CHAR(7)			NOT NULL
	, [first_date_of_month]			DATE			NOT NULL
	, [last_date_of_month]			DATE			NOT NULL
	, [first_date_of_quarter]		DATE			NOT NULL
	, [last_date_of_quarter]		DATE			NOT NULL
	, [first_date_of_year]			DATE			NOT NULL
	, [last_date_of_year]			DATE			NOT NULL
	, [first_date_of_next_month]	DATE			NOT NULL
	, [last_date_of_next_month]		DATE			NOT NULL
) ;

DECLARE @cutoff_date AS DATE = DATEADD ( YY, @number_of_years, @start_date ) ;

SET NOCOUNT ON ;

CREATE TABLE #Dates
(
	[date] DATE
		CONSTRAINT [PK_Dates] PRIMARY KEY CLUSTERED
	, [day] AS DATEPART ( DD, [date] )
	, [month] AS DATEPART ( MM, [date] )
	, [FirstOfMonth] AS CONVERT ( DATE, DATEADD ( MM, DATEDIFF ( MM, 0, [date] ), 0 ) )
	, [MonthName] AS DATENAME ( MM, [date] )
	, [week] AS DATEPART ( WK, [date] )
	, [ISOweek] AS DATEPART ( ISO_WEEK, [date] )
	, [DayOfWeek] AS DATEPART ( DW, [date] )
	, [quarter] AS DATEPART ( QQ, [date] )
	, [year] AS DATEPART ( YY, [date] )
	, [FirstOfYear] AS CONVERT ( DATE, DATEADD ( YY,  DATEDIFF ( YY,  0, [date] ), 0 ) )
	, [Style112] AS CONVERT ( CHAR(8), [date], 112 )
	, [Style103] AS CONVERT ( CHAR(10), [date], 103 )
) ;

INSERT 	
	INTO			#Dates ( [date] )
SELECT 			[date]
FROM	
(
	SELECT 			DATEADD ( DD, [rn] - 1, @start_date ) AS [date]
	FROM 	
	(
		SELECT 			TOP ( DATEDIFF ( DD, @start_date, @cutoff_date ) )
						ROW_NUMBER() OVER ( ORDER BY s1.[object_id] ) AS [rn]
		FROM 			sys.all_objects AS s1
			CROSS JOIN 	sys.all_objects AS s2
		ORDER BY 		s1.[object_id] ASC 
	) AS x
) AS y ;

INSERT
	INTO			dbo.Dates
SELECT			CONVERT ( INT, Style112 ) AS [date_key]
				, [date]
				, CONVERT ( TINYINT, [day] ) AS [day_of_month]
				, CONVERT ( CHAR(2), CASE WHEN [day] / 10 = 1 THEN 'th' ELSE CASE RIGHT ( [day], 1 ) WHEN '1' THEN 'st' WHEN '2' THEN 'nd' WHEN '3' THEN 'rd' ELSE 'th' END END ) AS [day_suffix]
				, CONVERT ( TINYINT, [DayOfWeek] ) AS [weekday_number] 
				, CONVERT ( VARCHAR(10), DATENAME ( WEEKDAY, [date] ) ) AS [day_name] 
				, CONVERT ( BIT, CASE WHEN [DayOfWeek] IN (1,7) THEN 1 ELSE 0 END ) AS [is_weekend] 
				, CONVERT ( TINYINT, ROW_NUMBER() OVER ( PARTITION BY FirstOfMonth, [DayOfWeek] ORDER BY [date] ) ) AS [day_of_week_in_month] 
				, CONVERT ( SMALLINT, DATEPART ( DY, [date] ) ) AS [day_of_year]
				, CONVERT ( TINYINT, DENSE_RANK() OVER ( PARTITION BY [year], [month] ORDER BY [week] ) ) AS [week_of_month]
				, CONVERT ( TINYINT, [week] ) AS [week_of_year]
				, CONVERT ( TINYINT, ISOWeek ) AS [iso_week_of_year]
				, CONVERT ( TINYINT, [month] ) AS [month_number]
				, CONVERT ( VARCHAR(10), [MonthName] ) AS [month_name]
				, CONVERT ( TINYINT, [quarter] ) AS [quarter_number] 
				, CONVERT ( VARCHAR(6), CASE [quarter] WHEN 1 THEN 'First' WHEN 2 THEN 'Second' WHEN 3 THEN 'Third' WHEN 4 THEN 'Fourth' END ) AS [quarter_name] 
				, [year]
				, CONVERT ( CHAR(6), LEFT ( Style103, 2 ) + LEFT ( Style112, 4 ) ) AS [mmyyyy] 
				, CONVERT ( CHAR(7), LEFT ( [MonthName], 3 ) + LEFT ( Style112, 4 ) ) AS [month_year]
				, FirstOfMonth AS [first_date_of_month] 
				, MAX ( [date] ) OVER ( PARTITION BY [year], [month] ) AS [last_date_of_month] 
				, MIN ( [date] ) OVER ( PARTITION BY [year], [quarter] ) AS [first_date_of_quarter] 
				, MAX ( [date] ) OVER ( PARTITION BY [year], [quarter] ) AS [last_date_of_quarter] 
				, FirstOfYear AS [first_date_of_year] 
				, MAX ( [date] ) OVER ( PARTITION BY [year] ) AS [last_date_of_year] 
				, DATEADD ( MM, 1, FirstOfMonth ) AS [first_date_of_next_month] 
				, DATEADD ( YY,  1, FirstOfYear ) AS [last_date_of_next_month] 
FROM 			#Dates ;
GO

DROP TABLE #Dates ;
GO

