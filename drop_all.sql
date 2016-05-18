USE [GD1C2016]
GO

IF (NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'CLAVE_MOTOR')) 
BEGIN
    EXEC ('CREATE SCHEMA CLAVE_MOTOR')
END
GO

CREATE PROCEDURE CLAVE_MOTOR.NO_CHECK_CONSTRAINS
AS 
	DECLARE @sql varchar(max)
	DECLARE tables_in_schema CURSOR FOR 
	SELECT f.name, Object_NAME(f.parent_object_id)
	FROM sys.foreign_keys AS f JOIN
	sys.schemas AS s ON s.schema_id = f.schema_id
	WHERE s.name = 'CLAVE_MOTOR'

	DECLARE @table_name varchar(max)
	DECLARE @fk_name varchar(max)

	OPEN tables_in_schema 

	FETCH tables_in_schema INTO  @fk_name, @table_name

	WHILE (@@FETCH_STATUS = 0) 
	BEGIN 
		SET @sql = 'ALTER TABLE CLAVE_MOTOR.' + @table_name + ' DROP CONSTRAINT ' + @fk_name
		EXEC(@sql)

		FETCH tables_in_schema INTO  @fk_name, @table_name
	END 

	CLOSE tables_in_schema 
	DEALLOCATE tables_in_schema 
GO

-- Creo el SP para limpiar la base
CREATE PROCEDURE [CLAVE_MOTOR].CleanDatabase
AS
	DECLARE @names_sp varchar(max)
	DECLARE @names_func varchar(max)
	DECLARE @names_veiws varchar(max)
	DECLARE @names_tables varchar(max)
	DECLARE @names_types varchar(max)
	DECLARE @names_triggers varchar(max)

	DECLARE @sql varchar(max)

	--Borro los triggers
	SELECT @names_triggers = coalesce(@names_triggers + ', ','') + '[CLAVE_MOTOR].' + t.NAME
	FROM GD1C2016.sys.objects t, GD1C2016.sys.schemas s
	WHERE s.schema_id = t.schema_id AND s.name = 'CLAVE_MOTOR' AND  t.type = 'TR'
	
	SET @sql = 'DROP TRIGGER ' + @names_triggers
	EXEC(@sql)

	--Borro los stored procedures
	SELECT @names_sp = coalesce(@names_sp + ', ','') + '[CLAVE_MOTOR].' + p.NAME
	FROM GD1C2016.sys.procedures p, GD1C2016.sys.schemas s
	WHERE s.schema_id = p.schema_id AND p.NAME != 'CleanDatabase' AND p.NAME != 'NO_CHECK_CONSTRAINS' AND s.name = 'CLAVE_MOTOR'
	
	SET @sql = 'DROP PROCEDURE ' + @names_sp
	EXEC(@sql)

	--Borro las functions
	SELECT @names_func = coalesce(@names_func + ', ','') + '[CLAVE_MOTOR].' + f.NAME
	FROM GD1C2016.sys.objects f, GD1C2016.sys.schemas s
	WHERE s.schema_id = f.schema_id AND s.name = 'CLAVE_MOTOR' AND  f.type IN ('FN', 'IF', 'TF')
	
	SET @sql = 'DROP FUNCTION ' + @names_func
	EXEC(@sql)


	--Borro las vistas
	SELECT @names_veiws = coalesce(@names_veiws + ', ','') + '[CLAVE_MOTOR].' + TABLE_NAME
	FROM GD1C2016.INFORMATION_SCHEMA.VIEWS
	WHERE TABLE_SCHEMA = 'CLAVE_MOTOR'

	SET @sql = 'DROP VIEW ' + @names_veiws
	EXEC(@sql)

	-- Deshabilito la integridad referencial de las tablas a borrar
	EXEC CLAVE_MOTOR.NO_CHECK_CONSTRAINS

	--Borro las tablas excepto la maestra
	SELECT @names_tables = coalesce(@names_tables + ', ','') + '[CLAVE_MOTOR].' + TABLE_NAME
	FROM GD1C2016.INFORMATION_SCHEMA.TABLES
	WHERE TABLE_SCHEMA = 'CLAVE_MOTOR' and TABLE_TYPE = 'BASE TABLE'

	SET @sql = 'DROP TABLE ' + @names_tables
	EXEC(@sql)

	--Borro los User define types
	SELECT @names_types = coalesce( @names_types + ' DROP TYPE ','DROP TYPE ') + '[CLAVE_MOTOR].' + t.NAME
	FROM GD1C2016.sys.types t, GD1C2016.sys.schemas s
	WHERE s.schema_id = t.schema_id AND s.name = 'CLAVE_MOTOR'

	SET @sql = @names_types
	EXEC(@sql)
GO

DECLARE @ok bit
SET @ok = 0
begin TRAN
	EXEC [CLAVE_MOTOR].CleanDatabase
	SET @ok = 1
COMMIT TRAN

DROP PROCEDURE [CLAVE_MOTOR].CleanDatabase
DROP PROCEDURE [CLAVE_MOTOR].NO_CHECK_CONSTRAINS	

IF @ok = 1 
DROP SCHEMA CLAVE_MOTOR
GO