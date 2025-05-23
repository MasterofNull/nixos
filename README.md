# How?
Follow these instructions to install this OS on a bare-metal install. (VM and other install methods just use rascal999/maxos repo and instructions.)

The main steps to the installation:

1. Install NixOS on the system. Bootable USB preferred.
2. Pull/Download the NixOS configuration, resources, and submodules files.
3. Change the configuration files to reflect your hardware and memory configurations.
4. Use nixos-rebuild to switch the system to the flake of your choice.

### PHASE 1

NOTE:
Many of these steps and commands can be found in the setup scripts within nixos/scripts/.
Specifically, nixos/scripts/init.sh and nixos/scripts/setup.sh.

Create a NixOS USB bootable install.
Follow the steps on the USB for a new install. 
(I have had problems with warnings and errors during the installation of no BSD while doing custom install options. We will have the option of adding/changing files, disks, and partitions later.)

If you are not familiar or want to get up and running asap set [User-name] to "user" and [Password] to "#1pass" during your USB install.

If you set [User-name] and [Password] to different values during the USB or initial install. 
The system login will be set to these values until you switch to the final flake configuration. 

It is STRONGLY recommended to use "user" as the initial profile install.
Many hard-coded file pointers use this name within the NixOS flake and dot files. 
These file locations and pointers need to be changed to the profile/user name and reflect the location chosen. 

If you know how to set user names and passwords in flakes. Then make sure to update them in the shared.nix file.

After the "final" flake switch, the login values will be set to [User-name] = user and [Password] = #1pass.

Or you can learn about the hashed password setup below. [User-name] will also need to be changed within the nixos/shared.nix file (If the [User-name] is not "user").
To change the [User-name] and [Password] 

https://nlewo.github.io/nixos-manual-sphinx/configuration/user-mgmt.xml.html

https://discourse.nixos.org/t/mkpasswd-m-sha-512-password/23785

Install the system on the largest drive. (We can always move later using the "hardware-configuration.nix" settings)


Now we have a fresh install complete with missing tools. Let's install those tools.
When the install is complete, run:
```
sudo nix-env --install git docker wget vscodium firefox
```
We will need to fully implament these tools within our current nixos build.
Add the below settings to "configuration.nix" (etc/nixos):
```
#docker
virtualisation.docker.rootless = {
  enable = true;
  setSocketVariable = true;
};

users.extraGroups.docker.members = [ "USER-NAME" ];
```
In the configuration.nix file add "docker" to the setting "extraGroups = [ "networkmanager" "wheel" ];
```
extraGroups = [ "networkmanager" "wheel" "docker" ];
```

Time to update our current NixOS build to include rootless Docker.
Run
```
sudo nixos-rebuild switch 
```
NOTE:
During final build switch if you get "error: path '/nix/store/*-linux-6.12.20-modules-shrunk/lib' is not in the Nix store"

Add "--upgrade" to the end of the code above.


Restart the machine.

```
sudo dockerd
```
Make sure Docker is running (with the above command) for the next steps. 

### PHASE 2

We need to download some large and old files from git. Let's do some prep.
```
git config --global http.version HTTP/1.1
git config --global core.compression 0
git config --global http.post Buffer 524288000
```
Set your sign-in credentials for git and Docker using the console.

```
git config --global user.email "{ID}+{username}@users.noreply.github.com"
git config --global user.name "USER-NAME"
```
While in your home directory, initialize Git:
```
git init
```

Set up Git:
https://docs.github.com/en/get-started/git-basics/set-up-git
Git Personal Tokens:
https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic

Set up Docker:
https://docs.docker.com/reference/cli/docker/login/#:~:text=%24%20docker%20login%20USING%20WEB%2DBASED,for%20authentication%20in%20the%20browser%E2%80%A6

After your sign-in information is set, let's start getting our NixOS system files.
The nixos folder with our flakes and dot files needs to be at the location "/home/user/nixos" and be named "nixos".
Run:
```
git clone https://github.com/MasterofNull/nixos.git
```

