USE Wypozyczalnia;
GO

-- Zapytania określone w projekcie. Wykonam je w postaci procedur składowanych. W ten spsób użytkownik będzie mógł w łatwy sposób wywołać potrzebne informacje. 
-- Jednocześnie zwiększe bezpieczeństwo i integralność danych, nie dając użytkownikowi bezpośredniego dostępu do bazy.

-- 1. wybór pracownika miesiąca czyli takiego, który obsłużył najwięcej zamówień w danym okresie czasu.
CREATE PROCEDURE Osoby.PracownikMiesiaca
	@Od date,
	@Do date
AS
BEGIN
	SELECT
		TOP 1 p.pracownik_id AS pracownik_id,
		CONCAT(o.imie, ' ', o.nazwisko) AS N'imię i nazwisko',
		COUNT(z.zamowienie_id) AS N'liczba zamówień'
	FROM Osoby.Pracownik AS p
	JOIN Zamowienia.Zamowienie AS z ON z.pracownik_id = p.pracownik_id
	JOIN Osoby.Osoba AS o ON o.osoba_id = p.osoba_id
	WHERE z.data_zamowienia BETWEEN @Od AND @Do  -- zakres dat ustalony przez parametr
	GROUP BY p.pracownik_id, o.imie, o.nazwisko
	ORDER BY COUNT(z.zamowienie_id) DESC; 
END;

GO 

-- 2. generowanie raportów o zamówieniach danego klienta w zadanym okresie czasu.
CREATE PROCEDURE Zamowienia.ZamowieniaKlienta
	@KlientId int,
	@Od date,
	@Do date
AS
BEGIN
	SELECT
		z.zamowienie_id,
		z.cena_calkowita,
		z.pracownik_id AS opiekun,
		z.data_zamowienia
	FROM Zamowienia.Zamowienie AS z
	JOIN Osoby.Klient AS k ON k.klient_id = z.klient_id
	WHERE (z.data_zamowienia BETWEEN @Od AND @Do) AND k.klient_id = @KlientId;
END;

GO

-- 3. wyświetlenie rankingu sprzętu w danej kategorii
CREATE PROCEDURE Sprzet.Ranking
	@KategoriaId int
AS
BEGIN
	SELECT
		k.nazwa as Kategoria,
		sk.ranking as Miejsce,
		s.nazwa as 'Nazwa Sprzętu'
	FROM Sprzet.SprzetKategoria sk
	JOIN Sprzet.Sprzet s ON s.sprzet_id = sk.sprzet_id
	JOIN Kategorie.Kategoria k ON k.kategoria_id = sk.kategoria_id
	WHERE sk.kategoria_id = 9
	ORDER BY sk.ranking ASC;
END;

-- 4. znalezienie sprzętu, które zajmuje średnio najwyższe miejsce we wszystkich rankingach
CREATE PROCEDURE Sprzet.AvgRanking
AS
BEGIN
	SELECT
		s.sprzet_id AS ID,
		s.nazwa AS nazwa_artykuły,
		FORMAT(AVG(CAST(sk.ranking AS decimal(10,4))), 'N2') AS sredni_ranking -- wprowadzam nieco bardziej czytelne formatowanie. Jednak rzutuje to decimal na varchar.
	FROM Sprzet.SprzetKategoria sk
	JOIN Sprzet.Sprzet s ON s.sprzet_id = sk.sprzet_id
	JOIN Kategorie.Kategoria k ON k.kategoria_id = sk.kategoria_id
	GROUP BY s.sprzet_id, s.nazwa
	ORDER BY AVG(CAST(sk.ranking AS decimal(10,4))) ASC; -- w celu poprawnego działania, eliminuję funkcję FORMAT() która powodowała rzutowanie
END;

GO 

-- 5. dodanie nowego sprzętu (z podaniem nazwy i typu)
-- Procedurę projektuję transakcyjnie w celu zapewnienia integralności danych
CREATE PROCEDURE Sprzet.DodajSprzet
    @Nazwa NVARCHAR(100),
    @Profesjonalny BIT,
    @Typ NVARCHAR(20),
    @CenaZaDobe DECIMAL(8,2),
    @ProducentId INT,
    @Rabat DECIMAL(5,2) = 0.00,		-- domyślnie 0.00
    @Opis NVARCHAR(255) = NULL,		-- domyślnie NULL
    @KategoriaId INT,
    @Ranking INT
