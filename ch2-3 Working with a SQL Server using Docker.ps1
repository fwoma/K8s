# We can create a Database
$env:SQLCMDPASSWORD="Passw0rd"
sqlcmd -S 127.0.0.1,31434 -U sa -Q "CREATE DATABASE TestDB"

# Which shows up:
sqlcmd -S 127.0.0.1,31434 -U sa -Q "SELECT Name from sys.databases"

# However, if we stop, delete and re-create the container...
docker stop sql2022
docker rm sql2022
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Passw0rd" `
-p 31434:1433 --name sql2022 -h sql2022 `
-d mcr.microsoft.com/mssql/server:2022-latest

# ...it is gone:
sqlcmd -S 127.0.0.1,31434 -U SA  -Q "SELECT Name from sys.databases"

# Let's also add a volume to persist our data in another container!
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Passw0rd" `
   -p 31435:1433 --name sql2022-persistent -h sql2022 -v sqldata2:/var/opt/mssql `
   -d mcr.microsoft.com/mssql/server:2022-latest

# We can now create a new DB
sqlcmd -S 127.0.0.1,31435 -U SA  -Q "CREATE DATABASE TestDB"

# And can also see the content in the container
docker exec sql2022-persistent ls /var/opt/mssql/data/TestDB.mdf

# Then stop and delete the container
docker stop sql2022-persistent
docker rm sql2022-persistent

# But our volume is still here!
docker volume ls

# Create a new Container with the same volume
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Passw0rd" `
   -p 31435:1433 --name sql2022-new -h sql2022 -v sqldata2:/var/opt/mssql `
   -d mcr.microsoft.com/mssql/server:2022-latest

# And our TestDB is here:
sqlcmd -S 127.0.0.1,31435 -U SA  -Q "SELECT Name from sys.databases"

# Advanced configs run through environment variables
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Passw0rd" `
   -p 31436:1433 --name sql2019-new -h sql2019-new `
   -e "MSSQL_PID=Evaluation" --env "MSSQL_AGENT_ENABLED=True" `
   -d mcr.microsoft.com/mssql/server:2019-latest /opt/mssql/bin/sqlservr -T 3205

# We have an Evaluation Edition now
sqlcmd -S 127.0.0.1,31436 -U SA  -Q "SELECT @@Version"

# With a traceflag 
sqlcmd -S 127.0.0.1,31436 -U SA  -Q "DBCC TRACESTATUS"

# And in SSMS, we can also see the Agent
Start-Process "C:\Program Files (x86)\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe"