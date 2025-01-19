USE Wypozyczalnia;
GO

EXEC Osoby.PracownikMiesiaca @Od = '2023-07-01', @Do = '2023-07-30';

EXEC Zamowienia.ZamowieniaKlienta @KlientId = 44, @Od = '2023-06-01', @Do = '2024-06-01';

