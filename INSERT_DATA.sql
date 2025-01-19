USE Wypozyczalnia;
GO

-- wstawiam dane do tabeli Osoba z pliku umieszczonego lokalnie
BULK INSERT Osoby.Osoba
FROM 'C:\data\osoby.csv'
WITH (
    FORMAT = 'CSV',         
    FIRSTROW = 2,           -- pomijam nag³ówek
    FIELDTERMINATOR = ',',  -- serparator kolumn
    ROWTERMINATOR = '\n',   -- separator wierszy 
	FIRE_TRIGGERS
);

-- wsatwiam dane do tabeli poprzez polecenie DML
INSERT INTO Osoby.Stanowisko(nazwa) 
VALUES
(N'G³ówny Kierownik'),
('Manager'),
('Kierownik'),
('Specjalista'),
('Pracownik Biurowy'),
('Technik'),
('Do aktualiazcji')

INSERT INTO Osoby.StatusZatrudnienia (nazwa_statusu) 
VALUES
('Aktywny'),
('Urlop'),
('Zwolniony'),
('Zawieszony'),
('Rekrutacja');

INSERT INTO Sprzet.Uprawnienie (nazwa) 
VALUES
('Do aktualizacji'),
('Patent ¯eglarski'),
('Uprawnienia wspinaczkowe'),
('Uprawnienia rowerowe'),
('Pozwolenie na broñ');

INSERT INTO Kategorie.PoraRoku (nazwa) VALUES
('Wiosna'),
('Lato'),
('Jesieñ'),
('Zima'),
(N'Przedwioœnie');

INSERT INTO Kategorie.Kategoria (nazwa, wymaga_patentu)
VALUES
('Narciarstwo', 0),
('£y¿wiarstwo', 0),
('Tenis', 0),
('Kolarstwo', 1),
('Wspinaczka', 1)

INSERT INTO Kategorie.KategoriaPoraRoku (kategoria_id, pora_roku_id)
VALUES
(1,4),
(1,3),
(1,5),
(1,1),
(2,4),
(3,1),
(3,2),
(3,3),
(4,1),
(4,2),
(4,3),
(5,2)

INSERT INTO Sprzet.Producent (nazwa, email, telefon, jezyk) 
VALUES
('Producent A', 'mail@producenta.pl', '123456789', 'Polski'),
('Producent B', 'rsg@producentb.com', '987654321', 'Francuski'),
('Producent C', 'elan@producentc.net', '543216789', 'Szwedzki'),
('Producent D', 'adidas@producentd.org', '678945321', 'Niemiecki'),
('Producent E', 'bienchi@prodE.eu', '789654123', N'W³oski');

INSERT INTO Serwis.StatusReklamacji (nazwa)
VALUES
('naprawiono'),
('odrzucono'),
('w trakcie naprawy'),
('rozpatrywana')

GO

-- wstawiam dane pracowników. G³owny kierownik jest kluczowy, dlatego wprowadzam go rêcznie. 
-- z uwagi na trigger, bulk insert móg³by nie zadzia³aæ
SET IDENTITY_INSERT Osoby.Pracownik ON;

INSERT INTO Osoby.Pracownik 
    (pracownik_id, przelozony_id, stanowisko_id, pesel, adres, data_zatrudnienia, status_zatrudnienia, osoba_id)
VALUES 
    (1, NULL, 1, '91100337152', 'Kazikowskiego 20, 05-300 Miñsk Mazowiecki', '2015-01-18', 1, 2);

SET IDENTITY_INSERT Osoby.Pracownik OFF;

-- pozostali pracownicy wstawieni z opcj¹ auto-increment wskazan¹ na poziomie kodu DDL
INSERT INTO Osoby.Pracownik 
    (przelozony_id, stanowisko_id, pesel, adres, data_zatrudnienia, osoba_id)
