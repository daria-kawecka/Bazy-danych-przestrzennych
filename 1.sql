-- Database: s304171

-- DROP DATABASE s304171;

-- 1
CREATE DATABASE s304171
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
	
-- 2
CREATE SCHEMA firma;
-- 3
CREATE ROLE readOnly;
GRANT USAGE ON SCHEMA public TO readOnly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readOnly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readOnly; --dodawanie dostępu do tabeli powstalych w przyszlosci

-- 4
CREATE TABLE firma.pracownicy(
	id_pracownika serial NOT NULL primary key,
	imie varchar(16) NOT NULL,
	nazwisko varchar(16) NOT NULL,
	adres VARCHAR(30),
	telefon varchar(9)
);

CREATE TABLE firma.godziny(
	id_godziny serial NOT NULL primary key,
	d_data DATE,
	liczba_godzin int,
	id_pracownika serial NOT NULL,
	FOREIGN KEY(id_pracownika) references firma.pracownicy(id_pracownika)
);

CREATE TABLE firma.pensja_stanowisko(
	id_pensji serial NOT NULL primary key,
	stanowisko VARCHAR(20), 
	kwota int,
	id_premii serial unique NOT NULL
);


CREATE TABLE firma.premia(
	id_premii serial NOT NULL primary key,
	rodzaj varchar(20),
	kwota INT
);

CREATE TABLE firma.wynagrodzenie(
	id_wynagrodzenia varchar(5) unique NOT NULL PRIMARY KEY,
	Data DATE,
	id_pracownika serial NOT NULL,
	id_godziny serial,
	id_pensji serial,
	id_premii serial,
 	FOREIGN KEY(id_pracownika) references firma.pracownicy(id_pracownika),
	FOREIGN KEY(id_godziny) references firma.godziny(id_godziny),
	FOREIGN KEY(id_pensji) references firma.pensja_stanowisko(id_pensji),
	FOREIGN KEY(id_premii) references firma.premia(id_premii)	
);

ALTER TABLE firma.premia
ADD FOREIGN KEY (id_premii) REFERENCES firma.pensja_stanowisko(id_premii);

ALTER TABLE firma.pensja_stanowisko
ADD FOREIGN KEY (id_pensji) REFERENCES firma.pracownicy(id_pracownika);
-- 5
INSERT INTO firma.pracownicy (imie,nazwisko,adres,telefon) 
values
('Basia','Jeleń','Kraków','556556556'),
('Andrzej','Nicpoń','Kraków','896536487'),
('Anastazja','Śledź','Częstochowa','566741147'),
('Marek','Król','Tarnów','656585614'),
('Andrzej','Długosz','Częstochowa','525748635'),
('Olaf','Bałwan','Kraków','567923012'),
('Janusz','Duda','Warszawa','741852963'),
('Anastazja','Czerny','Tarnów','654987321'),
('Mateusz','Czerny','Tarnów','569831421'),
('Malwina','Zawadzka','Częstochowa','641758423');

INSERT INTO firma.godziny(d_data,liczba_godzin) values 
('2020-05-05',121),
('2020-05-04',168),
('2020-05-05',89),
('2020-05-10',100),
('2020-05-11',61),
('2020-05-07',92),
('2020-05-14',172),
('2020-05-11',23),
('2020-05-09',115),
('2020-05-06',55);




-- dodanie do tabeli godziny informacji o miesiącu i tygodniu:
ALTER TABLE godziny ADD miesiac DATE;
INSERT INTO godziny(miesiac) SELECT EXTRACT(MONTH FROM d_data) FROM godziny;

ALTER TABLE wynagrodzenie ALTER COLUMN data TYPE varchar;


INSERT INTO firma.pensja_stanowisko(stanowisko, kwota) values
('kierownik', 10500),
('gł.księgowa',9200),
('asystentka',4200),
('HR',3100),
('doradca',2500),
('kierownik',9999.99),
('pracownik',5200),
('asystentka',4100),
('tester jakości',7500.50),
('PR',4506);

INSERT INTO firma.premia(rodzaj,kwota) values
('uznaniowa',500),
('świąteczna',220),
('zapomoga',150),
('uznaniowa',350),
('motywacyjna',150),
('uznaniowa',250),
('świąteczna',225),
('kwartalna',125),
('okolicznościowa',450),
('za zasługi',520);


-- 6
SELECT firma.id_pracownika, firma.nazwisko FROM firma.pracownicy;
SELECT fw.id_pracownika, fp.kwota, kprem.kwota_premii FROM firma.wynagrodzenie fw, firma.pensja_stanowisko fp, firma.premia fprem
WHERE fw.id_pensji = fp.id_pensji AND fw.id_premii = fprem.id_premii AND fpen.kwota + fprem.kwota > 1000;
	
