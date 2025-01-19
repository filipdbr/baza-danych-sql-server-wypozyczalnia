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
		FORMAT(AVG(CAST(sk.ranking AS decimal(10,4))), 'N2') AS sredni_ranking
	FROM Sprzet.SprzetKategoria sk
	JOIN Sprzet.Sprzet s ON s.sprzet_id = sk.sprzet_id
	JOIN Kategorie.Kategoria k ON k.kategoria_id = sk.kategoria_id
	GROUP BY s.sprzet_id, s.nazwa
	ORDER BY AVG(CAST(sk.ranking AS decimal(10,4))) ASC;
END;

-- 5. dodanie nowego sprzętu (z podaniem nazwy i typu)


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
	LEFT JOIN Osoby.Pracownik p2 ON p2.pracownik_id = p.przelozony_id
	LEFT JOIN Osoby.Osoba o2 ON p2.osoba_id = o2.osoba_id
	ORDER BY p.pracownik_id;
END;

/*7. otrzymanie opisu dla każdego rodzaju sprzętu, przy czym dla sprzętu górskiego opis ma uwzględniać nazwę, 
nazwę producenta, oraz porę roku w jakim sprzętu można używać, natomiast dla wodnego - nazwę, nazwę producenta, oraz informację o patencie*/
CREATE PROCEDURE Sprzet.OpisSprzetu
AS
BEGIN
	SELECT
		s.nazwa AS Sprzęt,
		p.nazwa AS Producent,
		k.nazwa AS Kategoria,
		CASE
			WHEN k.kategoria_id = 8 THEN
				pr.nazwa -- Pora roku
			WHEN k.kategoria_id = 9 THEN
				u.nazwa -- Uprawnienie
			ELSE
				NULL
		END AS Opis
	FROM Sprzet.Sprzet s
	JOIN Sprzet.Producent p ON s.producent_id = p.producent_id
	JOIN Sprzet.SprzetKategoria sk ON s.sprzet_id = sk.sprzet_id
	JOIN Kategorie.Kategoria k ON sk.kategoria_id = k.kategoria_id
	LEFT JOIN Sprzet.Uprawnienie u ON u.uprawnienie_id = k.uprawnienie_id -- LEFT JOIN dla uprawnień
	LEFT JOIN Kategorie.KategoriaPoraRoku kpr ON kpr.kategoria_id = k.kategoria_id -- LEFT JOIN dla powiązań kategoria-pora roku
	LEFT JOIN Kategorie.PoraRoku pr ON pr.pora_roku_id = kpr.pora_roku_id -- LEFT JOIN dla pór roku
	WHERE k.kategoria_id IN (8, 9)
	ORDER BY k.nazwa, s.nazwa;
END;