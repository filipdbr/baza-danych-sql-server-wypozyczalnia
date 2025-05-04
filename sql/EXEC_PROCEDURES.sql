USE Wypozyczalnia;
GO

-- Zadanie 1: wywo³ujê pracedurê sk³adowan¹ PracownikMIesi¹ca.
EXEC Osoby.PracownikMiesiaca @Od = '2023-07-01', @Do = '2023-07-31';

-- Zadanie 2: procedura sk³adowana Zamówienia Klienta. Umo¿liwia generowanie raportów o zamówieniach danego klienta w zadanym okresie czasu.
EXEC Zamowienia.ZamowieniaKlienta @KlientId = 45, @Od = '2023-06-01', @Do = '2024-06-01';

-- Zadanie 3: wyœwietlenie rankingu sprzêtu w danej kategorii, w tym przypadku kategoria o id 8, czyli 'wodny'
EXEC Sprzet.Ranking 7;

-- Zadanie 4: znalezienie sprzêtu, które zajmuje œrednio najwy¿sze miejsce we wszystkich rankingach. W tym przypadku brak parametrów
EXEC Sprzet.AvgRanking;

-- Zadanie 5: dodanie nowego sprzêtu (z podaniem nazwy i typu)
-- wersja a: wstawiam wszystkie parametry
-- komentarz: nale¿y odpowiednio wprowadziæ miejsce w rankingu, procedura dzia³a transakcyjnie
EXEC Sprzet.DodajSprzet 
    @Nazwa = 'Kajak profesjonalny',
    @Profesjonalny = 1,
    @Typ = 'górski',
    @CenaZaDobe = 80.00,
    @ProducentId = 3,
    @Rabat = 5.00,
    @Opis = 'Rower profesjonalny górski',
    @KategoriaId = 8,
    @Ranking = 8;

-- wersja b: tym razem wstawiam wartoœci domyœlne w polach Opis oraz Rabat
EXEC Sprzet.DodajSprzet 
    @Nazwa = 'Kajak profesjonalny',
    @Profesjonalny = 1,
    @Typ = 'wodny',
    @CenaZaDobe = 80.00,
    @ProducentId = 3,
    @KategoriaId = 9,
    @Ranking = 6;

-- Zadanie 6: wygenerowanie zestawienia wszystkich pracowników i ich szefów. Brak parametrów.
EXEC Osoby.ZestawieniePracownikow;

/* Zadanie 7: otrzymanie opisu dla ka¿dego rodzaju sprzêtu, przy czym dla sprzêtu górskiego opis ma uwzglêdniaæ nazwê, 
nazwê producenta, oraz porê roku w jakim sprzêtu mo¿na u¿ywaæ, natomiast dla wodnego - nazwê, nazwê producenta, oraz informacjê o patencie.
Aby zachowaæ czytelnoœæ, rozdzieli³em te informacje na 2 dodatkowe kolumny, zale¿ne od typu (nazywanego u mnie kategori¹).
*/
EXEC Sprzet.OpisSprzetu;


