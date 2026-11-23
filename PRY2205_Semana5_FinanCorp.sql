/* ================================================================
   CASO 1: LISTADO DE CLIENTES

   Objetivo:
   Identificar clientes trabajadores dependientes cuya profesion
   sea CONTADOR o VENDEDOR.

   Se consideran solamente clientes cuyo año de inscripcion sea
   superior al promedio redondeado de todos los años de inscripcion.

   Se utiliza una subconsulta para calcular dicho promedio.
   ================================================================ */

SELECT
    TO_CHAR(c.numrun, 'FM999G999G999',
            'NLS_NUMERIC_CHARACTERS='',.''')
        || '-' || c.dvrun AS "RUT CLIENTE",

    INITCAP(
        TRIM(
            NVL(c.pnombre, '') || ' ' ||
            NVL(c.snombre, '') || ' ' ||
            NVL(c.appaterno, '') || ' ' ||
            NVL(c.apmaterno, '')
        )
    ) AS "NOMBRE CLIENTE",

    UPPER(p.nombre_prof_ofic) AS "PROFESION CLIENTE",

    TO_CHAR(c.fecha_inscripcion, 'DD-MM-YYYY')
        AS "FECHA DE INSCRIPCION",

    INITCAP(NVL(c.direccion, 'SIN DIRECCION'))
        AS "DIRECCION CLIENTE"

FROM cliente c

INNER JOIN profesion_oficio p
    ON c.cod_prof_ofic = p.cod_prof_ofic

INNER JOIN tipo_cliente t
    ON c.cod_tipo_cliente = t.cod_tipo_cliente

WHERE UPPER(t.nombre_tipo_cliente) LIKE '%DEPENDIENTE%'

AND UPPER(p.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')

AND EXTRACT(YEAR FROM c.fecha_inscripcion) >
    (
        SELECT ROUND(
                   AVG(EXTRACT(YEAR FROM fecha_inscripcion))
               )
        FROM cliente
        WHERE fecha_inscripcion IS NOT NULL
    )

ORDER BY c.numrun ASC;


/* ================================================================
   CASO 2: AUMENTO DE CREDITO

   Objetivo:
   Obtener el RUT, edad y cupo disponible para compras de los
   clientes cuyo cupo disponible sea mayor o igual al maximo
   cupo disponible correspondiente al año anterior.

   Se utiliza una subconsulta para obtener el MAXIMO cupo.

   REFERENCIA TEMPORAL:
   Se utiliza FECHA_SOLIC_TARJETA para identificar las tarjetas
   solicitadas durante el año anterior.
   Esta referencia debe validarse con el poblamiento original.
   ================================================================ */


/* CREACION DE LA TABLA DE RESULTADOS */

BEGIN
    EXECUTE IMMEDIATE
        'DROP TABLE CLIENTES_CUPOS_COMPRA PURGE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

CREATE TABLE CLIENTES_CUPOS_COMPRA AS

SELECT
    TO_CHAR(c.numrun, 'FM999999999')
        || '-' || c.dvrun AS RUT_CLIENTE,

    TRUNC(
        MONTHS_BETWEEN(SYSDATE, c.fecha_nacimiento) / 12
    ) AS EDAD,

    NVL(tar.cupo_disp_compra, 0)
        AS CUPO_DISPONIBLE_COMPRA,

    UPPER(tc.nombre_tipo_cliente)
        AS TIPO_CLIENTE

FROM cliente c

INNER JOIN tarjeta_cliente tar
    ON c.numrun = tar.numrun

INNER JOIN tipo_cliente tc
    ON c.cod_tipo_cliente = tc.cod_tipo_cliente

WHERE NVL(tar.cupo_disp_compra, 0) >=
    (
        SELECT MAX(NVL(tar_ant.cupo_disp_compra, 0))

        FROM tarjeta_cliente tar_ant

        WHERE EXTRACT(YEAR FROM tar_ant.fecha_solic_tarjeta) =
              EXTRACT(YEAR FROM SYSDATE) - 1
    );


/* VISUALIZACION DE RESULTADOS DEL CASO 2 */

SELECT
    RUT_CLIENTE AS "RUT_CLIENTE",

    EDAD AS "EDAD",

    TO_CHAR(
        CUPO_DISPONIBLE_COMPRA,
        '$FM999G999G999',
        'NLS_NUMERIC_CHARACTERS='',.'''
    ) AS "CUPO_DISPONIBLE_COMPRA",

    TIPO_CLIENTE AS "TIPO_CLIENTE"

FROM CLIENTES_CUPOS_COMPRA

ORDER BY EDAD ASC;