AS
BEGIN
	BEGIN TRANSACTION -- chcę, aby wykonały się wszystkie instrukcje albo żadna
		BEGIN TRY
				-- Dodanie nowego sprzętu do tabeli Sprzet.Sprzet
				INSERT INTO Sprzet.Sprzet (nazwa, cena_za_dobe, profesjonalny, rabat, opis, producent_id)
				VALUES (@Nazwa, @CenaZaDobe, @Profesjonalny, @Rabat, @Opis, @ProducentId);

				-- Pobranie ID ostatnio dodanego sprzętu
				DECLARE @SprzetId INT;
				SET @SprzetId = SCOPE_IDENTITY();	-- pobieram ID sprzętu wstawionego powyżej

				-- dodaje sprzęt do tabeli SprzetKategoria w celu nadania mu kategorii
				IF (@KategoriaId IS NOT NULL)
				BEGIN
					INSERT INTO Sprzet.SprzetKategoria (sprzet_id, kategoria_id, ranking)
					VALUES (@SprzetId, @KategoriaId, @Ranking);
				END
			COMMIT TRANSACTION
		END TRY
    BEGIN CATCH
		ROLLBACK TRANSACTION -- cofam transakcję, jeżeli wystąpił chodziaż jeden błąd
        
		-- obsługa błędów
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN;
    END CATCH
END;

-- 6. wygenerowanie zestawienia wszystkich pracowników i ich szefów
CREATE PROCEDURE Osoby.ZestawieniePracownikow
AS
BEGIN
	SELECT 
		p.pracownik_id,
		CONCAT(o.imie, ' ', o.nazwisko) AS pracownik,
		p2.pracownik_id AS przelozony_id,
		CONCAT(o2.imie, ' ', o2.nazwisko) AS przelozony
	FROM Osoby.Pracownik p
	JOIN Osoby.Osoba o ON o.osoba_id = p.osoba_id
	-- self join z tabelą pracownik w celu uzyskania danych o przełożonym
	LEFT JOIN Osoby.Pracownik p2 ON p2.pracownik_id = p.przelozony_id
	-- ponowny join z tabelą osoba aby pobrać dane osobowe przełożonego
	LEFT JOIN Osoby.Osoba o2 ON p2.osoba_id = o2.osoba_id
	ORDER BY p.pracownik_id;
END;

/*7. otrzymanie opisu dla każdego rodzaju sprzętu, przy czym dla sprzętu górskiego opis ma uwzględniać nazwę, 
nazwę producenta, oraz porę roku w jakim sprzętu można używać, natomiast dla wodnego - nazwę, nazwę producenta, oraz informację o patencie
Komentarz: nie dodaję obsługi błedów, ponieważ nie spodziewam się, żeby wystąpiły. Nie mniej w prawdziwym projekcie, należałoby to dodać*/
CREATE PROCEDURE Sprzet.OpisSprzetu
AS
BEGIN
	SELECT
		s.nazwa AS Sprzęt,
		p.nazwa AS Producent,
		k.nazwa AS Kategoria,
		CASE
			WHEN k.kategoria_id = 8 THEN
				pr.nazwa -- nazwa pory roku jeżeli kategoria = 8 (czyli górski)
			ELSE
				NULL
		END AS 'Pora roku',
		CASE
			WHEN k.kategoria_id = 9 THEN
				u.nazwa -- nazwa patentu dla kategorii 9 (wodny)
			ELSE
				NULL
		END AS Patent
	FROM Sprzet.Sprzet s
	JOIN Sprzet.Producent p ON s.producent_id = p.producent_id
	JOIN Sprzet.SprzetKategoria sk ON s.sprzet_id = sk.sprzet_id
	JOIN Kategorie.Kategoria k ON sk.kategoria_id = k.kategoria_id
	LEFT JOIN Sprzet.Uprawnienie u ON u.uprawnienie_id = k.uprawnienie_id 
	LEFT JOIN Kategorie.KategoriaPoraRoku kpr ON kpr.kategoria_id = k.kategoria_id 
	LEFT JOIN Kategorie.PoraRoku pr ON pr.pora_roku_id = kpr.pora_roku_id
	WHERE k.kategoria_id IN (8, 9)
	ORDER BY k.nazwa, s.nazwa;
END;
