USE [GD1C2016]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE SCHEMA CLAVE_MOTOR AUTHORIZATION gd
GO

/*****************************************************************/
/***********************CREACION DE TABLAS************************/
/*****************************************************************/

/*
* Las posibles funcionalidades que conforman cada Rol definen a cuales acciones del sistema
* tienen acceso los Usuarios que tienen asignado ese Rol.
*/
PRINT 'Tabla Funcionalidades'
GO

CREATE TABLE CLAVE_MOTOR.Funcionalidad (
	func_id int IDENTITY(1,1) PRIMARY KEY,
	func_descripcion nvarchar(50) NOT NULL
	)
GO

PRINT 'INSERT Funcionalidades'
GO

INSERT INTO CLAVE_MOTOR.Funcionalidad (func_descripcion) VALUES('ABM de Rol');
INSERT INTO CLAVE_MOTOR.Funcionalidad (func_descripcion) VALUES('ABM de Usuarios');
INSERT INTO CLAVE_MOTOR.Funcionalidad (func_descripcion) VALUES('ABM de Rubro');
INSERT INTO CLAVE_MOTOR.Funcionalidad (func_descripcion) VALUES('ABM de Visibilidad');
INSERT INTO CLAVE_MOTOR.Funcionalidad (func_descripcion) VALUES('Generar Publicaciones');
INSERT INTO CLAVE_MOTOR.Funcionalidad (func_descripcion) VALUES('Comprar-Ofertar');
INSERT INTO CLAVE_MOTOR.Funcionalidad (func_descripcion) VALUES('Historial del cliente');
INSERT INTO CLAVE_MOTOR.Funcionalidad (func_descripcion) VALUES('Calificar al Vendedor');
INSERT INTO CLAVE_MOTOR.Funcionalidad (func_descripcion) VALUES('Consulta de Facturas');
INSERT INTO CLAVE_MOTOR.Funcionalidad (func_descripcion) VALUES('Listado Estadistico');

-------------------------------------------------------------------------------

/*
* Los Roles son conjuntos de funcionalidades que son asignadas a los usuarios del sistema
*/

PRINT 'Tabla Rol'
GO

CREATE TABLE CLAVE_MOTOR.Rol (
	rol_id int IDENTITY(1,1) PRIMARY KEY,
	rol_descripcion nvarchar(50) NOT NULL,
	rol_habilitado bit DEFAULT 1 NOT NULL
	)
GO

PRINT 'INSERT Rol'
GO

INSERT INTO CLAVE_MOTOR.Rol(rol_descripcion) values ('Administrador');
INSERT INTO CLAVE_MOTOR.Rol(rol_descripcion) values ('Cliente');
INSERT INTO CLAVE_MOTOR.Rol(rol_descripcion) values ('Empresa');
GO

CREATE INDEX RolesPorNombre
    ON CLAVE_MOTOR.Rol (rol_descripcion);
GO

------------------------------------------------------------------------

/*
* La tabla FuncionalidadRol es usada para determinar que funcionalidades estan
* asignadas a los distintos roles
*/
PRINT 'Tabla FuncionalidadRol'
GO

CREATE TABLE CLAVE_MOTOR.FuncionalidadRol (
	furo_idFuncionalidad  int REFERENCES CLAVE_MOTOR.Funcionalidad NOT NULL,
	furo_idRol  int REFERENCES CLAVE_MOTOR.Rol NOT NULL,
	PRIMARY KEY(furo_idFuncionalidad, furo_idRol)
	)
GO

PRINT 'INSERT FuncionalidadRol'
GO

/*
* El rol Administrador lleva todas las funciones del sistema
*/
INSERT INTO CLAVE_MOTOR.FuncionalidadRol (furo_idFuncionalidad,furo_idRol)
	(SELECT Funcionalidad.func_id, Rol.rol_id
	FROM CLAVE_MOTOR.Funcionalidad, CLAVE_MOTOR.Rol
	WHERE Rol.rol_descripcion = 'Administrador');