We must also copy some scripts into another file location and make them executable. To help download and set up some of our tools.
```
cp nixos/scripts/resources.sh nixos/resources/resources.sh
mkdir nixos/repos/dump
cp nixos/scripts/20230109_submodules.sh nixos/repos/dump/20230109_submodules.sh
chmod +x nixos/resources/resources.sh
chmod +x nixos/repos/dump/20230109_submodules.sh
./nixos/resources/resources.sh -abf
cd nixos/repos/dump
./20230109_submodules.sh
```
When the files are done downloading, move and merge the files from the created dump folder into the parent (/repos) folder.

CD into the nixos file and add the nixos folder and files to the git:
```
cd nixos
git add .
git commit -m "Host HOST-NAME"
git push
```

### PHASE 3

While those are downloading and before we switch into our new configuration we need a few more files and setup.
Copy the filesystem and device settings from etc/nixos/hardware-configuration.nix to nixos/hosts/(host-of-choice)/hardware-configuration.nix

Make sure your CPU and GPU settings are set correctly for your specific hardware. 
Settings for CPU and GPU are set in these files: 

nixos/config/shared.nix nixos/hosts/(host-of-choice)/configuration.nix and hardware-configuration.nix

You can compare the above settings/files with the auto-generated config from the initial install.

Which can be found at: etc/nixos/configuration.nix and etc/nixos/hardware-configuration.nix

During the initial switch to our flake, I am getting floating dependencies for x2goserver. So let's comment that out for now.

nixos/config/shared.nix
```
# x2go
  #services.x2goserver.enable = true;
```


### PHASE 4

If all that has worked out well.
Run:
Note: Replace HOST-NAME with flake names set within the flakes.nix. (Examples: mac, rog, iso, rig)

Also, we can update our NixOS flake file before switching to our new build to speed up error identification while switching.

During the initial install for the larger machine installs. I will edit the flake file (nixos/flake.nix) for the flake I am using to comment out the larger packages list (pkgs_base.nix, pkgs_additional.nix) to speed up the install process and correct or comment out packages and settings that create errors, resulting in a failed flake switch. 

```
### RIG
      rig = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = configSettings ++ [
          ./config/docker.nix
          ./config/grub.nix
          #./config/pkgs_additional.nix
          #./config/pkgs_base.nix
          ./config/pkgs_ui.nix
          ./config/secrets.nix
          ./config/syncthing.nix
          ./hosts/rig/configuration.nix
          ./hosts/rig/hardware-configuration.nix

          ({ pkgs, ... }: {
            home-manager.users.user.imports = [
              ./hosts/rig/home.nix
              ./hosts/rig/i3/i3.nix
            ];
          })
        ];
      };  
```

If the install works, uncomment out the larger package lists (pkgs_base.nix, pkgs_additional.nix) to fully install all programs for the flake of your choice.

```
cd nixos/
nix flake --extra-experimental-features nix-command --extra-experimental-features flakes update
```
Reboot the machine, then run:
```
sudo nixos-rebuild --flake .#HOST-NAME --impure switch
```

Optional:
If you removed the larger package repos to help speed up the install, now is the time to add them back.
(pkgs_base.nix, pkgs_additional.nix)

If you want to enable the x2go server service. Uncomment the line we edited in the shared.nix file.
nixos/config/shared.nix
```
# x2go
  services.x2goserver.enable = true;
```
Reboot the machine, then run:
```
sudo nixos-rebuild --flake .#HOST-NAME --impure switch
```

I will be adding some CPU and GPU specific flakes soon. For most laptops and PC's we are dealing with Intel or AMD CPU's with AMD or NVIDIA GPU 

Hopefully, I will get around to some ARM builds soon. 

> Give me six hours to chop down a tree and I will spend the first four sharpening the ax.

Abraham Lincoln

# What?

