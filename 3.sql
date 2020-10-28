-- Database: cw3

-- DROP DATABASE cw3;

CREATE DATABASE cw3
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
	
CREATE EXTENSION postgis;
--4:
SELECT COUNT(ST_Distance(popp.geom, rivers.geom)) AS DistanceToRivers INTO TableB
FROM public.popp, public.rivers 
WHERE popp.f_codedesc ='Building' and ST_Distance(popp.geom, rivers.geom)<100000;

--5a:
SELECT airports.name, airports.elev INTO airportsNew FROM public.airports;
SELECT MIN(ST_X(ST_AsText(geom))) as WEST, MAX(ST_X(ST_AsText(geom))) as EAST FROM airportsnew;
--5.b
SELECT ST_CENTROID(ST_SHORTESTLINE((SELECT airportsnew.geom FROM airportsnew WHERE ST_X(airportsnew.geom) 
									IN (SELECT MAX(ST_X(airports.geom)) FROM airports)),(SELECT airportsnew.geom FROM airportsnew WHERE ST_X(airportsnew.geom) 
										IN (SELECT MIN(ST_X(airportsnew.geom)) FROM airportsnew)))) AS airportB FROM airportsnew LIMIT 1;
										
--6	
SELECT ST_AREA(ST_BUFFER((ST_SHORTESTLINE((SELECT lakes.geom FROM lakes WHERE lakes.names='Iliamna Lake'),(SELECT airports.geom FROM airports WHERE airports.name='AMBLER'))),1000)) as area FROM  airports, lakes LIMIT 1;

--7
SELECT (SUM(tundra.area_km2)+SUM(swamp.areakm2)) area,trees.vegdesc species FROM  trees, tundra , swamp
WHERE tundra.area_km2 IN (SELECT tundra.area_km2 FROM tundra, trees WHERE ST_CONTAINS(trees.geom,tundra.geom) = 'true') AND swamp.areakm2  IN (SELECT swamp.areakm2 FROM swamp, trees WHERE ST_CONTAINS(trees.geom,swamp.geom) = 'true')
GROUP BY trees.vegdesc