/*
* Los clientes solo podran comprar o ofertar publicaciones
*/
INSERT INTO CLAVE_MOTOR.FuncionalidadRol (furo_idFuncionalidad,furo_idRol)
	(SELECT func_id, rol_id
	FROM CLAVE_MOTOR.Funcionalidad, CLAVE_MOTOR.Rol
	WHERE rol_descripcion = 'Cliente'
	AND func_descripcion = 'Comprar-Ofertar');
/*
* Las empresas solo podran hacer publicaciones
*/
INSERT INTO CLAVE_MOTOR.FuncionalidadRol (furo_idFuncionalidad,furo_idRol)
	(SELECT func_id, rol_id
	FROM CLAVE_MOTOR.Funcionalidad, CLAVE_MOTOR.Rol
	WHERE rol_descripcion = 'Empresa'
	AND func_descripcion = 'Generar Publicaciones');
GO

----------------------------------------------------------------------------

PRINT 'Tabla Usuario'
GO

CREATE TABLE CLAVE_MOTOR.Usuario (
	usua_id int IDENTITY(1,1) PRIMARY KEY,
	usua_username nvarchar(30) NOT NULL,
	usua_password nvarchar(64) NOT NULL,
	usua_fechaCreacion datetime DEFAULT GETDATE() NOT NULL,
	usua_habilitado bit NOT NULL DEFAULT 1,
	usua_idRol int REFERENCES CLAVE_MOTOR.Rol NOT NULL,
	usua_intentosLogin int NOT NULL DEFAULT 0
	)
GO

PRINT 'INSERT Usuario'
GO

/*
* Funcion de Hashing de password.
*
* TODO: TAL VEZ HAYA QUE SACARLE LOS DOS PRIMEROS CARACTERES, QUEDA CON '0x'
*/
CREATE FUNCTION CLAVE_MOTOR.FX_HASH_PASSWORD(@password varchar(50))
RETURNS varchar(34)
AS BEGIN
RETURN CONVERT(varchar(34),HASHBYTES('SHA2_256',@password),1)
END
GO

/*
* Se inserta el usuario admin
*/
INSERT INTO CLAVE_MOTOR.Usuario (usua_username, usua_password, usua_idRol)
	VALUES ('admin', 
			CLAVE_MOTOR.FX_HASH_PASSWORD('admin'),
			(SELECT Rol.rol_id
				FROM CLAVE_MOTOR.Rol
				WHERE Rol.rol_descripcion = 'Administrador')
			);
GO

/*
* Se insertan los usuarios Empresa con su respectivo rol
* La password por default de los usarios existentes en 
* el sistema pre-migracion es 'password'
*/

/*
* Funcion para componer un username a partir de la razon social de una empresa pre-migracion.
* PARA LAS POST-MIGRACION NO DEBE USARSE YA QUE LA RAZON SOCIAL PUEDE NO POSSER EL MISMO FORMATO
*/

CREATE FUNCTION CLAVE_MOTOR.FX_USERNAME_EMPRESA(@Razonsocial varchar(50))
RETURNS varchar(50)
AS BEGIN
RETURN REPLACE(@Razonsocial,'º:','')
END
GO

INSERT INTO CLAVE_MOTOR.Usuario(usua_username,usua_password,usua_idRol)
	(SELECT DISTINCT CLAVE_MOTOR.FX_USERNAME_EMPRESA(Maestra.Publ_Empresa_Razon_Social),
	CLAVE_MOTOR.FX_HASH_PASSWORD('password'), 
	(SELECT CLAVE_MOTOR.Rol.rol_id 
		FROM CLAVE_MOTOR.Rol
		WHERE rol.rol_descripcion = 'Empresa')
	FROM gd_esquema.Maestra
	WHERE Maestra.Publ_Empresa_Razon_Social IS NOT NULL
	);
GO

