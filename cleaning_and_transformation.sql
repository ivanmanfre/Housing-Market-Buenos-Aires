/* Combining listings from agency and direct owner into a single table */
SELECT "Titulo", "Precio", "Ambientes", "Barrio", "Direccion", "Metros cuadrados", 'Agency' AS "Posted_By"
FROM agency
UNION ALL
SELECT "Titulo", "Precio", "Ambientes", "Barrio", "Direccion", "Metros cuadrados", 'Direct' AS "Posted_By"
FROM direct;

/*
CREATE TABLE combined AS
SELECT "Titulo", "Precio", "Ambientes", "Barrio", "Direccion", "Metros cuadrados", 'Agency' AS "Posted_By"
FROM agency
UNION ALL
SELECT "Titulo", "Precio", "Ambientes", "Barrio", "Direccion", "Metros cuadrados", 'Direct' AS "Posted_By"
FROM direct;
*/

-- Convert all prices from USD to Peso (ARS)
-- 1 USD = $1165 ARS (7th Feb 24)
WITH conversion AS(
	SELECT 
	 CASE
		WHEN "Precio" LIKE 'USD%' THEN
		  -- Remove 'USD ', remove '.', convert to numeric, multiply by 1165
		    CAST(CAST(REPLACE(REPLACE("Precio", 'USD ', ''), '.', '') AS NUMERIC) * 1165 AS TEXT)
		WHEN "Precio" = 'Consultar precio' THEN NULL
	    WHEN "Precio" LIKE 'Pesos%' THEN
	        REPLACE("Precio", 'Pesos ', '')
		ELSE
		  REPLACE(REPLACE("Precio", '$ ', ''), '.', '')
	  END AS "Converted_Price"
	FROM combined)
SELECT ROUND(CAST("Converted_Price" AS NUMERIC)/ 1165, 0) AS price_usd,
       "Converted_Price" AS price_pesos
FROM conversion
----
/*
UPDATE combined
SET "Precio" =
	 CASE
		WHEN "Precio" LIKE 'USD%' THEN
		  -- Remove 'USD ', remove '.', convert to numeric
		    CAST(CAST(REPLACE(REPLACE("Precio", 'USD ', ''), '.', '') AS NUMERIC) AS TEXT)
		WHEN "Precio" = 'Consultar precio' THEN NULL
	    WHEN "Precio" LIKE 'Pesos%' THEN
	        CAST(CAST(REPLACE("Precio", 'Pesos ', '') AS NUMERIC)/ 1165 AS TEXT) -- convert to USD
		ELSE
		  CAST(ROUND(CAST(REPLACE(REPLACE("Precio", '$ ', ''), '.', '') AS NUMERIC) / 1165 , 0) AS TEXT)  -- to usd
     END
*/	
ALTER TABLE combined
ALTER COLUMN "Precio" TYPE NUMERIC
USING "Precio"::NUMERIC;

DELETE FROM combined
WHERE "Precio" < 100 or "Precio" > 30000;
---

UPDATE combined
SET "Ambientes" = REPLACE("Ambientes",' amb.','')

SELECT *
FROM combined
WHERE LOWER("Titulo") LIKE '%monoambiente%'
AND (LOWER("Ambientes") LIKE '%dorm.%' OR LOWER("Ambientes") LIKE '%baño%');

