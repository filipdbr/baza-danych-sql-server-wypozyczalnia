USE Wypozyczalnia;
GO

-- Tworz� trigerry kt�re pomagaj� wprowadzi� dodatkow� logik�, kt�rej nie uda�o mi si� osi�gn�� poprzez relacje oraz CHECK()

-- mo�e by� tylko 1 kierownik g��wny (ID 1 w tabeli Osoby.Stanowisko)
-- pracownik nie mo�e by� swoim w�asnym prze�o�onym
CREATE TRIGGER trg_walidacja_pracownik_stanowisko
ON Osoby.Pracownik
AFTER INSERT, UPDATE
AS
BEGIN
    -- Sprawdzenie, czy wi�cej ni� jeden pracownik ma stanowisko_id = 1 i przelozony_id IS NULL
    IF EXISTS (
        SELECT 1
        FROM Osoby.Pracownik
        WHERE stanowisko_id = 1 AND przelozony_id IS NULL
        GROUP BY stanowisko_id
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR ('Tylko jeden pracownik o stanowisku_id = 1 mo�e mie� przelozony_id IS NULL.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Sprawdzenie, czy pracownicy z innymi stanowiskami maj� przelozony_id IS NULL
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE stanowisko_id != 1 AND przelozony_id IS NULL
    )
    BEGIN
        RAISERROR ('Pracownicy z innymi stanowiskami ni� stanowisko_id = 1 musz� mie� przypisanego prze�o�onego.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Sprawdzenie, czy jakikolwiek pracownik jest swoim w�asnym prze�o�onym
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE pracownik_id = przelozony_id
    )
    BEGIN
        RAISERROR ('Pracownik nie mo�e by� swoim w�asnym prze�o�onym.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;



-- Automatyczne dodawanie sprz�tu do tabeli 'SprzetProfesjonalny' w przypadku wprowadzenia 1 w polu "profesjonalny"
CREATE TRIGGER trg_Autododatnie_Profesjonalny
ON Sprzet.Sprzet
AFTER INSERT
AS
BEGIN
    -- Dodaj� rekord do tabeli 'SprzetProfesjonalny'
    INSERT INTO Sprzet.SprzetProfesjonalny (sprzet_id, uprawnienie_id)
    SELECT 
        i.sprzet_id,
        u.uprawnienie_id 
    FROM inserted AS i
    CROSS APPLY (
        -- przypisuj� uprawnienie 1, kt�re b�dzie nosi� nazw� 'do aktualizacji'
        SELECT uprawnienie_id 
        FROM Sprzet.Uprawnienie
        WHERE uprawnienie_id = 1
    ) AS u
    WHERE i.profesjonalny = 1; -- tylko dla profesjonalnego sprz�tu
END;

GO

-- Wyzwalacz kontroluj�cy, czy nie przekraczamy maksymalnego zam�wienia, kt�re wynosi 5 egemplarzy
CREATE TRIGGER trg_Max_Zamowienie
ON Zamowienia.ZamowienieEgzemplarz
AFTER INSERT, UPDATE
AS
BEGIN
    -- Deklaruj� zmienn� do przechowywania liczby egzemplarzy dla danego zam�wienia
    DECLARE @ilosc INT;
    
    -- Sprawdzam liczb� egzemplarzy przypisanych do tego zam�wienia
    SELECT @ilosc = COUNT(DISTINCT egzemplarz_id) -- Liczymy r�ne egzemplarze
    FROM Zamowienia.ZamowienieEgzemplarz
    WHERE zamowienie_id IN (SELECT zamowienie_id FROM inserted); -- U�ywamy zamowienie_id z danych wstawianych/aktualizowanych

    -- Je�li liczba egzemplarzy przekracza 5, cofam transakcj�
    IF @ilosc > 5
    BEGIN
        RAISERROR ('Zam�wienie nie mo�e przekracza� 5 egzemplarzy.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;


GO

-- wyzwalacz akutalizuj�cy zam�wienia, je�eli dochodzi do aktualizacji danych pracownika
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


-- Pomys�y i �wiczenia: 
-- trigger automarycznie ustawiaj�cy dat� zwortu
-- trigger dla zmiany statusu egzemplarz na wypo�yczony
-- trigger dla automatycznego ustawienia data_zgloszenia w tabeli Naprawa
-- Trigger dla automatycznego usuwania ZamowienieEgzemplarz po zwrocie