/*
* Funcion para componer un username a partir del nombre y apellido de un cliente.
* 
* TODO: PODRIA USARSE ESTA FUNCION PARA EL USERNAME PARA TODOS LOS CLIENTES, NO SOLO LOS DE LA MIGRACION
*/
CREATE FUNCTION CLAVE_MOTOR.FX_USERNAME_CLIENTE(@nombre varchar(50),@apellido varchar(50))
RETURNS varchar(100)
AS BEGIN
RETURN REPLACE(LOWER(@nombre + @apellido), ' ','')
END
GO

/*
* Se insertan los usuarios de clientes con su respectivo Rol.
*/
INSERT INTO CLAVE_MOTOR.Usuario(usua_username,usua_password,usua_idRol)
	(SELECT DISTINCT CLAVE_MOTOR.FX_USERNAME_CLIENTE(Maestra.Cli_Nombre,Maestra.Cli_Apeliido),
	CLAVE_MOTOR.FX_HASH_PASSWORD('password'), 
	(SELECT CLAVE_MOTOR.Rol.rol_id 
		FROM CLAVE_MOTOR.Rol
		WHERE rol.rol_descripcion = 'Cliente')
	FROM gd_esquema.Maestra
	WHERE Maestra.Cli_Dni IS NOT NULL
	UNION
	SELECT DISTINCT CLAVE_MOTOR.FX_USERNAME_CLIENTE(Maestra.Publ_Cli_Nombre,Maestra.Publ_Cli_Apeliido),
	CLAVE_MOTOR.FX_HASH_PASSWORD('password'), 
	(SELECT CLAVE_MOTOR.Rol.rol_id 
		FROM CLAVE_MOTOR.Rol
		WHERE rol.rol_descripcion = 'Cliente')
	FROM gd_esquema.Maestra
	WHERE Maestra.Publ_Cli_Dni IS NOT NULL
	);
GO

/*
* Varios accesos a usuarios seran por su username.
*/
CREATE INDEX UsuariosPorNombre
    ON CLAVE_MOTOR.Usuario (usua_username);
GO

----------------------------------------------------------------------------

/*
* Creacion de domicilios.
*/
PRINT 'Tabla Domicilios'
GO
CREATE TABLE CLAVE_MOTOR.Domicilio (
	domi_id int IDENTITY(1,1) PRIMARY KEY,
	domi_calle nvarchar(100),
	domi_nro int,
	domi_piso int,
	domi_depto nvarchar(5),
	domi_codPostal nvarchar(20),
	domi_ciudad nvarchar(50),
	domi_localidad nvarchar(50),
	)
GO

PRINT 'INSERT Domicilios'
GO
INSERT INTO CLAVE_MOTOR.Domicilio(domi_calle,domi_nro,domi_piso,domi_depto,domi_codPostal)
(SELECT DISTINCT Maestra.Cli_Dom_Calle,Maestra.Cli_Nro_Calle,Maestra.Cli_Cod_Postal,Maestra.Cli_Depto,Maestra.Cli_Piso
FROM gd_esquema.Maestra
WHERE Maestra.Cli_Dni IS NOT NULL
UNION
SELECT DISTINCT Maestra.Publ_Cli_Dom_Calle, Maestra.Publ_Cli_Nro_Calle,Maestra.Publ_Cli_Cod_Postal,Maestra.Publ_Cli_Depto,Maestra.Publ_Cli_Piso
FROM gd_esquema.Maestra
WHERE Maestra.Publ_Cli_Dni IS NOT NULL
UNION 
SELECT DISTINCT Maestra.Publ_Empresa_Dom_Calle, Maestra.Publ_Empresa_Nro_Calle,Maestra.Publ_Empresa_Cod_Postal,Maestra.Publ_Empresa_Depto,Maestra.Publ_Empresa_Piso
FROM gd_esquema.Maestra
WHERE Maestra.Publ_Empresa_Cuit IS NOT NULL);

CREATE INDEX DomiciliosPorCalleYNro
    ON CLAVE_MOTOR.Domicilio (domi_calle,domi_nro);
