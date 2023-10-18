# It's always DNS!
nslookup sqlonlinux.demo.lcl
nslookup 192.168.100.101

# Integrate our Server with the Active Directory
ssh demo@sqlonlinux

# Add tools
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update 
sudo apt-get install -y realmd krb5-user software-properties-common python3-software-properties packagekit adcli libpam-sss libnss-sss sssd sssd-tools adutil

# Join the AD Domain - Make sure to use upper case for Domain!
echo Passw0rd | sudo realm join DEMO.LCL -U 'demo-adm@DEMO.LCL' -v

# Lets init kerberos
echo Passw0rd | kinit demo-adm@DEMO.LCL

# We should have a kerberos ticket
klist

# Let's create a login
adutil user create --name sqlsvc --distname CN=sqlsvc,CN=Users,DC=DEMO,DC=LCL --password 'Passw0rd' --accept-eula -d 

# ... an SPN
adutil spn addauto -n sqlsvc -s MSSQLSvc -H sqlonlinux.demo.lcl -p 1433 -y

# And create a keytab file
adutil keytab createauto -k mssql.keytab -p 1433 -H sqlonlinux.demo.lcl --password 'Passw0rd' -s MSSQLSvc -e aes256-cts-hmac-sha1-96,aes128-cts-hmac-sha1-96,aes256-cts-hmac-sha384-192,aes128-cts-hmac-sha256-128,des3-cbc-sha1,arcfour-hmac -y
adutil keytab create -k mssql.keytab -p sqlsvc --password 'Passw0rd' -e aes256-cts-hmac-sha1-96,aes128-cts-hmac-sha1-96,aes256-cts-hmac-sha384-192,aes128-cts-hmac-sha256-128,des3-cbc-sha1,arcfour-hmac

# Put that file in the right place
sudo mv mssql.keytab /var/opt/mssql/secrets/
sudo chown mssql. /var/opt/mssql/secrets/mssql.keytab
sudo chmod 440 /var/opt/mssql/secrets/mssql.keytab

# And configure SQL Server to use it
sudo /opt/mssql/bin/mssql-conf set network.kerberoskeytabfile /var/opt/mssql/secrets/mssql.keytab
sudo /opt/mssql/bin/mssql-conf set network.privilegedadaccount sqlsvc
sudo systemctl restart mssql-server

exit

# We can then authorize our AD User
sqlcmd -S sqlonlinux -U sa -Q 'CREATE LOGIN [DEMO\DEMO-adm] FROM Windows'

# and use AD auth
$env:SQLCMDPASSWORD=""
sqlcmd -S sqlonlinux -Q "SELECT SUSER_NAME()"