[NixOS](https://nixos.org/) config geared towards pentesters and security researchers.

# Why?

**TL;DR** - This VM / build will probably be useful for pentesting exams and people interested in security research.

The goal of this [NixOS](https://nixos.org/) config is to bundle as many bookmarks / shell aliases / docker images / Firefox extensions / git repos / tools as possible to make my pentesting life easier. I didn't invest the time to customise my base installation before because these customisations were not easily or consistently portable.

I didn't want to invest the time customising a machine, getting used to the customisations, and then having to tweak a new build to get to the same place. This all changed when I discovered [NixOS](https://nixos.org/). Now I can customise to my heart's content (almost, with the exception of Firefox extension settings) and deploy these customisations on any device.

My quest to divorce the data from the tin continues..

# Where?

The easiest way to get up and running is via the nightly OVA image available [here](https://alm.gg/maxos_kde.ova) (9.8GB). The VM comes with KDE rather than i3wm by default because I appreciate that you probably don't want to learn all of my [i3wm shortcuts](/config/i3.nix). You can of course build your own VM using the [build_vm_virtualbox.sh script](/scripts/build_vm_virtualbox.sh) and by customising the [VirtualBox VM "host" file](/hosts/vm_virtualbox/configuration.nix).

# What else?

Here is a list of things I'd like to do for this project:

* Docker image
* Working VM image
* Set up build pipeline
* Refactor code
* Review resources.sh
* Review / replace init.sh script
* Review scripts
* Review repos/
* Review docker images
* Refresh README (up to date examples)

# Security warning

I have made a conscious effort to ensure that docker images and tools which run on this build are only accessible on your machine, but I don't have a build pipeline which checks this, nor do I scan this repo for security issues. You have been warned.

# Highlights

This NixOS config comes with a few things to make my life easier while pentesting (some of these resources are available after running the [resources.sh](/scripts/resources.sh) script).

* Over 521 software packages
* 329 zsh aliases
* Over 450 security-focused bookmarks:
  * 63 podcasts
  * 65 YouTube channels / playlists
  * 47 online labs
  * 34 news resources
  * 29 search engines
  * 24 newsletters
  * 17 Telegram channels
* 304 git repos
* 173 docker images
* 36 web applications
* 28 Firefox extensions
* Text-only offline [Wikipedia](http://localhost:9060/wikipedia_en_all_nopic_2022-01/A/User:The_other_Kiwix_guy/Landing)
* [Jupyter Notebooks](http://localhost:8000/tree?) for pentesting

## Security-focused Firefox bookmarks

[Here](/config/firefox/firefox-policies.json) are some security-focused Firefox bookmarks.

![Some Firefox bookmarks](/resources/gifcap/gifcap-ff-bookmarks.gif)

## ZSH aliases

All available [here](/config/zsh/zshrc.zsh) (and more).

### localhost.run filebrowser

Deploy externally accessible, web-based file browser in one command.

![a-localhostrun-filebrowser](/resources/gifcap/gifcap-a-localhostrun-filebrowser.gif)

### localhost.run nginx

Deploy externally accessible nginx instance in one command.

![a-localhostrun-filebrowser](/resources/gifcap/gifcap-a-localhostrun-nginx.gif)

### Vulnerable labs

Deploy a vulnerable lab in one command.

![d-lab-start](/resources/gifcap/gifcap-d-lab-start.gif)

### Ubuntu docker image and port

Deploy an Ubuntu docker image with an arbitrary port exposed in one command.

![d-shellhereport](/resources/gifcap/gifcap-d-shellhereport.gif)

### One line SMB server in CWD

Deploy an SMB share in the current working directory in one command.

![d-smbservehere](/resources/gifcap/gifcap-d-smbservehere.gif)

### Tor array

Deploy a Tor array (a arbitrary number of docker instances which all connect to the Tor network individually and expose incrementing ports) in one command.

![d-tor-array](/resources/gifcap/gifcap-d-tor-array.gif)

# resources.sh

[This](/scripts/resources.sh) script it pretty important to the build. I haven't got it building on top of the VM image yet, but it's responsible for pulling git repos, docker images, and other resources. I recommend you run this if you install maxos.

![resources.sh](/resources/gifcap/gifcap-resources-sh.gif)

# Install

## Build VM

```
docker build . -t maxos-vm-builder
docker run --privileged -v `pwd`:/mnt maxos-vm-builder
```

## Base Install
Use unstable ISO (https://www.google.com/search?q=nixos+iso+unstable) for flake support.

## Get repo

```
# Set SSH key for GitHub
nix-env -i git
git clone git@github.com:rascal999/maxos.git
cd maxos/
```

OR

```
curl -L https://bit.ly/3yCeldM -o master.zip
unzip master.zip
cd maxos-master/
```

## Install

```
./scripts/init.sh
```
