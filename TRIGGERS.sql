USE Wypozyczalnia;
GO

-- Tworzê trigerry które pomagaj¹ wprowadziæ dodatkow¹ logikê, której nie uda³o mi siê osi¹gn¹æ poprzez relacje oraz CHECK()

-- mo¿e byæ tylko 1 kierownik g³ówny (ID 1 w tabeli Osoby.Stanowisko)
-- pracownik nie mo¿e byæ swoim w³asnym prze³o¿onym
CREATE TRIGGER trg_walidacja_pracownik_stanowisko
ON Osoby.Pracownik
AFTER INSERT, UPDATE
AS
BEGIN
    -- Sprawdzenie, czy wiêcej ni¿ jeden pracownik ma stanowisko_id = 1 i przelozony_id IS NULL
    IF EXISTS (
        SELECT 1
        FROM Osoby.Pracownik
        WHERE stanowisko_id = 1 AND przelozony_id IS NULL
        GROUP BY stanowisko_id
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR ('Tylko jeden pracownik o stanowisku_id = 1 mo¿e mieæ przelozony_id IS NULL.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Sprawdzenie, czy pracownicy z innymi stanowiskami maj¹ przelozony_id IS NULL
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE stanowisko_id != 1 AND przelozony_id IS NULL
    )
    BEGIN
        RAISERROR ('Pracownicy z innymi stanowiskami ni¿ stanowisko_id = 1 musz¹ mieæ przypisanego prze³o¿onego.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Sprawdzenie, czy jakikolwiek pracownik jest swoim w³asnym prze³o¿onym
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE pracownik_id = przelozony_id
    )
    BEGIN
        RAISERROR ('Pracownik nie mo¿e byæ swoim w³asnym prze³o¿onym.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;



-- Automatyczne dodawanie sprzêtu do tabeli 'SprzetProfesjonalny' w przypadku wprowadzenia 1 w polu "profesjonalny"
CREATE TRIGGER trg_Autododatnie_Profesjonalny
ON Sprzet.Sprzet
AFTER INSERT
AS
BEGIN
    -- Dodajê rekord do tabeli 'SprzetProfesjonalny'
    INSERT INTO Sprzet.SprzetProfesjonalny (sprzet_id, uprawnienie_id)
    SELECT 
        i.sprzet_id,
        u.uprawnienie_id 
    FROM inserted AS i
    CROSS APPLY (
        -- przypisujê uprawnienie 1, które bêdzie nosiæ nazwê 'do aktualizacji'
        SELECT uprawnienie_id 
        FROM Sprzet.Uprawnienie
        WHERE uprawnienie_id = 1
    ) AS u
    WHERE i.profesjonalny = 1; -- tylko dla profesjonalnego sprzêtu
END;

GO

-- Wyzwalacz kontroluj¹cy, czy nie przekraczamy maksymalnego zamówienia, które wynosi 5 egemplarzy
CREATE TRIGGER trg_Max_Zamowienie
ON Zamowienia.ZamowienieEgzemplarz
AFTER INSERT, UPDATE
AS
BEGIN
    -- Deklarujê zmienn¹ do przechowywania liczby egzemplarzy dla danego zamówienia
    DECLARE @ilosc INT;
    
    -- Sprawdzam liczbê egzemplarzy przypisanych do tego zamówienia
    SELECT @ilosc = COUNT(DISTINCT egzemplarz_id) -- Liczymy ró¿ne egzemplarze
    FROM Zamowienia.ZamowienieEgzemplarz
    WHERE zamowienie_id IN (SELECT zamowienie_id FROM inserted); -- U¿ywamy zamowienie_id z danych wstawianych/aktualizowanych

    -- Jeœli liczba egzemplarzy przekracza 5, cofam transakcjê
    IF @ilosc > 5
    BEGIN
        RAISERROR ('Zamówienie nie mo¿e przekraczaæ 5 egzemplarzy.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;


GO

-- wyzwalacz akutalizuj¹cy zamówienia, je¿eli dochodzi do aktualizacji danych pracownika
CREATE TRIGGER trg_Aktualizaca_Pracownik
ON Osoby.Pracownik
AFTER UPDATE
AS
BEGIN
	IF EXISTS (
		SELECT 1
		FROM inserted AS i
		JOIN Zamowienia.Zamowienie AS z ON i.pracownik_id = z.pracownik_id
		)
	BEGIN
		UPDATE Zamowienia.Zamowienie
		SET pracownik_id = i.pracownik_id
		FROM inserted i
		WHERE Zamowienia.Zamowienie.pracownik_id = i.pracownik_id;
	END
END;

GO


-- Pomys³y i æwiczenia: 
-- trigger automarycznie ustawiaj¹cy datê zwortu
-- trigger dla zmiany statusu egzemplarz na wypo¿yczony
-- trigger dla automatycznego ustawienia data_zgloszenia w tabeli Naprawa
-- Trigger dla automatycznego usuwania ZamowienieEgzemplarz po zwrocie