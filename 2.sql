-- Database: cw2

-- DROP DATABASE cw2;

CREATE DATABASE cw2
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
	
CREATE EXTENSION postgis;

-- budynki (id, geometria, nazwa)

CREATE TABLE budynki (
id INT UNIQUE PRIMARY KEY,
geometria GEOMETRY,
nazwa VARCHAR(30));

-- drogi (id, geometria, nazwa)
CREATE TABLE drogi(
id INT UNIQUE PRIMARY KEY,
geometria GEOMETRY,
nazwa VARCHAR(30));

-- punkty_informacyjne (id, geometria, nazwa)
CREATE TABLE punkty_informacyjne(
id INT UNIQUE PRIMARY KEY,
geometria GEOMETRY,
nazwa VARCHAR(30));

INSERT INTO budynki(id,geometria,nazwa) VALUES (1,ST_GeomFromText('POLYGON((8 4,10.5 4,10.5 1.5,8 1.5,8 4))',0), 'BuildingA');
INSERT INTO budynki(id,geometria,nazwa) VALUES (2,ST_GeomFromText('POLYGON((4 7,6 7,6 5,4 5,4 7))',0),'BuildingB');
INSERT INTO budynki(id,geometria,nazwa) VALUES (3,ST_GeomFromText('POLYGON((3 6,3 8,5 8,5 6,3 6))',0),'BuildingC');
INSERT INTO budynki(id,geometria,nazwa) VALUES (4,ST_GeomFromText('POLYGON((9 8,9 9,10 9,10 8,9 8))',0),'BuildingD');
INSERT INTO budynki(id,geometria,nazwa) VALUES (5,ST_GeomFromText('POLYGON((1 1 ,1 2,2 2,2 1,1 1))',0),'BuildingF');

INSERT INTO drogi(id, geometria, nazwa) VALUES (1,ST_GeomFromText('LINESTRING(0 4.5,12 4.5)',0), 'RoadX');
INSERT INTO drogi(id, geometria, nazwa) VALUES (2,ST_GeomFromText('LINESTRING(7.5 10.5,7.5 0)',0), 'RoadY');

INSERT INTO punkty_informacyjne(id, geometria, nazwa) VALUES (1,ST_GeomFromText('POINT(6 9.5)',0),'K');
INSERT INTO punkty_informacyjne(id, geometria, nazwa) VALUES (2,ST_GeomFromText('POINT(6.5 6)',0),'J');
INSERT INTO punkty_informacyjne(id, geometria, nazwa) VALUES (3,ST_GeomFromText('POINT(9.5 6)',0),'I');
INSERT INTO punkty_informacyjne(id, geometria, nazwa) VALUES (4,ST_GeomFromText('POINT(1 3.5)',0),'G');
INSERT INTO punkty_informacyjne(id, geometria, nazwa) VALUES (5,ST_GeomFromText('POINT(5.5 1.5)',0),'H');

-- a.	Wyznacz całkowitą długość dróg w analizowanym mieście.  
SELECT SUM(ST_Length(geometria)) FROM drogi;

-- b.	Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego budynek o nazwie BuildingA
SELECT ST_AsText(geometria), ST_Area(geometria), ST_Perimeter(geometria) FROM budynki WHERE nazwa LIKE 'BuildingA';

-- c.	Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki posortuj alfabetycznie.  
SELECT nazwa, ST_AREA(geometria) FROM budynki ORDER BY nazwa;

-- d.	Wypisz nazwy i obwody 2 budynków o największej powierzchni.  
SELECT nazwa, ST_PERIMETER(geometria) AS obwod FROM budynki ORDER BY obwod DESC LIMIT 2;

-- e. Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.  
SELECT ST_DISTANCE(budynki.geometria,punkty_informacyjne.geometria) FROM budynki, punkty_informacyjne WHERE budynki.nazwa LIKE 'BuildingC' AND punkty_informacyjne.nazwa LIKE 'G';

-- f.	Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w odległości większej niż 0.5 od budynku BuildingB. 
SELECT ST_AREA(ST_DIFFERENCE(budynki.geometria,(SELECT ST_Buffer(geometria,0.5) FROM budynki WHERE nazwa LIKE 'BuildingB'))) FROM budynki WHERE nazwa LIKE 'BuildingC';

-- g.	Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi 
o nazwie RoadX.  
SELECT nazwa, ST_AsText(ST_Centroid(geometria)) AS centroid FROM budynki WHERE ST_Y(ST_Centroid(geometria)) > (SELECT ST_Y(ST_Centroid(geometria)) FROM drogi WHERE nazwa LIKE 'RoadX');

-- 8. Oblicz pole powierzchni tych części budynku BuildingC i poligonu o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.
SELECT ST_AREA(ST_SymDifference(geometria,ST_GeomFromText('POLYGON((4 7,6 7,6 8,4 8,4 7))',0))) FROM budynki WHERE nazwa='BuildingC';