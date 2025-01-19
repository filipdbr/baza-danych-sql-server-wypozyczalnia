USE Wypozyczalnia;
GO

-- Zapytania określone w projekcie:

-- 1. wybór pracownika miesiąca czyli takiego, który obsłużył najwięcej zamówień w danym okresie czasu.
SELECT
    TOP 1 p.pracownik_id AS ID_Pracownika,
    CONCAT(o.imie, ' ', o.nazwisko) AS Pracownik,
    COUNT(z.zamowienie_id) AS 'Liczba obsłużonych zamówień'
FROM Osoby.Pracownik AS p
JOIN Zamowienia.Zamowienie AS z ON z.pracownik_id = p.pracownik_id
JOIN Osoby.Osoba AS o ON o.osoba_id = p.osoba_id
WHERE z.data_zamowienia BETWEEN '2023-06-01' AND '2023-06-30'  -- zakres dat: czerwiec 2023
GROUP BY p.pracownik_id, o.imie, o.nazwisko
ORDER BY COUNT(z.zamowienie_id) DESC;  

-- 2. generowanie raportów o zamówieniach danego klienta w zadanym okresie czasu.
SELECT
	z.zamowienie_id,
	z.cena_calkowita,
	z.pracownik_id AS opiekun,
	z.data_zamowienia AS N'data zamówienia'
FROM Zamowienia.Zamowienie AS z
JOIN Osoby.Klient AS k ON k.klient_id = z.klient_id
WHERE (z.data_zamowienia BETWEEN '2023-01-01' AND '2024-01-01') AND k.klient_id = 5;

-- 3. wyświetlenie rankingu sprzętu w danej kategorii
SELECT
	k.nazwa,
	sk.ranking,
	s.nazwa
FROM Sprzet.SprzetKategoria sk
JOIN Sprzet.Sprzet s ON s.sprzet_id = sk.sprzet_id
JOIN Kategorie.Kategoria k ON k.kategoria_id = sk.kategoria_id
WHERE sk.kategoria_id = 1
ORDER BY sk.ranking ASC;

-- 4. znalezienie sprzętu, które zajmuje średnio najwyższe miejsce we wszystkich rankingach
SELECT
    s.sprzet_id AS ID,
	s.nazwa AS nazwa_artykuły,
    FORMAT(AVG(CAST(sk.ranking AS decimal(10,4))), 'N2') AS sredni_ranking
FROM Sprzet.SprzetKategoria sk
JOIN Sprzet.Sprzet s ON s.sprzet_id = sk.sprzet_id
JOIN Kategorie.Kategoria k ON k.kategoria_id = sk.kategoria_id
GROUP BY s.sprzet_id, s.nazwa
ORDER BY AVG(CAST(sk.ranking AS decimal(10,4))) ASC;

-- 5. dodanie nowego sprzętu (z podaniem nazwy i typu)

-- 6. wygenerowanie zestawienia wszystkich pracowników i ich szefów
SELECT 
	p.pracownik_id,
	CONCAT(o.imie, ' ', o.nazwisko) AS pracownik,
	p2.pracownik_id AS przelozony_id,
	CONCAT(o2.imie, ' ', o2.nazwisko) AS przelozony
FROM Osoby.Pracownik p
JOIN Osoby.Osoba o ON o.osoba_id = p.osoba_id
LEFT JOIN Osoby.Pracownik p2 ON p2.pracownik_id = p.przelozony_id
LEFT JOIN Osoby.Osoba o2 ON p2.osoba_id = o2.osoba_id
ORDER BY p.pracownik_id

/*7. otrzymanie opisu dla każdego rodzaju sprzętu, przy czym dla sprzętu górskiego opis ma uwzględniać nazwę, 
nazwę producenta, oraz porę roku w jakim sprzętu można używać, natomiast dla wodnego - nazwę, nazwę producenta, oraz informację o patencie*/
SELECT *
FROM Sprzet.Sprzet