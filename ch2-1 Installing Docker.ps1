## Installing Docker on Linux
ssh demo@sqlondocker

# Install docker
sudo apt install docker docker.io -y

# verify installation
sudo docker ps

exit

# On Windows
# Install WSL first
wsl --install
wsl --set-version 2

# Manually
Start-Process https://docs.docker.com/desktop/install/windows-install/

# Or through choco
choco install docker-desktop -y 

# Add the VSCode extensions
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-wsl

# Reboot
shutdown /r