GO

----------------------------------------------------------------------------
/*
* Los clientes son los compradores en el sistema. Se les asigna su usuario previamente creado.
*/
PRINT 'Tabla Clientes'
GO

CREATE TABLE CLAVE_MOTOR.Cliente (
	clie_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL,
	clie_tipoDocumento nvarchar(30) NOT NULL,
	clie_documento nvarchar(50) NOT NULL,
	PRIMARY KEY(clie_tipoDocumento, clie_documento),
	clie_nombre nvarchar(50),
	clie_apellido nvarchar(50),
	clie_fechaNacimiento datetime,
	clie_mail nvarchar(100),
	clie_telefono nvarchar(50),
	clie_idDomicilio int REFERENCES CLAVE_MOTOR.Domicilio,
	)
GO

PRINT 'INSERT Cliente'
GO

/*
* TODO: HACER LA CONVERSION CORRECTA DE LA FECHA. SACAR LOS GETDATE.
*/
INSERT INTO CLAVE_MOTOR.Cliente (clie_idUsuario,clie_tipoDocumento,clie_documento,clie_nombre,clie_apellido,clie_fechaNacimiento,
		clie_mail,clie_idDomicilio)
		(SELECT DISTINCT (SELECT Usuario.usua_id
				FROM CLAVE_MOTOR.Usuario
				WHERE Usuario.usua_username = CLAVE_MOTOR.FX_USERNAME_CLIENTE(M.Cli_Nombre,M.Cli_Apeliido)),
				'DNI',
				M.Cli_Dni,
				M.Cli_Nombre,
				M.Cli_Apeliido,
				GETDATE(),
				M.Cli_Mail,
				(SELECT Domicilio.domi_id FROM CLAVE_MOTOR.Domicilio 
				WHERE Domicilio.domi_calle = M.Cli_Dom_Calle AND Domicilio.domi_nro = M.Cli_Nro_Calle)
		FROM gd_esquema.Maestra M
		WHERE M.Cli_Dni IS NOT NULL
		UNION
		SELECT DISTINCT (SELECT Usuario.usua_id
				FROM CLAVE_MOTOR.Usuario
				WHERE Usuario.usua_username = CLAVE_MOTOR.FX_USERNAME_CLIENTE(M.Publ_Cli_Nombre,M.Publ_Cli_Apeliido)),
				'DNI',
				M.Publ_Cli_Dni,
				M.Publ_Cli_Nombre,
				M.Publ_Cli_Apeliido,
				GETDATE(),
				M.Publ_Cli_Mail,
				(SELECT D.domi_id FROM CLAVE_MOTOR.Domicilio D
				WHERE D.domi_calle = M.Publ_Cli_Dom_Calle AND D.domi_nro = M.Publ_Cli_Nro_Calle)
		FROM gd_esquema.Maestra M
		WHERE M.Publ_Cli_Dni IS NOT NULL);

---------------------------------------------------------------------------

PRINT 'Tabla Empresa'
GO

CREATE TABLE CLAVE_MOTOR.Empresa (
	empr_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL,
	empr_tipoDocumento nvarchar(30) NOT NULL,
	empr_documento nvarchar(50) NOT NULL,
	PRIMARY KEY(empr_tipoDocumento, empr_documento),
	empr_razonSocial nvarchar(50),
	empr_nombreContacto nvarchar(50),
	empr_rubroPrincipal nvarchar(50),
	empr_mail nvarchar(100),
	empr_telefono nvarchar(50),
	empr_idDomicilio int REFERENCES CLAVE_MOTOR.Domicilio,
	)
GO