SELECT fw.id_pracownika FROM firma.wynagrodzenie fw, firma.pensja_stanowisko fpen
	WHERE fw.id_pensji=fpen.id_pensji AND fw.id_premii IS NULL and fpen.kwota > 1000;

SELECT * FROM frma.pracownicy fpr WHERE fpr.imie like '%J'

SELECT fpr.imie, fpr.nazwisko FROM firma.pracownicy fpr WHERE fpr.nazwisko IN '%n%' AND fpr.imie like '%a'

SELECT fpr.imie, fpr.nazwisko FROM firma.pracownicy fpr, firma.godziny fgodz
	WHERE fprac.id_pracownika = fgodz.id_pracownika AND fgodz.liczba_godzin > 160;

SELECT fpr.imie, fpr.nazwisko FROM firma.pracownicy fpr, firma.wynagrodzenie fw, firma.pensja_stanowisko fpen,
	WHERE fpr.id_pracownika = fw.id_pracownika AND fw.id_pensji = fpen.id_pensji AND fpen.kwota > 1500 AND fpen.kwota <3000;

SELECT fpr.imie, fpr.nazwisko FROM firma.pracownicy fpr, firma.godziny fgodz, firma.wynagrodzenia fw
	WHERE fpr.id_pracownika = fw.id_pracownika AND fw.id_godziny = fgodz.id_godziny AND fgodz.liczba_godzin > 160 AND fw.id_premii IS NULL;


-- 7
SELECT COUNT(*) fpen.stanowisko FROM firma.pensja_stanowisko AS fpen
	GROUP BY fpen.stanowisko DESC;
SELECT MIN(fpen.kwota), MAX(fpen.kwota) FROM firma.pensja_stanowisko fpen 
	WHERE fpen.stanowisko = 'kierownik';

SELECT SUM(COALESCE(fpr.kwota,0))+ SUM(COALESCE(fpen.kwota,0)) AS wynagrodznie FROM firm.wynagrodzenie fw 
	LEFT JOIN firma.pensja fpen ON fw.id_pensji = fpen.id_pensji
	LEFT JOIN firma.premia fpr ON fw.id_premii = fpr.id_premii 
	
SELECT SUM(COALESCE(kpr.fwota,0))+ SUM(COALESCE(fpen.fwota,0)) AS wynagrodznie FROM firma.wynagrodzenie fw
	LEFT JOIN firma.pensja fpen ON fw.id_pensji = fpen.id_pensji
	LEFT JOIN firma.premia fpr ON fw.id_premii = fpr.id_premii GROUP BY fpen.stanowisko
	
SELECT COUNT(fw.id_premii) FROM firma.wynagrodzenia 
	LEFT JOIN firma.pensja fpen ON fw.id_pensji=fpen.id_pensji GROUP BY fpen.stanowisko
	
DELETE
FROM  firma.wynagrodzenie fw    
USING firma.pensja fpen 
WHERE fpen.fwota < 1200 AND fw.id_pensji = fpen.id_pensji



-- 8
ALTER TABLE firma.pracownicy fp ALTER COLUMN telefon TYPE varchar(14) USING telefon::varchar;
UPDATE firma.pracownicy kp SET telefon - '(+48) '||fp.telefon

UPDATE firma.pracownicy fp SET telefon=SUBSTRING(fp.telefon,1,9)||'-'||SUBSTRING(fp.telefon,10,3)||'-'||SUBSTRING(fp.telefon,13,3)

SELECT UPPER(fp.imie), UPPER(fp.nazwisko), UPPER(fp.adres), UPPER(fp.telefon), LENGTH(fp.nazwisko) 
		FROM firma.pracownicy fp 
			ORDER BY length(fp.nazwisko) DESC LIMIT 1
			
SELECT fp.*,md5(fpen.kwota) AS kwota FROM firma.pracownicy fp
	   JOIN firma.wynagrodzenie fw ON fw.id_pracownika = fp.id_pracownika 
       JOIN firma.pensja_stanowisko fpen ON fpen.id_pensji = fw.id_pensji 
-- 9
SELECT 'Pracownik ' || fp.imie || ' ' || fp.nazwisko 
|| ' w dniu ' || fg.data
|| ' otrzymał pensje całkowitą na kwotę ' || fpen.kwota + fpr.kwota 
|| ' gdzie wynagrodzenie zasadnicze wynosiło: '|| fpen.kwota || ',a premia: ' || fpr.kwota || ', nadgodziny: ' || '0 zł' AS raport
FROM firma.pracownicy fp
JOIN firma.wynagrodzenie fw ON fw.id_pracownika = fp.id_pracownika 
JOIN firma.pensja fpen ON fpen.id_pensji = fw.id_pensji 
JOIN firma.premia fpr ON fpr.id_premii =fw.id_premii 
JOIN firma.godziny fg ON fp.id_pracownika = fp.id_pracownika
	   
