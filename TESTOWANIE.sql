INSERT INTO Zamowienia.Zamowienie (cena_calkowita, klient_id, pracownik_id, data_zamowienia)
VALUES (539.63, 20, 6, '2023-04-19')


select *
from Zamowienia.Zamowienie

select
	z.zamowienie_id,
	COUNT(*) AS Egzemplarze
from Zamowienia.Zamowienie z
JOIN Zamowienia.ZamowienieEgzemplarz ze on ze.zamowienie_id = z.zamowienie_id
WHERE z.zamowienie_id = 300
GROUP BY z.zamowienie_id;


INSERT INTO Zamowienia.ZamowienieEgzemplarz 
(zamowienie_id, egzemplarz_id, data_zwrotu)
VALUES
(300, 1, '2024-01-01'),
(300, 2, '2024-01-01'),
(300, 3, '2024-01-01'),
(300, 4, '2024-01-01'),
(300, 5, '2024-01-01')

GO