PRINT 'INSERT Empresa'
GO
/*
* Se insertan las empresas con sus usuarios y domicilios correspondientes.
* Ademas se elige que el rubro de la empresa, sea el rubro sobre el cual mas
* publicaciones hizo
*/
INSERT INTO CLAVE_MOTOR.Empresa (empr_idUsuario,empr_tipoDocumento,empr_documento,empr_razonSocial,empr_nombreContacto,
		empr_rubroPrincipal,empr_mail,empr_idDomicilio)
		(SELECT DISTINCT (SELECT Usuario.usua_id
				FROM CLAVE_MOTOR.Usuario
				WHERE Usuario.usua_username = CLAVE_MOTOR.FX_USERNAME_EMPRESA(M.Publ_Empresa_Razon_Social)),
				'CUIT',
				M.Publ_Empresa_Cuit,
				M.Publ_Empresa_Razon_Social,
				null,
				(SELECT TOP 1 M2.Publicacion_Rubro_Descripcion
					FROM gd_esquema.Maestra M2
					WHERE M2.Publ_Empresa_Cuit = M.Publ_Empresa_Cuit
					GROUP BY M2.Publicacion_Rubro_Descripcion
					ORDER BY COUNT(*) DESC),
				M.Publ_Empresa_Mail,
				(SELECT D.domi_id FROM CLAVE_MOTOR.Domicilio D
				WHERE D.domi_calle = M.Publ_Empresa_Dom_Calle AND D.domi_nro = M.Publ_Empresa_Nro_Calle)
		FROM gd_esquema.Maestra M
		WHERE M.Publ_Empresa_Cuit IS NOT NULL);


---------------------------------------------------------------------------

PRINT 'VISIBILIDAD'
GO
/*
* Se crean las visibilidades existentes en el sistema.
* Para poder mantener los codigos actuales de cada una,
* se deshabilita el checkeo de identity manual.
* Luego se vuelve a habilitar que solo permita autogenerado.
*/
CREATE TABLE CLAVE_MOTOR.Visibilidad (
	visi_id int IDENTITY(1,1) PRIMARY KEY,
	visi_descripcion nvarchar(50) NOT NULL,
	visi_precioPublicar numeric(18, 2),
	visi_precioVenta numeric(18, 2),
	visi_precioEnvio numeric(18, 2),
	)
GO

SET IDENTITY_INSERT CLAVE_MOTOR.Visibilidad ON;
GO

/*
* TODO: VERIFICAR LA CORRESPONDENCIA DE LOS VALORES DE LOS CAMPOS SEGUN LAS REGLAS DE NEGOCIO.
* NO SE SI ALGUNO DE ESOS ES EL PRECIO DE ENVIO O SI TODAS LAS PUBLICACIONES EXISTENTES NO TUVIERON CARGO DE ENVIO.
* EN LA CHARLA, LOS AYUDANTES MENCIONARON QUE HABIA QUE HACER UNA REGLA DE 3 SIMPLE EN ALGUN LADO.
*/
INSERT INTO CLAVE_MOTOR.Visibilidad (visi_id,visi_descripcion,visi_precioPublicar,visi_precioVenta,visi_precioEnvio)
	(SELECT DISTINCT M.Publicacion_Visibilidad_Cod, M.Publicacion_Visibilidad_Desc,M.Publicacion_Visibilidad_Porcentaje,M.Publicacion_Visibilidad_Precio,0
	FROM gd_esquema.Maestra M);

SET IDENTITY_INSERT CLAVE_MOTOR.Visibilidad OFF;

---------------------------------------------------------------------------

PRINT 'Tabla Rubro'
GO
CREATE TABLE CLAVE_MOTOR.Rubro (
	rubr_id int IDENTITY(1,1) PRIMARY KEY,
	rubr_descripcionCorta nvarchar(30) NOT NULL,
	rubr_descripcionLarga nvarchar(100) NOT NULL,
	)
GO

PRINT 'INSERT Rubro'
GO
INSERT INTO CLAVE_MOTOR.Rubro (rubr_descripcionCorta, rubr_descripcionLarga)
(SELECT DISTINCT Publicacion_Rubro_Descripcion, ('Sin Descripcion')
FROM gd_esquema.Maestra);


