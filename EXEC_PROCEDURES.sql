USE Wypozyczalnia;
GO

-- Zadanie 1: wywo�uj� pracedur� sk�adowan� PracownikMIesi�ca.
EXEC Osoby.PracownikMiesiaca @Od = '2023-07-01', @Do = '2023-07-31';

-- Zadanie 2: procedura sk�adowana Zam�wienia Klienta. Umo�liwia generowanie raport�w o zam�wieniach danego klienta w zadanym okresie czasu.
EXEC Zamowienia.ZamowieniaKlienta @KlientId = 45, @Od = '2023-06-01', @Do = '2024-06-01';

-- Zadanie 3: wy�wietlenie rankingu sprz�tu w danej kategorii, w tym przypadku kategoria o id 8, czyli 'wodny'
EXEC Sprzet.Ranking 7;

-- Zadanie 4: znalezienie sprz�tu, kt�re zajmuje �rednio najwy�sze miejsce we wszystkich rankingach. W tym przypadku brak parametr�w
EXEC Sprzet.AvgRanking;

-- Zadanie 5: dodanie nowego sprz�tu (z podaniem nazwy i typu)
-- wersja a: wstawiam wszystkie parametry
-- komentarz: nale�y odpowiednio wprowadzi� miejsce w rankingu, procedura dzia�a transakcyjnie
EXEC Sprzet.DodajSprzet 
    @Nazwa = 'Kajak profesjonalny',
    @Profesjonalny = 1,
    @Typ = 'g�rski',
    @CenaZaDobe = 80.00,
    @ProducentId = 3,
    @Rabat = 5.00,
    @Opis = 'Rower profesjonalny g�rski',
    @KategoriaId = 8,
    @Ranking = 8;

-- wersja b: tym razem wstawiam warto�ci domy�lne w polach Opis oraz Rabat
EXEC Sprzet.DodajSprzet 
    @Nazwa = 'Kajak profesjonalny',
    @Profesjonalny = 1,
    @Typ = 'wodny',
    @CenaZaDobe = 80.00,
    @ProducentId = 3,
    @KategoriaId = 9,
    @Ranking = 6;

-- Zadanie 6: wygenerowanie zestawienia wszystkich pracownik�w i ich szef�w. Brak parametr�w.
EXEC Osoby.ZestawieniePracownikow;

/* Zadanie 7: otrzymanie opisu dla ka�dego rodzaju sprz�tu, przy czym dla sprz�tu g�rskiego opis ma uwzgl�dnia� nazw�, 
nazw� producenta, oraz por� roku w jakim sprz�tu mo�na u�ywa�, natomiast dla wodnego - nazw�, nazw� producenta, oraz informacj� o patencie.
Aby zachowa� czytelno��, rozdzieli�em te informacje na 2 dodatkowe kolumny, zale�ne od typu (nazywanego u mnie kategori�).
*/
EXEC Sprzet.OpisSprzetu;


