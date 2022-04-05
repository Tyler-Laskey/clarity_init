# clarity_init

Prior to running the following instructions you _**MUST**_ run these powershell commands as an admin:
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
wsl --set-default-version 2
```


To install run the following commands:
```sh
git clone https://github.com/Tyler-Laskey/clarity_init.git ~/clarity_init
cd ~/clarity_init
chmod +x init.sh && chmod +x addAliases.sh
./addAliases.sh && sudo ./init.sh
```
After restarting ubuntu run the following commands:
```sh
cd ~/clarity_init
sudo ./init.sh
```

To apply the proxy patch specifically please use the **--proxy** argument and this will apply the linux portion of the patch.
```sh
sudo ./init.sh --proxy
```