---------------------------------------------------------------------------
/*
* Las publicaciones pueden ser de tipo Compra Directa o Subasta.
* Para el codigo de las publicaciones existentes en el sistema se usara el mismo
* que tenian para mantener consistencia. Los de las nuevas seran autogenerados.
* Tipo: Compra Inmediata = 1
		Subasta = 2
* Estado: Publicada = 1
		Otro = 0 no hay publicaciones que no esten publicadas en el sistema actual
* TODO: EL PRECIO PARECE SER EL FINAL, CALCULAR EL PRECIO ANTES DE APLICARSE EL 
* PORCENTAJE DE POR VISIBILIDAD.
*/

PRINT 'Tabla Publicacion'
GO

CREATE TABLE CLAVE_MOTOR.Publicacion (
	publ_id int IDENTITY(1,1) PRIMARY KEY,
	publ_descripcion nvarchar(50) NOT NULL,
	publ_stock int NOT NULL,
	publ_fechaInicio datetime NOT NULL,
	publ_fechaVencimiento datetime NOT NULL,
	publ_precio numeric(18, 2) NOT NULL,
	publ_tipo int NOT NULL,
	publ_estado int,
	publ_idVisibilidad int REFERENCES CLAVE_MOTOR.Visibilidad NOT NULL,
	publ_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL,
	publ_idRubro int REFERENCES CLAVE_MOTOR.Rubro NOT NULL,
	publ_aceptaPreguntas bit DEFAULT 1
	)
GO

PRINT 'INSERT Publicacion'

SET IDENTITY_INSERT CLAVE_MOTOR.Publicacion ON;

INSERT INTO CLAVE_MOTOR.Publicacion (publ_id,publ_descripcion,publ_stock,publ_fechaInicio,publ_fechaVencimiento,
		publ_precio,publ_tipo,publ_estado,publ_idVisibilidad,publ_idUsuario,publ_idRubro)
	(SELECT DISTINCT M.Publicacion_Cod,M.Publicacion_Descripcion,M.Publicacion_Stock,M.Publicacion_Fecha,M.Publicacion_Fecha_Venc,
		M.Publicacion_Precio,
		(SELECT CASE WHEN M.Publicacion_Tipo = 'Compra Inmediata' THEN 1
					ELSE 2 END),
		(SELECT CASE WHEN M.Publicacion_Estado = 'Publicada' THEN 1
					ELSE 0 END),
		M.Publicacion_Visibilidad_Cod,
		(SELECT U.usua_id
		FROM CLAVE_MOTOR.Usuario U
		WHERE U.usua_username = CLAVE_MOTOR.FX_USERNAME_EMPRESA(M.Publ_Empresa_Razon_Social)),
		(SELECT R.rubr_id
		FROM CLAVE_MOTOR.Rubro R
		WHERE R.rubr_descripcionCorta = M.Publicacion_Rubro_Descripcion)
	FROM gd_esquema.Maestra M
	WHERE M.Publ_Empresa_Cuit IS NOT NULL)

---------------------------------------------------------------------------
CREATE TABLE CLAVE_MOTOR.Compra (
	comp_id int IDENTITY(1,1) PRIMARY KEY,
	comp_fecha datetime NOT NULL,
	comp_cantidad int NOT NULL,
	comp_idPublicacion int REFERENCES CLAVE_MOTOR.Publicacion NOT NULL,
	comp_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL
	)
GO


---------------------------------------------------------------------------
CREATE TABLE CLAVE_MOTOR.Oferta (
	ofer_id int IDENTITY(1,1) PRIMARY KEY,
	ofer_fecha datetime NOT NULL,
	ofer_monto numeric(18, 2) NOT NULL,
	ofer_idPublicacion int REFERENCES CLAVE_MOTOR.Publicacion NOT NULL,
	ofer_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL
	)
GO

---------------------------------------------------------------------------
CREATE TABLE CLAVE_MOTOR.Calificacion (
	cali_id int IDENTITY(1,1) PRIMARY KEY,
	cali_cantEstrellas int NOT NULL,
	cali_descripcion nvarchar(250),
	cali_idCompra int REFERENCES CLAVE_MOTOR.Compra NOT NULL,
	cali_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL
	)
