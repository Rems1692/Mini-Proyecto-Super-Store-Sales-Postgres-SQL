
1 - ¿CUAL ES EL MARGEN DE GANANCIA DE CADA CATEGORIA?
SELECT
P.CATEGORY,
SUM (V.QUANTITY) AS CANTIDAD_VENDIDAS,
ROUND(SUM(V.SALES),2) AS VENTAS_TOTALES,
ROUND (SUM(V.PROFIT),2) AS GANANCIAS_TOTALES,
ROUND(SUM(V.PROFIT)/SUM(V.SALES)* 100.0,2)
AS MARGEN
FROM VENTAS_SS V
JOIN PRODUCTOS_SSL P
ON V.PRODUCT_ID = P.PRODUCT_ID
GROUP BY
CATEGORY
ORDER BY VENTAS_TOTALES DESC

-- Furniture vende casi lo mismo que las otras dos categorías, pero su ganancia es 8 veces menor

2 - ¿QUE SUB CATEGORIAS TIENEN LOS PEORES MARGENES DE GANANCIAS EN FURNITURE?
SELECT
P.SUB_CATEGORY,
SUM (V.QUANTITY) AS CANTIDAD_VENDIDAS,
ROUND(SUM(V.SALES),2) AS VENTAS_TOTALES,
ROUND (SUM(V.PROFIT),2) AS GANANCIAS_TOTALES,
ROUND(SUM(V.PROFIT)/SUM(V.SALES)* 100.0,2)
AS MARGEN
FROM VENTAS_SS V
JOIN PRODUCTOS_SSL P
ON V.PRODUCT_ID = P.PRODUCT_ID
WHERE P.CATEGORY = 'Furniture'
GROUP BY
P.SUB_CATEGORY
ORDER BY VENTAS_TOTALES DESC

--Dentro de Furniture, solo 2 de las 4 subcategorías generan pérdida: Tables (-8.56%) y Bookcases (-3.02%)
--Furnishings vende la mayor cantidad de unidades (3,563) pero genera las ventas más bajas en dólares ($91,705) de las 4 
-- Y aun así tiene el mejor margen (14.24%). Es decir, Furnishings son productos de bajo precio unitario pero eficientes, 
--Mientras que Chairs vende menos unidades pero genera casi 4 veces más ingreso, con margen bastante más bajo 8.10%

3 - ¿EN QUE ESTADOS FURNITURE GENERA PERDIDAS?
SELECT
V.STATE,
SUM (V.QUANTITY) AS CANTIDAD_VENDIDAS,
ROUND(SUM(SALES),2) AS VENTAS_TOTALES,
ROUND (SUM(PROFIT),2) AS GANANCIAS_TOTALES,
ROUND(SUM(PROFIT)/SUM(SALES)* 100.0,2)
AS MARGEN
FROM VENTAS_SS V
JOIN PRODUCTOS_SSL P
ON V.PRODUCT_ID = P.PRODUCT_ID
WHERE P.CATEGORY = 'Furniture'
GROUP BY
V.STATE
ORDER BY VENTAS_TOTALES DESC
LIMIT 10;

--De los 10 estados que más venden Furniture, 5 tienen margen negativo (Texas, Pennsylvania, Illinois, Ohio, Florida) 
-- Es decir, la mitad de tus estados top en volumen están perdiendo dinero en esta categoría. 
--El caso más grave es Illinois con -32.10%, seguido de Pennsylvania (-18.29%) y Texas, 
--que aunque tiene el peor margen en dólares (-$10,436), su % (-17.22%) no es el más severo.
--El contraste más interesante: California vende casi el doble que New York (1,696 vs 877 unidades) 
--pero tiene margen más bajo (5.87% vs 6.27%) — mientras que Michigan y Virginia, con mucho menos volumen, logran márgenes de +20%.


4 - ¿COMO VARIA EL MARGEN DE LAS SUB CATEGORIAS SEGUN EL RANGO DE DESCUENTOS APLICADO?
SELECT
P.SUB_CATEGORY,
	CASE
		WHEN DISCOUNT = 0 THEN '0%'
		WHEN DISCOUNT <= 0.2 THEN '1-20%'
		WHEN DISCOUNT <= 0.4 THEN '21-40%'
		ELSE '41%+'
	END AS RANGO_DESCUENTO,
    SUM (V.QUANTITY) AS CANTIDAD_VENDIDAS,
	ROUND(SUM(SALES),2) AS VENTAS_TOTALES,
	ROUND (SUM(PROFIT),2) AS GANANCIAS_TOTALES,
	ROUND(SUM(PROFIT)/SUM(SALES)* 100.0,2)
	AS MARGEN
FROM VENTAS_SS V
JOIN PRODUCTOS_SSL P
	ON V.PRODUCT_ID = P.PRODUCT_ID