-- Used lower, search was case sensitive
UPDATE "combined"
SET "Ambientes" = CASE
    WHEN LOWER("Titulo") LIKE '%monoambiente%' OR LOWER("Titulo") LIKE '%1 ambiente%' THEN '1'
    WHEN LOWER("Titulo") LIKE '%2 ambientes%' OR LOWER("Titulo") LIKE '%dos ambientes%' THEN '2'
    WHEN LOWER("Titulo") LIKE '%3 ambientes%' OR LOWER("Titulo") LIKE '%tres ambientes%' THEN '3'
    WHEN LOWER("Titulo") LIKE '%4 ambientes%' OR LOWER("Titulo") LIKE '%cuatro ambientes%' THEN '4'
    WHEN LOWER("Titulo") LIKE '%5 ambientes%' OR LOWER("Titulo") LIKE '%cinco ambientes%' THEN '5'
    WHEN LOWER("Titulo") LIKE '%6 ambientes%' OR LOWER("Titulo") LIKE '%seis ambientes%' THEN '6'
    WHEN LOWER("Titulo") LIKE '%7 ambientes%' OR LOWER("Titulo") LIKE '%siete ambientes%' THEN '7'
    WHEN LOWER("Titulo") LIKE '%8 ambientes%' OR LOWER("Titulo") LIKE '%ocho ambientes%' THEN '8'
    WHEN LOWER("Titulo") LIKE '%9 ambientes%' OR LOWER("Titulo") LIKE '%nueve ambientes%' THEN '9'
    WHEN LOWER("Titulo") LIKE '%10 ambientes%' OR LOWER("Titulo") LIKE '%diez ambientes%' THEN '10'
    ELSE "Ambientes"
END
WHERE LOWER("Ambientes") LIKE '%dorm.%' OR LOWER("Ambientes") LIKE '%baño%'
AND (LOWER("Titulo") LIKE '%monoambiente%'
     OR LOWER("Titulo") SIMILAR TO '%(1|2|3|4|5|6|7|8|9|10) ambiente%'
     OR LOWER("Titulo") SIMILAR TO '%(uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez) ambientes%');

---

DELETE FROM "combined"
WHERE LOWER("Ambientes") LIKE '%dorm.%';
DELETE FROM "combined"
WHERE LOWER("Ambientes") LIKE '%baño%';

-- Removing m2
UPDATE combined
SET "Metros cuadrados" = REPLACE("Metros cuadrados", ' m²', '')
UPDATE combined
SET "Metros cuadrados" = NULL
WHERE "Metros cuadrados" LIKE '%amb.%';

SELECT *
FROM combined


-- Neighbourhood cleaning. Remove city

UPDATE "combined"
SET "Barrio" = REPLACE("Barrio", ', Capital Federal', '');

UPDATE "combined"
SET "Barrio" = REPLACE ("Barrio", 'Cid Campeador, ', '');

UPDATE "combined"
SET "Barrio" = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("Barrio", 'Primera Junta, ', ''),'Almagro Norte, ', ''),'Flores Sur, ', ''),'Caballito Sur, ', ''),'Palermo Nuevo, ',''),'Parque Rivadavia, ',''),'Caballito Norte, ',''),'Palermo Hollywood, ',''),'Palermo Viejo, ','')

UPDATE "combined"
SET "Barrio" = TRIM(SUBSTRING("Barrio" FROM POSITION(',' IN "Barrio") + 1))
WHERE POSITION(',' IN "Barrio") > 0;

SELECT *
FROM combined
WHERE "Barrio" = 'Monserrat'

SELECT DISTINCT "Barrio"
FROM combined

-- Duplicates
BEGIN;
CREATE TABLE temp_combined AS
SELECT DISTINCT ON ("Titulo", "Barrio", "Precio", "Direccion", "Ambientes") *
FROM combined
ORDER BY "Titulo", "Barrio", "Precio", "Direccion", "Ambientes";

DROP TABLE combined;

ALTER TABLE temp_combined RENAME TO combined;

COMMIT;
 
---
ALTER TABLE combined
ALTER COLUMN "Ambientes" TYPE NUMERIC
USING "Ambientes"::NUMERIC;

ALTER TABLE combined
ALTER COLUMN "Metros cuadrados" TYPE NUMERIC
USING "Metros cuadrados"::NUMERIC;

--
UPDATE combined
SET "Barrio" = 'Palermo'
WHERE "Barrio" = 'Las Canitas'

SELECT COUNT("Barrio") as count, "Barrio"
FROM combined
GROUP BY "Barrio"
ORDER BY count DESC