GO

---------------------------------------------------------------------------
CREATE TABLE CLAVE_MOTOR.MedioPago (
	medi_id int IDENTITY(1,1) PRIMARY KEY,
	medi_descripcion nvarchar(50) NOT NULL,
	)
GO

---------------------------------------------------------------------------

CREATE TABLE CLAVE_MOTOR.Factura (
	fact_id int IDENTITY(1,1) PRIMARY KEY,
	fact_fecha datetime NOT NULL,
	fact_total numeric(18, 2) NOT NULL,
	fact_idMedioPago int REFERENCES CLAVE_MOTOR.MedioPago NOT NULL,
	fact_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL
	)
GO

---------------------------------------------------------------------------

CREATE TABLE CLAVE_MOTOR.ItemFactura (
	item_id int IDENTITY(1,1) PRIMARY KEY,
	item_monto numeric(18, 2) NOT NULL,
	item_cantidad int NOT NULL,
	item_descripcion nvarchar(50) NOT NULL,
	item_idFactura int REFERENCES CLAVE_MOTOR.Factura NOT NULL
	)
GO

---------------------------------------------------------------------------

ALTER TABLE CLAVE_MOTOR.FuncionalidadRol ADD CONSTRAINT fk_Func_IDFunc
FOREIGN KEY (furo_idFuncionalidad) REFERENCES CLAVE_MOTOR.Funcionalidad(func_id)

ALTER TABLE CLAVE_MOTOR.FuncionalidadRol ADD CONSTRAINT fk_Func_IDRol
FOREIGN KEY (furo_idRol) REFERENCES CLAVE_MOTOR.Rol(rol_id)

ALTER TABLE CLAVE_MOTOR.ItemFactura ADD CONSTRAINT fk_Func_ItemFactura
FOREIGN KEY (item_idFactura) REFERENCES CLAVE_MOTOR.Factura(fact_id)

ALTER TABLE CLAVE_MOTOR.Factura ADD CONSTRAINT fk_Fact_IDMediPago
FOREIGN KEY (fact_idMedioPago) REFERENCES CLAVE_MOTOR.MedioPago(medi_id)

ALTER TABLE CLAVE_MOTOR.Factura ADD CONSTRAINT fk_Fact_IDUsuario
FOREIGN KEY (fact_idUsuario) REFERENCES CLAVE_MOTOR.Usuario(usua_id)

ALTER TABLE CLAVE_MOTOR.Publicacion ADD CONSTRAINT fk_Publ_idVisibilidad
FOREIGN KEY (publ_idVisibilidad) REFERENCES CLAVE_MOTOR.Visibilidad(visi_id)

ALTER TABLE CLAVE_MOTOR.Publicacion ADD CONSTRAINT fk_Publ_idUsuario
FOREIGN KEY (publ_idUsuario) REFERENCES CLAVE_MOTOR.Usuario(usua_id)

ALTER TABLE CLAVE_MOTOR.Publicacion ADD CONSTRAINT fk_Publ_IDRubro
FOREIGN KEY (publ_idRubro) REFERENCES CLAVE_MOTOR.Rubro(rubr_id)

ALTER TABLE CLAVE_MOTOR.Usuario ADD CONSTRAINT fk_Usu_IDRol
FOREIGN KEY (usua_idRol) REFERENCES CLAVE_MOTOR.Rol(rol_id)

ALTER TABLE CLAVE_MOTOR.Empresa ADD CONSTRAINT fk_Emp_IDUsuario
FOREIGN KEY (empr_idUsuario) REFERENCES CLAVE_MOTOR.Usuario(usua_id)

ALTER TABLE CLAVE_MOTOR.Empresa ADD CONSTRAINT fk_Emp_IDDomicilio
FOREIGN KEY (empr_idDomicilio) REFERENCES CLAVE_MOTOR.Domicilio(domi_id)

