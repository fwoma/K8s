# Install Choco
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Tools
choco install vscode -y
choco install openssh -y
choco install googlechrome -y
choco install curl -y
choco install grep -y
choco install sql-server-management-studio -y 
choco install azure-data-studio -y
choco install sqlcmd -y

# Refresh Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Add VSCode Powershell Extension and update Package Management
code --install-extension ms-vscode.PowerShell
Install-PackageProvider Nuget -Force
Install-Module -Name PowerShellGet -Force 
Install-Module -Name PackageManagement -Force 

# Post vscode install
copy $home\desktop\keybindings.json $home\AppData\Roaming\Code\User
copy $home\desktop\settings.json $home\AppData\Roaming\Code\User

# Copy SSH key

# Create/refresh known hosts
remove-item "$($Home)\.ssh\known_hosts" -force
$Machines = @('k8s-nfs','k8s-cp','k8s-worker-1','k8s-worker-2','sqlonlinux','sqlondocker')
foreach($machine in $Machines) {
    $SSHTarget=("demo@" + ($machine))
    ssh -o StrictHostKeyChecking=no -t $SSHTarget ("echo " + $machine)
}