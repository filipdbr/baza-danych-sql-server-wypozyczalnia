SELECT 
    spid, 
    db_name(dbid) AS database_name, 
    loginame AS login_name, 
    hostname, 
    program_name
FROM sys.sysprocesses
WHERE db_name(dbid) = 'Wypozyczalnia';

DROP DATABASE Wypozyczalnia;