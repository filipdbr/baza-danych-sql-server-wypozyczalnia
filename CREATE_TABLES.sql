USE Wypozyczalnia;
GO

-- encja 'Osoba'
CREATE TABLE Osoby.Osoba (
	
	-- Atrybuty
    osoba_id INT IDENTITY(1,1) NOT NULL,
    imie NVARCHAR(25) NOT NULL,
    nazwisko NVARCHAR(50) NOT NULL,
    telefon VARCHAR(15) NOT NULL,
    
	-- Klucz g��wny
    CONSTRAINT Osoba_pk PRIMARY KEY (osoba_id),
	
	-- Ograniczenia
    CHECK (LEN(imie) >= 2),
    CHECK (LEN(nazwisko) >= 2),
    CHECK (LEN(telefon) >= 7 AND LEN(telefon) <= 15),
	CHECK (telefon NOT LIKE '%[^0-9]%') -- telefon mo�e sk�ada� si� jedynie z cyfr
);

-- encja 'Klient'
CREATE TABLE Osoby.Klient (
	
	-- Atrybuty
	klient_id INT IDENTITY(1,1) NOT NULL,
	firma nvarchar(50),
	nip varchar(10),
	osoba_id INT NOT NULL,
	data_utworzenia date DEFAULT GETDATE(),

	-- Klucz g��wny i klucz obcy
	CONSTRAINT Klient_pk PRIMARY KEY (klient_id),	
	CONSTRAINT Osoba_fk FOREIGN KEY (osoba_id) REFERENCES Osoby.Osoba(osoba_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE, -- je�eli usuniemy osob�, chc� usun�� wszystkie rekordy z ni� zwi�zne
	
	-- Ograniczenia
	CHECK (firma IS NULL OR LEN(firma) >= 3)
);

-- encja 'Stanowisko'
CREATE TABLE Osoby.Stanowisko(

	-- Atrybuty
	stanowisko_id INT IDENTITY(1,1) NOT NULL,
	nazwa nvarchar(50) NOT NULL,

	-- Klucz g��wny
	CONSTRAINT Stanowisko_pk PRIMARY KEY (stanowisko_id),

	-- Ograniczenia
	CHECK(LEN(nazwa) > 3),
	CONSTRAINT Stanowisko_nazwa_uk UNIQUE (nazwa)
);

-- encja 'Status Zatrudnienia'
CREATE TABLE Osoby.StatusZatrudnienia (
    
	-- Atrybuty
    status_zatrudnienia_id INT IDENTITY(1,1) NOT NULL,
    nazwa_statusu NVARCHAR(30) NOT NULL,

    -- Klucz g��wny
    CONSTRAINT Status_zatrudnienia_pk PRIMARY KEY (status_zatrudnienia_id),

    -- Ograniczenia
    CHECK (LEN(nazwa_statusu) > 3 AND nazwa_statusu NOT LIKE '%[^A-Za-z]%')
);



-- encja 'Pracownik'
CREATE TABLE Osoby.Pracownik (
    
	-- Atrybuty
    pracownik_id INT IDENTITY(1,1) NOT NULL,
    przelozony_id INT DEFAULT 1,
    stanowisko_id INT DEFAULT 7 NOT NULL,
    pesel VARCHAR(11),
    adres NVARCHAR(100) NOT NULL,
    data_zatrudnienia DATE NOT NULL,
    status_zatrudnienia INT DEFAULT 1 NOT NULL,
    osoba_id INT,

    -- Klucze
    CONSTRAINT Pracownik_pk PRIMARY KEY (pracownik_id),
    CONSTRAINT Pracownik_Prze�o�ony_fk FOREIGN KEY (przelozony_id) REFERENCES Osoby.Pracownik(pracownik_id)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION, -- logika zostanie obs�u�na przez wyzwalacz
    CONSTRAINT Pracownik_Stanowisko_fk FOREIGN KEY (stanowisko_id) REFERENCES Osoby.Stanowisko(stanowisko_id)
		ON UPDATE CASCADE
		ON DELETE SET DEFAULT, -- domy�lnie stworzone jest stanowisko o ID 7, kt�ry nazywa si� "do aktualizacji".
    CONSTRAINT Pracownik_Osoba_fk FOREIGN KEY (osoba_id) REFERENCES Osoby.Osoba(osoba_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
    CONSTRAINT Pracownik_Status_fk FOREIGN KEY (status_zatrudnienia) REFERENCES Osoby.StatusZatrudnienia(status_zatrudnienia_id)
		ON UPDATE CASCADE
		ON DELETE SET DEFAULT,

    -- Ograniczenia
	-- mo�e by� tylko 1 kierownik g��wny - zostanie to obs�u�one przez trigger.
	-- tylko kierownik g�. mo�e nie mie� prze�o�onego - zostanie to obs�u�one przez trigger.
    CHECK (pesel IS NULL OR (LEN(pesel) = 11 AND pesel NOT LIKE '%[^0-9]%')),
    CHECK (LEN(adres) >= 5),
    CHECK (data_zatrudnienia >= '2001-01-01'),
);

CREATE INDEX index_przelozony ON Osoby.Pracownik(przelozony_id); -- do obs�ugi wyszukiwa� pracownik�w prze�o�onego
CREATE UNIQUE INDEX UQ_Pracownik_Pesel ON Osoby.Pracownik(pesel) WHERE pesel IS NOT NULL; -- w ten spos�b uzyskam unikaln� warto�c pesel lub wiele warto�ci null


-- encja 'Zam�wienie'
CREATE TABLE Zamowienia.Zamowienie(
	
	-- Atrybuty
	zamowienie_id INT IDENTITY(1,1) NOT NULL,
	cena_calkowita decimal(8,2) NOT NULL,
	klient_id INT NOT NULL,
	pracownik_id INT DEFAULT 1 NOT NULL,
	data_zamowienia DATE NOT NULL,

	-- Klucze
	CONSTRAINT Zamowienie_pk PRIMARY KEY (zamowienie_id),
	CONSTRAINT Klient_Zmowienie_fk FOREIGN KEY (klient_id) REFERENCES Osoby.Klient(klient_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
	CONSTRAINT Pracownik_Zamowienie_fk FOREIGN KEY (pracownik_id) REFERENCES Osoby.Pracownik(pracownik_id)
		ON UPDATE NO ACTION		-- obs�u�one zostanie przez procedur� sk�adowan�
		ON DELETE NO ACTION,	-- obs�u�one zostanie przez procedur� sk�adowan�

	-- Ograniczenia
	CHECK (cena_calkowita > 0.00)
);

-- tworz� indexy dla encji 'Zamowienie'
CREATE INDEX index_klient_id On Zamowienia.Zamowienie(klient_id); -- bedziemy szuka� liczby zam�wie� klient�w
CREATE INDEX index_pracownik_id ON Zamowienia.Zamowienie(pracownik_id); -- b�dziemy szuka� pracownik�w z najwi�ksz� liczb� zam�wie�
CREATE INDEX index_zamowienie_i_data_zamowienia ON Zamowienia.Zamowienie(zamowienie_id, data_zamowienia); -- dla wyszukiwania zam�wie� w zakresie dat


/* nast�pnie musz� stworzy� encj� 'Producent' i tworzy� kolejne encje w kierunku 'Zam�wienie;.
Wynika to z tego, �e aby tworzy� FK w tabeli podrz�dnej, w pierwszej kolejno�ci musz� stworzy� tabele nadrz�dne.*/

-- encja 'Producent'
CREATE TABLE Sprzet.Producent (

    -- Atrybuty
    producent_id INT IDENTITY(1,1) NOT NULL,
    nazwa NVARCHAR(50) NOT NULL,
    email NVARCHAR(50) NOT NULL,
    telefon NVARCHAR(15) NOT NULL,
    jezyk NVARCHAR(15),
    data_utworzenia DATE DEFAULT GETDATE(),

    -- Klucze
    CONSTRAINT Producent_pk PRIMARY KEY (producent_id),

    -- Ograniczenia
    CHECK (LEN(nazwa) > 2 AND nazwa NOT LIKE '%[^A-Za-z0-9 ]%'),	-- dopuszczam w nazwie litery wielkie i ma�e, cyfry oraz spacj�
    CHECK (LEN(telefon) > 7 AND telefon NOT LIKE '%[^0-9]%'),		-- w numerze telefonu dopuszczam jedynie cyfry
    CHECK (LEN(jezyk) > 4 AND jezyk NOT LIKE '%[^A-Za-z]%')			-- w nazwie j�zyka dopuszczam litery wielkie i ma�e
);

-- Indeks na atrybucie nazwa: mo�liwe cz�stwe wyszukiwanie po nazwie producenta
CREATE INDEX index_producent_nazwa ON Sprzet.Producent(nazwa);

-- encja 'Sprzet'
CREATE TABLE Sprzet.Sprzet(
	
	-- Atrybuty
	sprzet_id INT IDENTITY(1,1) NOT NULL,
	nazwa nvarchar(100) NOT NULL,
	cena_za_dobe decimal(8,2) NOT NULL,
	profesjonalny BIT,
	rabat decimal(5,2),
	opis nvarchar(255),
	producent_id INT NOT NULL,

	-- Klucze
	CONSTRAINT Sprzet_pk PRIMARY KEY (sprzet_id),
	CONSTRAINT Producent_Sprzet_fk FOREIGN KEY (producent_id) REFERENCES Sprzet.Producent(producent_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,

	-- Ograniczenia
	CHECK(LEN(nazwa) > 3),
	CHECK(cena_za_dobe > 0.00),
	CHECK(rabat >= 0.00)

);

-- encja 'Egzemplarz'
CREATE TABLE Sprzet.Egzemplarz (
    
	-- Atrybuty
    egzemplarz_id INT IDENTITY(1,1) NOT NULL,
    wypozyczony BIT NOT NULL DEFAULT 0, -- Domy�lnie sprz�t nie jest wypo�yczony
    sprzet_id INT NOT NULL,

    -- Klucze
    CONSTRAINT Egzemplarz_pk PRIMARY KEY (egzemplarz_id),
    CONSTRAINT Sprzet_Egzemplarz_fk FOREIGN KEY (sprzet_id) REFERENCES Sprzet.Sprzet(sprzet_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

-- encja 'Reklamacja'
CREATE TABLE Sprzet.Reklamacja(
	
	-- Atrybuty
	reklamacja_id INT IDENTITY(1,1) NOT NULL,
	zamowienie_id INT NOT NULL,
	powod nvarchar(255) NOT NULL,
	data_reklamacji date NOT NULL,

	-- Klucze
	CONSTRAINT Reklamacja_pk PRIMARY KEY (reklamacja_id),
	CONSTRAINT Reklamacja_Zamowienie_fk FOREIGN KEY (zamowienie_id) REFERENCES Zamowienia.Zamowienie(zamowienie_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

-- encja zawieraj�ca statusy reklamacji
CREATE TABLE Sprzet.StatusReklamacji(

	-- Atrybuty
	status_reklamacji_id INT IDENTITY (1,1) NOT NULL,
	nazwa nvarchar(20) UNIQUE NOT NULL,

	-- Klucz g��wny
	CONSTRAINT StatusReklamacji_pk PRIMARY KEY (status_reklamacji_id)

);

-- encja asocjacyjna dla encji Reklamacja i Egzemplarz. Konieczna, poniewa� jedna reklamacja mo�e dotyczy� wielu egzemplarzy
CREATE TABLE Sprzet.ReklamacjaEgzemplarz(

	-- Atrybuty
	reklamacja_egzemplarz_id INT IDENTITY (1,1) NOT NULL,
	reklamacja_id INT NOT NULL,
	egzemplarz_id INT NOT NULL,
	status_reklamacji INT NOT NULL,

	-- Klucze
	CONSTRAINT ReklamacjaEgzemplarz_pk PRIMARY KEY (reklamacja_egzemplarz_id),
	CONSTRAINT Reklamacja_ReklamacjaEgzemplarz_fk FOREIGN KEY (reklamacja_id) REFERENCES Sprzet.Reklamacja(reklamacja_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
	CONSTRAINT Egzemplarz_ReklamacjaEgzemplarz_fk FOREIGN KEY (egzemplarz_id) REFERENCES Sprzet.Egzemplarz(egzemplarz_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
	CONSTRAINT StatusReklamacji_ReklamacjaEgzemplarz_fk FOREIGN KEY (status_reklamacji) REFERENCES Sprzet.StatusReklamacji(status_reklamacji_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,

);

-- encja 'Naprawa'
CREATE TABLE Sprzet.Naprawa (
    
	-- Atrybuty
    naprawa_id INT IDENTITY(1,1) NOT NULL,
    data_zgloszenia DATE DEFAULT GETDATE(),
    termin_ukonczenia DATE DEFAULT NULL,
    powod VARCHAR(255),
    koszt_naprawy DECIMAL(8,2) CHECK (koszt_naprawy >= 0.00) DEFAULT NULL,
    egzemplarz_id INT NOT NULL,
	id_reklamacja_egzemplarz INT

    -- Klucze
    CONSTRAINT Naprawa_pk PRIMARY KEY (naprawa_id),
    CONSTRAINT Egzemplarz_Naprawa_fk FOREIGN KEY (egzemplarz_id) REFERENCES Sprzet.Egzemplarz(egzemplarz_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
	CONSTRAINT ReklamacjaEgzemplarz_Naprawa_fk FOREIGN KEY (id_reklamacja_egzemplarz) REFERENCES Sprzet.ReklamacjaEgzemplarz(id_reklamacja_egzemplarz)
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,

    -- Ograniczenia
    CHECK (termin_ukonczenia IS NULL OR termin_ukonczenia >= data_zgloszenia)
);

-- encja asocjacyjna 'ZamowienieEgzemplarz'
CREATE TABLE Zamowienia.ZamowienieEgzemplarz (

	-- Atrybuty
	zamowienie_id INT NOT NULL,
	egzemplarz_id INT NOT NULL,
	data_zwrotu DATE NOT NULL,

	-- Klucze
	CONSTRAINT ZamowienieEgzemplarz_pk PRIMARY KEY (zamowienie_id, egzemplarz_id),
	CONSTRAINT Zamowienie_ZamowienieEgzemplarz_fk FOREIGN KEY (zamowienie_id) REFERENCES Zamowienia.Zamowienie(zamowienie_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE, -- w przypadku usuni�cia rekodu w tabeli nadrz�dnej usuwam wszystkie rekory r�wnie� w tej tabeli
	CONSTRAINT Egzemplarz_ZamowienieEgzemplarz_fk FOREIGN KEY (egzemplarz_id) REFERENCES Sprzet.Egzemplarz(egzemplarz_id)
		ON UPDATE NO ACTION		-- obs�u�one zostanie przez procedur� sk�adowan�
		ON DELETE NO ACTION,	-- w przypadku usuni�cia rekordu egzemplarz_id w tabeli nadrz�dnej zarz�dz� logik� poprzez wyzwalacz
	CONSTRAINT ZamowienieEgzemplarz_UNIQUE UNIQUE (zamowienie_id, egzemplarz_id)	-- brak mo�liwo�ci wstawienia do zam�wienia tego samego egzemplarza 2 razy 

);

-- Encja 'Uprawnienie'
CREATE TABLE Sprzet.Uprawnienie (

	-- Atrybuty
    uprawnienie_id INT IDENTITY(1,1) NOT NULL,
    nazwa NVARCHAR(100) NOT NULL,

    -- Klucze
    CONSTRAINT Uprawnienie_pk PRIMARY KEY (uprawnienie_id)
);

-- Encja 'Sprz�t profesjonalny' przechowuj�ca jedynie te modele, kt�re klasyfikowane s� jako profesjonalne
CREATE TABLE Sprzet.SprzetProfesjonalny (

	-- Atrybuty
    sprzet_id INT NOT NULL,
    uprawnienie_id INT,

    -- Klucze
    CONSTRAINT SprzetProfesjonalny_pk PRIMARY KEY (sprzet_id, uprawnienie_id),
    CONSTRAINT Sprzet_SprzetProfesjonalny_fk FOREIGN KEY (sprzet_id) REFERENCES Sprzet.Sprzet(sprzet_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
    CONSTRAINT Uprawnienie_SprzetProfesjonalny_fk FOREIGN KEY (uprawnienie_id) REFERENCES Sprzet.Uprawnienie(uprawnienie_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

-- Encja 'Kategoria' przechowuj�ce informace o kategoriach sprz�tu w systemie
CREATE TABLE Kategorie.Kategoria (

	-- Atrybuty
    kategoria_id INT IDENTITY(1,1) NOT NULL,
    nazwa NVARCHAR(50) NOT NULL,
    wymaga_patentu BIT NOT NULL,

    -- Klucze
    CONSTRAINT Kategoria_pk PRIMARY KEY (kategoria_id)
);

-- Encja asocjacyjna dla encji 'Sprzet' i 'Kategoria'. Pozwala obs�u�y� relacj� wiele-do-wielu. Dodatkowo wprowadza ranking.
CREATE TABLE Sprzet.SprzetKategoria (

	-- Atrybuty
    sprzet_id INT NOT NULL,
    kategoria_id INT DEFAULT 1 NOT NULL,
    ranking INT NOT NULL,

    -- Klucze
    CONSTRAINT SprzetKategoria_pk PRIMARY KEY (sprzet_id, kategoria_id),
    CONSTRAINT Sprzet_SprzetKategoria_fk FOREIGN KEY (sprzet_id) REFERENCES Sprzet.Sprzet(sprzet_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
    CONSTRAINT Kategoria_SprzetKategoria_fk FOREIGN KEY (kategoria_id) REFERENCES Kategorie.Kategoria(kategoria_id)
		ON UPDATE CASCADE
		ON DELETE SET DEFAULT,

	-- Ograniczenia
	CONSTRAINT Ranking_uq UNIQUE (kategoria_id, ranking), -- w rankingu nie mo�e by� miejsc ex aequo. Kombinacja miejsce ranking musi by� unikatowa
	CHECK (ranking >= 1)
);

CREATE INDEX index_ranking_kategoria ON Sprzet.SprzetKategoria(kategoria_id, ranking);
CREATE INDEX index_sprzet_kategoria ON Sprzet.SprzetKategoria(sprzet_id);
CREATE INDEX index_kategoria_sprzetkategoria ON Sprzet.SprzetKategoria(kategoria_id);


-- Encja 'PoraRoku'. Dopuszam inne nazwy p�r roku ni� standrdowe 4, st�d brak ogranicze�. Mo�e by� to np. przedwio�nie.
CREATE TABLE Kategorie.PoraRoku (

	-- Atrybuty
    pora_roku_id INT IDENTITY(1,1) NOT NULL,
    nazwa NVARCHAR(20) NOT NULL,

    -- Klucze
    CONSTRAINT PoraRoku_pk PRIMARY KEY (pora_roku_id)
);

-- Kolejna tabela po�rednicz�ca, tym razem dla Pory Roku i Kategorii. Kategoria, mo�e by� przypisana do wielu p�r roku. 
CREATE TABLE Kategorie.KategoriaPoraRoku (

	-- Atrybuty
    kategoria_id INT NOT NULL,
    pora_roku_id INT DEFAULT 1 NOT NULL,

    -- Klucze
    CONSTRAINT KategoriaPoraRoku_pk PRIMARY KEY (kategoria_id, pora_roku_id),
    CONSTRAINT Kategoria_KategoriaPoraRoku_fk FOREIGN KEY (kategoria_id) REFERENCES Kategorie.Kategoria(kategoria_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
    CONSTRAINT PoraRoku_KategoriaPoraRoku_fk FOREIGN KEY (pora_roku_id) REFERENCES Kategorie.PoraRoku(pora_roku_id)
		ON UPDATE CASCADE
		ON DELETE SET DEFAULT
);
