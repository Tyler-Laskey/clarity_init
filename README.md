# Clarity Init <!-- omit in toc -->

- [Setup Ubuntu WSL](#setup-ubuntu-wsl)
  - [Enable Windows Subsystem for Linux & Hyper-V](#enable-windows-subsystem-for-linux--hyper-v)
  - [Download and install Ubuntu](#download-and-install-ubuntu)
  - [Add ubuntu to the Windows environment PATH](#add-ubuntu-to-the-windows-environment-path)
- [Initialize Clarity Local Dev Environment](#initialize-clarity-local-dev-environment)
- [Optional - Manually re-trigger the proxy portion of the setup. (You should not need to do this typically)](#optional---manually-re-trigger-the-proxy-portion-of-the-setup-you-should-not-need-to-do-this-typically)

## Setup Ubuntu WSL

Prior to running the following instructions you _**MUST**_ run these powershell commands as an admin:

### Enable Windows Subsystem for Linux & Hyper-V

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
wsl --set-default-version 2
```

A reboot will be required at this point to complete activating WSL & Hyper-V

### Download and install Ubuntu

1. Download the Ubuntu app bundle from Microsoft <https://aka.ms/wslubuntu2004> (file is 895MB, pay attention to where you save this as you will need it in the following steps)
2. Run the AppxBundle that you downloaded ot install Ubuntu
3. You will be prompted for a new UNIX username, this is NOT tied to your windows login but I recommend using your windows username (T/X id). The username _IS_ case sensitive

### Add ubuntu to the Windows environment PATH

1. Open PowerShell as an Administrator and in that window paste the following (the window will automatically close once complete):

```powershell
$userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
[System.Environment]::SetEnvironmentVariable("PATH", $userenv + ";C:\Users\Administrator\Ubuntu", "User")
exit
```

2. To verify that Ubuntu is successfully installed, open a new window and run the command: `ubuntu`. This should launch Ubuntu.

## Initialize Clarity Local Dev Environment

1. To install run the following commands:

```sh
git clone https://github.com/Tyler-Laskey/clarity_init.git ~/clarity_init
cd ~/clarity_init
chmod +x init.sh && chmod +x addAliases.sh
./addAliases.sh && sudo ./init.sh
```

2. After restarting ubuntu run the following commands:

```sh
cd ~/clarity_init
sudo ./init.sh
```

3. The Python portion of the init script will be triggered automatically, but if you need to correct the path that you provided the script you can re-run the python portion manually.

```sh
sudo ./initPython.sh
```

## Optional - Manually re-trigger the proxy portion of the setup. (You should not need to do this typically)

1. To apply the proxy patch specifically please use the `--proxy` argument and this will apply the linux portion of the patch.

```sh
sudo ./init.sh --proxy
```
