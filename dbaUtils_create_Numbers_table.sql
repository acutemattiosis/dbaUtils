
USE [dbaUtils] ;
GO

IF
(
		( SELECT @@VERSION ) NOT LIKE '%2016%'
	AND	( SELECT @@VERSION ) NOT LIKE '%2017%'
	AND	( SELECT @@VERSION ) NOT LIKE '%2019%'
)
BEGIN
	IF 	( OBJECT_ID ( 'dbaUtils.dbo.Numbers' ) IS NOT NULL )
		DROP TABLE dbo.Numbers ;
END
ELSE
BEGIN
	DROP TABLE IF EXISTS dbo.Numbers ;
END
GO

CREATE TABLE dbo.Numbers
(
	[number] 		SMALLINT		NOT NULL
		CONSTRAINT 	[PK_Numbers] 	PRIMARY KEY CLUSTERED
) ;
GO

DECLARE @max_number AS SMALLINT = 10000 ;

WITH cte_Numbers AS
(
	SELECT		1 AS [n]
	UNION ALL
	SELECT 		[n] + 1
	FROM		cte_Numbers
	WHERE		[n] < @max_number
)
INSERT
	INTO	dbo.Numbers
			( [number] )
SELECT		[n]
FROM		cte_Numbers
OPTION 		( MAXRECURSION 0 ) ;
GO
