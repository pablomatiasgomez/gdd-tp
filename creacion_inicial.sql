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

CREATE TABLE CLAVE_MOTOR.Rol (
	rol_id int IDENTITY(1,1) PRIMARY KEY,
	rol_descripcion nvarchar(50) NOT NULL,
	rol_habilitado bit DEFAULT 1 NOT NULL
	)
GO

INSERT INTO CLAVE_MOTOR.Rol(rol_descripcion) values ('Administrdor')
INSERT INTO CLAVE_MOTOR.Rol(rol_descripcion) values ('Cliente')
INSERT INTO CLAVE_MOTOR.Rol(rol_descripcion) values ('Empresa')
GO

CREATE TABLE CLAVE_MOTOR.Funcionalidad (
	rol_id int IDENTITY(1,1) PRIMARY KEY,
	rol_descripcion nvarchar(50) NOT NULL
	)
GO



CREATE TABLE CLAVE_MOTOR.FuncionalidadRol (
	furo_idFuncionalidad  int REFERENCES CLAVE_MOTOR.Funcionalidad NOT NULL,
	furo_idRol  int REFERENCES CLAVE_MOTOR.Rol NOT NULL,
	PRIMARY KEY(furo_idFuncionalidad, furo_idRol)
	)
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


INSERT INTO CLAVE_MOTOR.Usuario (usua_username, usua_password, usua_idRol)
	values ('admin', HASHBYTES('SHA2_256', 'admin'), 1)
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

CREATE TABLE CLAVE_MOTOR.Visibilidad (
	visi_id int IDENTITY(1,1) PRIMARY KEY,
	visi_descripcion nvarchar(50) NOT NULL,
	visi_precioPublicar numeric(18, 2),
	visi_precioVenta numeric(18, 2),
	visi_precioEnvio numeric(18, 2),
	)
GO

CREATE TABLE CLAVE_MOTOR.Rubro (
	rubr_id int IDENTITY(1,1) PRIMARY KEY,
	rubr_descripcionCorta nvarchar(30) NOT NULL,
	rubr_descripcionLarga nvarchar(100) NOT NULL,
	)
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

CREATE TABLE CLAVE_MOTOR.Compra (
	comp_id int IDENTITY(1,1) PRIMARY KEY,
	comp_fecha datetime NOT NULL,
	comp_cantidad int NOT NULL,
	comp_idPublicacion int REFERENCES CLAVE_MOTOR.Publicacion NOT NULL,
	comp_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL
	)
GO

CREATE TABLE CLAVE_MOTOR.Oferta (
	ofer_id int IDENTITY(1,1) PRIMARY KEY,
	ofer_fecha datetime NOT NULL,
	ofer_monto numeric(18, 2) NOT NULL,
	ofer_idPublicacion int REFERENCES CLAVE_MOTOR.Publicacion NOT NULL,
	ofer_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL
	)
GO

CREATE TABLE CLAVE_MOTOR.Calificacion (
	cali_id int IDENTITY(1,1) PRIMARY KEY,
	cali_cantEstrellas int NOT NULL,
	cali_descripcion nvarchar(250),
	cali_idCompra int REFERENCES CLAVE_MOTOR.Compra NOT NULL,
	cali_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL
	)
GO

CREATE TABLE CLAVE_MOTOR.MedioPago (
	medi_id int IDENTITY(1,1) PRIMARY KEY,
	medi_descripcion nvarchar(50) NOT NULL,
	)
GO

CREATE TABLE CLAVE_MOTOR.Factura (
	fact_id int IDENTITY(1,1) PRIMARY KEY,
	fact_fecha datetime NOT NULL,
	fact_total numeric(18, 2) NOT NULL,
	fact_idMedioPago int REFERENCES CLAVE_MOTOR.MedioPago NOT NULL,
	fact_idUsuario int REFERENCES CLAVE_MOTOR.Usuario NOT NULL
	)
GO

CREATE TABLE CLAVE_MOTOR.ItemFactura (
	item_id int IDENTITY(1,1) PRIMARY KEY,
	item_monto numeric(18, 2) NOT NULL,
	item_cantidad int NOT NULL,
	item_descripcion nvarchar(50) NOT NULL,
	item_idFactura int REFERENCES CLAVE_MOTOR.Factura NOT NULL
	)
GO



ALTER TABLE CLAVE_MOTOR.FuncionalidadRol ADD CONSTRAINT fk_Func_IDFunc
FOREIGN KEY (furo_idFuncionalidad) REFERENCES CLAVE_MOTOR.Funcionalidad(rol_id)

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

ALTER TABLE CLAVE_MOTOR.Factura ADD CONSTRAINT fk_Fact_IDUsuario
FOREIGN KEY (fact_idUsuario) REFERENCES CLAVE_MOTOR.Usuario(usua_id)

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

ALTER TABLE CLAVE_MOTOR.Oferta ADD CONSTRAINT fk_Fact_IDUsuario
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
	/* TODO REEMPLAZAR POR idUsuario aca */ ,[Publ_Empresa_Cuit]
      
      ,[Publicacion_Rubro_Descripcion] /* TODO ESTO DEBERIA SER EL ID PREVIAMENTE GENERADO */
	FROM gd_esquema.Maestra
GO