WHERE CATEGORY = 'Furniture'
GROUP BY
RANGO_DESCUENTO,
P.SUB_CATEGORY
ORDER BY
RANGO_DESCUENTO,
P.SUB_CATEGORY;

--las 4 subcategorías, sin excepción: sin descuento, TODAS son rentables (18-27% de margen) 
--Incluso Tables y Bookcases, que en tu análisis general aparecían con margen negativo.
--el margen se vuelve negativo apenas se supera el 20% de descuento

5 - ¿CUANTO DINERO SE PIERDE EN LAS SUB CATEGORIAS DE FURNITURE CON DESCUENTOS MAYORES A 21%?
SELECT
SUB_CATEGORY,
SUM (V.QUANTITY) AS CANTIDAD_VENDIDAS,
ROUND(SUM(PROFIT),2) 
AS PERDIDA_TOTAL,
COUNT(DISTINCT ORDER_ID) 
AS ORDENES_AFECTADAS
FROM VENTAS_SS V
JOIN PRODUCTOS_SSL P
	ON V.PRODUCT_ID = P.PRODUCT_ID
WHERE CATEGORY = 'Furniture'
AND DISCOUNT > 0.20
GROUP BY
P.SUB_CATEGORY
HAVING SUM(PROFIT)<0
ORDER BY
PERDIDA_TOTAL ASC;

--Furniture pierde $54,478 en 513 órdenes con descuento mayor a 21%, 
--Concentrado principalmente en Tables ($30,698, el 56% del total). 
--Limitar el descuento máximo a 20% en esta categoría —especialmente en Tables, 
--donde el impacto por unidad es mayor debido a su precio elevado 
--podría recuperar la mayor parte de esos $54,478 sin afectar el resto de la operación."

6 - ¿CÓMO HA EVOLUCIONADO LA GANANCIA DEL NEGOCIO AÑO A AÑO, Y CUÁL FUE EL PORCENTAJE DE CRECIMIENTO RESPECTO AL AÑO ANTERIOR?
SELECT 
EXTRACT(YEAR FROM ORDER_DATE) AS YEAR,
SUM (QUANTITY) AS CANTIDAD_VENDIDAS,
ROUND(SUM(SALES), 2) AS VENTAS_TOTALES,
ROUND(SUM(PROFIT), 2) AS GANANCIAS_TOTALES,
ROUND(SUM(PROFIT)/SUM(SALES)*100, 2) AS MARGEN,
ROUND(
       (SUM(PROFIT) - LAG(SUM(PROFIT)) 
	   OVER (ORDER BY EXTRACT(YEAR FROM ORDER_DATE)))
        / LAG(SUM(PROFIT)) 
		OVER (ORDER BY EXTRACT(YEAR FROM ORDER_DATE))
        * 100, 2) AS CRECIMIENTO
FROM VENTAS_SS
GROUP BY YEAR
ORDER BY YEAR DESC;

-- La ganancia crecio los 3 años, pero a un ritmo decreciente:
-- 2015: +24.37% | 2016: +32.74% | 2017: +14.24%
-- 2017 tuvo el crecimiento mas bajo de los 3 años, menos de la mitad 
-- del ritmo de 2016 -- señal de que la eficiencia se desacelero.

7 - ¿EL CRECIMIENTO DE VENTAS HA IDO A LA PAR DEL CRECIMIENTO DE GANANCIA, O HAY AÑOS DONDE EL NEGOCIO VENDIÓ MÁS PERO GANÓ PROPORCIONALMENTE MENOS?
SELECT 
    EXTRACT(YEAR FROM ORDER_DATE) AS YEAR,
    ROUND(SUM(SALES), 2) AS VENTAS_TOTALES,
    ROUND(SUM(PROFIT), 2) AS GANANCIAS_TOTALES,
    ROUND(
        (SUM(SALES) - LAG(SUM(SALES)) OVER (ORDER BY EXTRACT(YEAR FROM ORDER_DATE)))
        / LAG(SUM(SALES)) OVER (ORDER BY EXTRACT(YEAR FROM ORDER_DATE))
        * 100, 2) AS CRECIMIENTO_VENTAS,
    ROUND(
        (SUM(PROFIT) - LAG(SUM(PROFIT)) OVER (ORDER BY EXTRACT(YEAR FROM ORDER_DATE)))
        / LAG(SUM(PROFIT)) OVER (ORDER BY EXTRACT(YEAR FROM ORDER_DATE))
        * 100, 2) AS CRECIMIENTO_GANANCIAS
FROM VENTAS_SS
GROUP BY YEAR
ORDER BY YEAR DESC;