ALTER TABLE CLAVE_MOTOR.Cliente ADD CONSTRAINT fk_Clie_IDUsuario
FOREIGN KEY (clie_idUsuario) REFERENCES CLAVE_MOTOR.Usuario(usua_id)

ALTER TABLE CLAVE_MOTOR.Cliente ADD CONSTRAINT fk_Clie_IDDomicilio
FOREIGN KEY (clie_idDomicilio) REFERENCES CLAVE_MOTOR.Domicilio(domi_id)

ALTER TABLE CLAVE_MOTOR.Oferta ADD CONSTRAINT fk_Ofer_IDPublicacion
FOREIGN KEY (ofer_idPublicacion) REFERENCES CLAVE_MOTOR.Publicacion(publ_id)

ALTER TABLE CLAVE_MOTOR.Oferta ADD CONSTRAINT fk_Oferta_IDUsuario
FOREIGN KEY (ofer_idUsuario) REFERENCES CLAVE_MOTOR.Usuario(usua_id)

ALTER TABLE CLAVE_MOTOR.Compra ADD CONSTRAINT fk_Comp_IDUsuario
FOREIGN KEY (comp_idUsuario) REFERENCES CLAVE_MOTOR.Usuario(usua_id)

ALTER TABLE CLAVE_MOTOR.Compra ADD CONSTRAINT fk_Comp_IDPublicacion
FOREIGN KEY (comp_idPublicacion) REFERENCES CLAVE_MOTOR.Publicacion(publ_id)

ALTER TABLE CLAVE_MOTOR.Calificacion ADD CONSTRAINT fk_Cali_IDUsuario
FOREIGN KEY (cali_idUsuario) REFERENCES CLAVE_MOTOR.Usuario(usua_id)

ALTER TABLE CLAVE_MOTOR.Calificacion ADD CONSTRAINT fk_Cali_IDCompra
FOREIGN KEY (cali_idCompra) REFERENCES CLAVE_MOTOR.Compra(comp_id)


/*****************************************************************/


/*****************************************************************/
/************************** MIGRACION ****************************/
/*****************************************************************/

/*
INSERT INTO CLAVE_MOTOR.Empresa (
	empr_idUsuario
	empr_tipoDocumento,
	empr_documento,
	empr_razonSocial,
	empr_nombreContacto,
	empr_rubroPrincipal,
	empr_mail,
	empr_telefono,
	empr_idDomicilio)
	VALUES (
	SELECT DISTINCT 

INSERT INTO CLAVE_MOTOR.Publicacion (
	publ_id, 
	publ_descripcion, 
	publ_stock,
	publ_fechaInicio,
	publ_fechaVencimiento,
	publ_precio,
	publ_tipo,
	publ_estado,
	publ_idVisibilidad,
	publ_idUsuario,
	publ_idRubro)

	SELECT [Publicacion_Cod]
      ,[Publicacion_Descripcion]
      ,[Publicacion_Stock]
      ,[Publicacion_Fecha]
      ,[Publicacion_Fecha_Venc]
      ,[Publicacion_Precio]
      ,[Publicacion_Tipo]
	  ,[Publicacion_Estado]
      ,[Publicacion_Visibilidad_Cod]
	 TODO REEMPLAZAR POR idUsuario aca  ,[Publ_Empresa_Cuit]
      
      ,[Publicacion_Rubro_Descripcion]  TODO ESTO DEBERIA SER EL ID PREVIAMENTE GENERADO
	FROM gd_esquema.Maestra
	
	
	
INSERT INTO CLAVE_MOTOR.Cliente (
	clie_idUsuario,
	clie_tipoDocumento,
	clie_documento,
	clie_nombre,
	clie_apellido,
	clie_fechaNacimiento,
	clie_mail,
	clie_telefono,
	clie_idDomicilio )
	
	SELECT [id_Usuario],
		   [
	
	FROM  gd_esquema.Maestra, 
	/*TODO*/
	
GO

*/

