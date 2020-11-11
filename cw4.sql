-- Database: cw4_figury

-- DROP DATABASE cw4_figury;

CREATE DATABASE cw4_figury
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
	
CREATE EXTENSION postgis;

CREATE TABLE obiekty(
id INT NOT NULL UNIQUE,
nazwa varchar(12),
geom GEOMETRY
);

INSERT INTO obiekty VALUES(1,'obiekt1',ST_GeomFromText('COMPOUNDCURVE(LINESTRING(0 1,1 1),CIRCULARSTRING(1 1,2 0,3 1), CIRCULARSTRING(3 1,4 2,5 1), LINESTRING(5 1,6 1))',0));
INSERT INTO obiekty VALUES(2,'obiekt2',ST_GeomFromText('MULTICURVE(CIRCULARSTRING(11 2,13 2,11 2),COMPOUNDCURVE(LINESTRING(10 6,14 6),CIRCULARSTRING(14 6,16 4,14 2),CIRCULARSTRING(14 2,12 0, 10 2), LINESTRING(10 2,10 6)))',0));
INSERT INTO obiekty VALUES(3,'obiekt3',ST_GeomFromText('POLYGON((7 15,10 17,12 13,7 15))',0));
INSERT INTO obiekty VALUES(4,'obiekt4',ST_GeomFromText('LINESTRING(20 20,25 25,27 24,25 22,26 21,22 19,20.5 19.5)',0));
INSERT INTO obiekty VALUES(5,'obiekt5',ST_GeomFromText('MULTIPOINT(30 30 59,38 32 234)',0));
INSERT INTO obiekty VALUES(6,'obiekt6',ST_GeomFromText('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2), POINT(4 2))',0));

-- zad.1 
SELECT ST_Area(ST_Buffer((ST_ShortestLine((SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'),(SELECT geom FROM obiekty WHERE nazwa='obiekt4'))),5 )) FROM obiekty;

-- zad.2

SELECT ST_MakePolygon(ST_AddPoint(polygon.open_line, ST_StartPoint(polygon.open_line)) )
FROM (
  SELECT geom As open_line from obiekty where nazwa='obiekt4') As polygon;
  
-- zad.3 
INSERT INTO obiekty VALUES (7,'obiekt7', ST_Collect((SELECT geom FROM obiekty WHERE id=3),(SELECT geom FROM obiekty WHERE id=4)))
SELECT * FROM obiekty WHERE id=7;

-- zad.4
SELECT SUM(ST_Area(ST_Buffer(geom,5))) As pole_pow FROM obiekty WHERE ST_HasArc(geom) IS FALSE;