## SQL on Docker
ssh demo@sqlondocker

# Pull SQL 2022
sudo docker pull mcr.microsoft.com/mssql/server:2022-latest

# Run SQL 2022
sudo docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Passw0rd" \
-p 31433:1433 --name sql2022 -h sql2022 \
-d mcr.microsoft.com/mssql/server:2022-latest

# See the process
sudo docker ps -a

exit 

# This is accessible from Windows as well (note the port!)
$env:SQLCMDPASSWORD="Passw0rd"
sqlcmd -S sqlondocker,31433 -U SA -Q "SELECT @@ServerName,@@Version"

# But we could also run this on our Docker on Windows for SQL Server 2019
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Passw0rd" `
-p 31433:1433 --name sql2019 -h sql2019 `
-d mcr.microsoft.com/mssql/server:2019-latest

# Connect to the instance
sqlcmd -S 127.0.0.1,31433 -U SA -Q "SELECT @@servername,@@version"

# Run SQL 2022
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Passw0rd" `
-p 31434:1433 --name sql2022 -h sql2022 `
-d mcr.microsoft.com/mssql/server:2022-latest

# See both instances running
docker ps -a

# And SQL 2022 is also accessible
sqlcmd -S 127.0.0.1,31434 -U SA -Q "SELECT @@version"

# Or use the new sqlcmd
sqlcmd create mssql --accept-eula --using https://aka.ms/AdventureWorksLT.bak
sqlcmd query "SELECT DB_NAME()"
#sqlcmd open ads
