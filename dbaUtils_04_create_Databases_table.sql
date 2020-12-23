
USE [dbaUtils] ;
GO

IF
(
		( SELECT @@VERSION ) NOT LIKE '%2016%'
	AND	( SELECT @@VERSION ) NOT LIKE '%2017%'
	AND	( SELECT @@VERSION ) NOT LIKE '%2019%'
)
BEGIN
	RAISERROR (	'Version of SQL Server incompatible with temporal tables', 20, 1 ) WITH LOG ;
END
GO

IF EXISTS
(	
	SELECT 	*
	FROM	sys.tables
	WHERE	[temporal_type] <> 0
		AND	( [object_id] = OBJECT_ID ( 'dbo.Databases' )
		OR	[object_id] = OBJECT_ID ( 'dbo.DatabasesHistory' ) )
)
	ALTER TABLE [dbo].[Databases] SET ( SYSTEM_VERSIONING = OFF ) ;

DROP TABLE IF EXISTS dbo.DatabasesHistory ;
DROP TABLE IF EXISTS dbo.Databases ;

CREATE TABLE dbo.Databases
(
	[id]						SMALLINT		NOT NULL 	IDENTITY (1,1)
	    CONSTRAINT 		[PK_Databases] 				PRIMARY KEY CLUSTERED	( [id] ASC )
   	, [database_id]				SMALLINT		NOT NULL
   	, [database_name]			SYSNAME			NOT NULL
	, [database_owner]			SYSNAME			NULL
	, [compatibility_level]		TINYINT			NOT NULL
	, [database_collation]		SYSNAME			NOT NULL
	, [state]					TINYINT			NOT NULL
	, [recovery_model]			TINYINT			NOT NULL
	, [page_verification]		TINYINT			NOT NULL
	, [is_querystore_on]		BIT				NOT NULL
	, [is_encrypted]			BIT				NOT NULL
   	, [sys_start]				DATETIME2(0) 	GENERATED ALWAYS AS ROW START		HIDDEN		NOT NULL
		CONSTRAINT		[DF_Databases_sys_start]	DEFAULT					( CAST ( sysdatetime() AS DATETIME2(0) ) )
   	, [sys_end]					DATETIME2(0) 	GENERATED ALWAYS AS ROW END			HIDDEN		NOT NULL
		CONSTRAINT		[DF_Databases_sys_end]		DEFAULT					( CAST ( '9999-12-31 23:59:59' AS DATETIME2(0) ) )
	, PERIOD FOR SYSTEM_TIME ( [sys_start], [sys_end] )
)
WITH	( SYSTEM_VERSIONING = ON ( HISTORY_TABLE = dbo.DatabasesHistory ) ) ;
GO
