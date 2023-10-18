# AD Integration
# We need a keytab first which we can generate on any AD joined machine
ssh demo@sqlonlinux

# We create a new SPN and keytab - Take note of the hostname and the port!
echo Passw0rd | kinit demo-adm@DEMO.LCL
adutil spn addauto -n sqlsvc -s MSSQLSvc -H dockerad.demo.lcl -p 32433 -y
adutil keytab createauto -k mssql.keytab -p 32433 -H dockerad.demo.lcl --password 'Passw0rd' -s MSSQLSvc -e aes256-cts-hmac-sha1-96,aes128-cts-hmac-sha1-96,aes256-cts-hmac-sha384-192,aes128-cts-hmac-sha256-128,des3-cbc-sha1,arcfour-hmac -y
adutil keytab create -k mssql.keytab -p sqlsvc --password 'Passw0rd' -e aes256-cts-hmac-sha1-96,aes128-cts-hmac-sha1-96,aes256-cts-hmac-sha384-192,aes128-cts-hmac-sha256-128,des3-cbc-sha1,arcfour-hmac

exit

# Let's add a DNS Record for dockerad.demo.lcl - using the IP of sqlondocker
Set-ClipBoard ([System.Net.Dns]::GetHostAddresses("sqlondocker.demo.lcl").IPAddressToString)
cmdkey /generic:DC.demo.lcl /user:Demo\demo-adm /pass:Passw0rd
mstsc /v:DC.demo.lcl /w:1280 /h:720


# We can then copy this keytab file to the machine running docker 
scp demo@sqlonlinux:~/mssql.keytab mssql.keytab 
scp mssql.keytab demo@sqlondocker:~/mssql.keytab

# Login to machine running docker
ssh demo@sqlondocker

# We need an ini file for SQL Server
cat <<EOF >> mssql.conf
[network]
privilegedadaccount = sqlsvc
kerberoskeytabfile = /var/opt/mssql/secrets/mssql.keytab
EOF

# As well as a Kerberos conf file
cat <<EOF >> krb5.conf
[libdefaults]
default_realm = DEMO.LCL

[realms]
DEMO.LCL = {
    kdc = DC.demo.lcl
    admin_server = DC.demo.lcl
    default_domain = DEMO.LCL
}

[domain_realm]
.demo.lcl = DEMO.LCL
demo.lcl = DEMO.LCL
EOF

cat <<EOF >> logger.ini
[Output:security]
Type = File
Filename = /var/opt/mssql/log/security.log
[Logger]
Level = Silent
[Logger:security.kerberos]
Level = Debug
Outputs = security
[Logger:security.ldap]
Level = debug
Outputs = security
EOF

# Create a directory for our volume in advance
sudo mkdir /container
sudo mkdir /container/dockerad
sudo mkdir /container/dockerad/secrets

# Add the files there
sudo mv mssql.keytab /container/dockerad/secrets
sudo mv mssql.conf /container/dockerad
sudo mv krb5.conf /container/dockerad
sudo mv logger.ini /container/dockerad

# Make sure that everything is accessible
sudo chmod -R 755 /container/dockerad/

# And add the mssql user and make it the owner
sudo useradd -M -s /bin/bash -u 10001 -g 0 mssql
sudo chown -R mssql /container/dockerad/

# Now, we can run the container - see Port and name again!
sudo docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=Passw0rd" \
-p 32433:1433 --name dockerad -h dockerad \
-v /container/dockerad:/var/opt/mssql \
-v /container/dockerad/krb5.conf:/etc/krb5.conf \
--dns-search demo.lcl \
--dns 192.168.100.10  \
--add-host DC.demo.lcl:192.168.100.10  \
--add-host demo.lcl:192.168.100.10  \
--add-host demo:192.168.100.10  \
-d mcr.microsoft.com/mssql/server:2019-latest

# If you run into issues with the AD integration, this is where you should look:
# https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-ad-auth-troubleshooting?view=sql-server-ver16
cat /container/dockerad/log/security.log 

exit

# We can connect with SQL auth
sqlcmd -S sqlondocker,32433 -U SA -Q "SELECT @@ServerName,@@Version"

# Authorize our AD User...
sqlcmd -S dockerad,32433 -U sa -Q 'CREATE LOGIN [DEMO\DEMO-adm] FROM Windows'

# And use AD auth
$env:SQLCMDPASSWORD=""
sqlcmd -S dockerad,32433 -Q "SELECT SUSER_NAME()"