# clarity_init

To install run the following commands:
```sh
git clone https://github.com/Tyler-Laskey/clarity_init.git ~/clarity_init
cd ~/clarity_init
chmod +x init.sh && chmod +x addAliases.sh
./addAilases.sh && sudo ./init.sh
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