VALUES 
    (1, 2, '19681897386', 'Room 1860', '2022-07-23', 1),
    (1, 2, '19919460157', 'PO Box 94412', '2020-05-28', 3),
    (2, 3, '19740108973', 'PO Box 53194', '2021-02-02', 4),
    (2, 3, '19939943031', 'Apt 536', '2020-05-28', 5),
    (3, 3, '19560827075', 'Suite 1', '2024-05-27', 6),
    (4, 4, '19954704709', '18th Floor', '2023-08-28', 7),
    (5, 4, NULL, 'Suite 71', '2022-12-28', 8),
    (6, 4, '19897354554', 'Suite 76', '2022-12-28', 9),
    (6, 5, '19584710944', 'Apt 1931', '2021-02-27', 10),
    (6, 5, '19503315389', '2nd Floor', '2023-01-02', 11),
    (7, 6, NULL, 'PO Box 47030', '2024-09-24', 12),
    (7, 3, '19971501556', 'Apt 105', '2024-08-27', 13),
    (8, 2, '19606353605', 'Suite 3', '2021-09-12', 14),
    (9, 3, '19668714363', '19th Floor', '2023-06-12', 15);

-- Wstawianie danych do encji Klient
BULK INSERT Osoby.Klient
FROM 'C:\data\lista_klientow.csv'
WITH (
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',  
    CODEPAGE = '65001',    -- kodowanie UTF-8
    FIRSTROW = 2 ,
	FIRE_TRIGGERS
);

-- sprzet
BULK INSERT Sprzet.Sprzet
FROM 'C:\data\sprzet.csv'
WITH (
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',  
    CODEPAGE = '65001',     -- Kodowanie UTF-8
    FIRSTROW = 2,
	FIRE_TRIGGERS			-- chcê, aby triggery zadzia³a³y ju¿ podczas bulk insert 
);

-- wgrywam dane do tabeli poœrednicz¹cej SprzetKategoria
BULK INSERT Sprzet.SprzetKategoria
FROM 'C:\data\sprzet_kategoria.csv'
WITH (
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n',  
    CODEPAGE = '65001',     -- Kodowanie UTF-8
    FIRSTROW = 2,
	FIRE_TRIGGERS			-- chcê, aby triggery zadzia³a³y ju¿ podczas bulk insert 
);

-- wgrywam dane do tabeli egzemplarze
BULK INSERT Sprzet.Egzemplarz
FROM 'C:\data\egzemplarze.csv'
WITH (
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = ';', 
    ROWTERMINATOR = '\n',  
    CODEPAGE = '65001',     -- Kodowanie UTF-8
    FIRSTROW = 1,
	FIRE_TRIGGERS			-- chcê, aby triggery zadzia³a³y ju¿ podczas bulk insert 
);

-- wstawiam dane do encji Zamówienia
BULK INSERT Zamowienia.Zamowienie
FROM 'C:\data\zamowienia.csv'
WITH (
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = ';', 
    ROWTERMINATOR = '\n',  
    CODEPAGE = '65001',     -- Kodowanie UTF-8
    FIRSTROW = 2,
	FIRE_TRIGGERS			-- chcê, aby triggery zadzia³a³y ju¿ podczas bulk insert 
);

-- wstawiam dane do encji zamówienie egzemplarz
BULK INSERT Zamowienia.ZamowienieEgzemplarz
FROM 'C:\data\zamowienia_szczegolowo.csv'
WITH (
    DATAFILETYPE = 'char',
    FIELDTERMINATOR = ';', 
    ROWTERMINATOR = '\n',  
    CODEPAGE = '65001',     -- Kodowanie UTF-8
    FIRSTROW = 1
);

-- encja Reklamacje
BULK INSERT Serwis.Reklamacja
FROM 'C:\data\reklamacje.csv'
WITH (
	DATAFILETYPE = 'char',
    FIELDTERMINATOR = ';', 
    ROWTERMINATOR = '\n',  
    CODEPAGE = '65001',   
    FIRSTROW = 2
);

-- encja Reklamacje
BULK INSERT Serwis.ReklamacjaEgzemplarz
FROM 'C:\data\reklamacje_szczegolowo.csv'
WITH (
	DATAFILETYPE = 'char',
    FIELDTERMINATOR = ';', 
    ROWTERMINATOR = '\n',  
    CODEPAGE = '65001',   
    FIRSTROW = 2
);

