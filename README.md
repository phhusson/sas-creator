
## Usage on Linux

Generate secure variant from any:
```
sudo bash securize.sh system.img
```
The output for above would be `s-secure.img`.

Generate A64 AB VNDKLite from A64 AB:
```
sudo bash lite-adapter.sh 32 system.img
```
Generate ARM64 AB VNDKLite from ARM64 AB:
```
sudo bash lite-adapter.sh 64 system.img
```
Generate ARM A-only from ARM AB (deprecated since Android 12):
```
sudo bash run.sh 32 system.img
```
Generate ARM64 A-only from ARM64 AB (deprecated since Android 12):
```
sudo bash run.sh 64 system.img`
```
The output for above would be `s.img`.

## Usage on Windows

Windows users (with fairly recent hardware and Windows version) can run these scripts on Docker, without having to set up a full Ubuntu installation/VM. For people who are new to Docker, below are crude steps to e.g. securize an image with it:

 1. [Install Docker Desktop](https://docs.docker.com/desktop/windows/install/).
 2. Make sure Docker is in **Linux** Container mode (it should be by default) - right click the tray icon, one of the menu items should say "Switch to **Windows** Containers", **don't** click it.
 3. Pick/make a folder (e.g. `C:\out`) and put your GSI image there (e.g. `system.img`).
 4. Open Docker Desktop - Settings - Resources - File sharing and add the above folder.
 5. Open Command Prompt (`cmd`) and run:
```
docker pull ubuntu
docker run -it -v C:\out:/out --privileged ubuntu
```
This starts a Ubuntu container and mounts `C:\out` to `/out` inside it.

 6. You should now be in a privileged (`#`) Ubuntu terminal. Run:
```
apt update
apt install -y git xattr
git clone https://github.com/AndyCGYan/sas-creator
cd sas-creator
bash securize.sh /out/system.img
mv s-secure.img /out
exit
```
You can now flash the securized image `C:\out\s-secure.img`.

Note: intentionally not using Dockerfile.