-- 2017 las ventas crecieron más rápido que la ganancia. 
-- En otras palabras, el negocio vendió bastante más, 
-- pero esa venta extra no se tradujo en la misma proporción de ganancia extra.
-- 2014 --> 2015 el negocio vendió MENOS en dólares totales, 
-- pero cada venta fue más eficiente, 
-- así que terminó ganando más dinero con menos esfuerzo de venta.

8 - ¿QUÉ MESES DE 2017 TUVIERON EL PEOR MARGEN?
SELECT 
    EXTRACT(MONTH FROM ORDER_DATE) AS MONTH,
	TO_CHAR(ORDER_DATE, 'FMMONTH') AS MONTH_TEXT,
	SUM(QUANTITY) AS UNIDADES_VENDIDAS,
    ROUND(SUM(SALES), 2) AS VENTAS_TOTALES,
    ROUND(SUM(PROFIT), 2) AS GANANCIAS_TOTALES,
    ROUND(SUM(PROFIT)/SUM(SALES)*100, 2) AS MARGEN
FROM VENTAS_SS
WHERE EXTRACT(YEAR FROM ORDER_DATE) = 2017
GROUP BY 
MONTH,
MONTH_TEXT
ORDER BY MONTH;

-- Abril 2.56% | Febrero 7.95% | Noviembre 8.18%

9 - ¿CÓMO VARÍA EL MARGEN DE ABRIL 2017 SEGÚN EL RANGO DE DESCUENTO?
SELECT 
    CASE 
        WHEN DISCOUNT = 0 THEN '0%'
        WHEN DISCOUNT <= 0.2 THEN '1-20%'
        WHEN DISCOUNT <= 0.4 THEN '21-40%'
        ELSE '41%+'
    END AS RANGO_DESCUENTO,
	SUM(QUANTITY) AS UNIDADES_VENDIDAS,
    ROUND(SUM(SALES), 2) AS VENTAS_TOTALES,
    ROUND(SUM(PROFIT), 2) AS GANANCIAS_TOTALES,
    ROUND(SUM(PROFIT)/SUM(SALES)*100, 2) AS MARGEN
FROM VENTAS_SS
WHERE EXTRACT(YEAR FROM ORDER_DATE) = 2017
  AND EXTRACT(MONTH FROM ORDER_DATE) = 4
GROUP BY RANGO_DESCUENTO
ORDER BY RANGO_DESCUENTO;

-- 21-40% → -13.11% | 41%+ → -113.07%

10 - ¿QUÉ CATEGORÍA CAUSÓ LA CAÍDA DE MARGEN EN ABRIL 2017?
SELECT 
    CATEGORY,
	SUM(QUANTITY) AS UNIDADES_VENDIDAS,
    ROUND(SUM(SALES), 2) AS VENTAS_TOTALES,
    ROUND(SUM(PROFIT), 2) AS GANANCIAS_TOTALES,
    ROUND(SUM(PROFIT)/SUM(SALES)*100, 2) AS MARGEN
FROM VENTAS_SS V
JOIN PRODUCTOS_SSL p ON V.PRODUCT_ID = P.PRODUCT_ID
WHERE EXTRACT(YEAR FROM ORDER_DATE) = 2017
  AND EXTRACT(MONTH FROM ORDER_DATE) = 4
GROUP BY CATEGORY
ORDER BY MARGEN ASC;

--Technology -21.32% (causa: 2 órdenes de Machines con ~45% de descuento promedio)


11 - ¿QUÉ SUBCATEGORÍA ESPECÍFICA DE TECHNOLOGY, Y CON QUÉ DESCUENTO PROMEDIO, EXPLICA LA CAÍDA DE MARGEN EN ABRIL 2017?
SELECT 
    SUB_CATEGORY,
	SUM (QUANTITY) AS CANTIDAD_VENDIDAS,
    COUNT(DISTINCT order_id) AS ORDENES_TOTALES,
    ROUND(AVG(discount)*100, 2) AS DESCUENTO_PROMEDIO,
    ROUND(SUM(sales), 2) AS VENTAS_TOTALES,
    ROUND(SUM(profit), 2) AS GANANCIAS_TOTALES
FROM ventas_ss v
JOIN productos_ssl p ON v.product_id = p.product_id
WHERE category = 'Technology'
  AND EXTRACT(YEAR FROM ORDER_DATE) = 2017
  AND EXTRACT(MONTH FROM ORDER_DATE) = 4
GROUP BY SUB_CATEGORY
ORDER BY GANANCIAS_TOTALES ASC;

-- Machines fue la unica subcategoria con margen fuertemente negativo (-41.36%),
-- con solo 2 ordenes (7 unidades) y un descuento promedio de ~45%.
-- No es un problema estructural de Technology -- es un caso puntual de
-- 2 transacciones con descuento fuera de lo normal, que distorsiono
-- el margen de toda la categoria ese mes.