# Mediabox (Testing Branch – Modular Compose)
> **This branch contains the new modular compose system** with per-app fragments, a dynamic `docker-compose.generated.yml`, and enhanced `mediabox.sh` flags.

**Repo URL:** [https://github.com/jamesvthompson/mediabox/tree/testing](https://github.com/jamesvthompson/mediabox/tree/testing)

---

## 🚀 Quick Start

```bash
git checkout testing
./mediabox.sh --interactive
```

The interactive menu lets you toggle apps before launching.  
Your choices are saved in `prep/config.yml` under `apps:`.

---

## 🧩 Modular Compose

Instead of one huge `docker-compose.yml`, apps now live in:
```
compose/base.yml        # always included
compose/<app>.yml       # one per app/service
```

`./mediabox.sh` uses `scripts/generate-compose.sh` to combine only the enabled apps into:
```
docker-compose.generated.yml
```

---

## ✅ Category Requirements

Your selection **must** include:

1. **One download client**  
   - `delugevpn` \| `qbittorrentvpn` \| `sabnzbd`
2. **One manager**  
   - `radarr` \| `sonarr` \| `lidarr` \| `headphones`
3. **One player**  
   - `plex` \| `emby` \| `jellyfin`

If any category is missing, the script will exit with a friendly error and tips.

---

## ⚙️ New Flags

| Flag | Description |
|------|-------------|
| `--list-apps` | Show all available apps and which are enabled in `prep/config.yml`. |
| `--enable <apps>` | Permanently enable apps in `prep/config.yml`. |
| `--disable <apps>` | Permanently disable apps in `prep/config.yml`. |
| `--interactive` | Menu to toggle apps before launch. Saves to `prep/config.yml`. |
| `--dry-run` | Print the merged compose file to stdout, do not write or launch. |
| `--no-launch` | Generate compose file but do not start containers. |
| `--check-env` | Verify required environment variables (VPN creds, etc.). |
| `--apps <list>` | Override enabled apps for this run only. Comma/space separated. |

---

## 💡 Examples

Run interactively:
```bash
./mediabox.sh --interactive
```

Enable Overseerr and disable Plex permanently, but don’t launch:
```bash
./mediabox.sh --enable overseerr --disable plex --no-launch
```

Preview a stack with Plex, Sonarr, and DelugeVPN:
```bash
./mediabox.sh --apps "plex sonarr delugevpn" --dry-run
```

Launch using currently enabled apps:
```bash
./mediabox.sh
```

---

## 📦 Adding a New App

1. Create `compose/<app>.yml` with the service definition.  
2. Add `app: true/false` under `apps:` in `prep/config.yml`.  
3. Select via `--apps`, `--enable`, or `--interactive`.

---

## 🛠 Troubleshooting

- **Missing VPN credentials?**  
  Use `.env` in repo root or export vars:
  ```bash
  export VPN_USER=myuser
  export VPN_PASS=mypass
  ```

- **Missing category requirement?**  
  Add at least 1 from each: **download client**, **manager**, **player**.

---

# Mediabox

Mediabox is an all Docker Container based media aggregator stack.

Components include:

* [Couchpotato movie library manager](https://couchpota.to/)
* [Deluge torrent client (using VPN)](http://deluge-torrent.org/)
* [Dozzle realtime log viewer](https://github.com/amir20/dozzle)
* [Duplicati Backup Software](https://www.duplicati.com/)
* [Emby Open Media Solution](https://emby.media/)
* [Filebrowser Web-Based File Manager](https://github.com/filebrowser/filebrowser)
* [Flaresolverr proxy server to bypass Cloudflare protection (Used with Jackett)](https://github.com/FlareSolverr/FlareSolverr)
* [Glances system monitoring](https://nicolargo.github.io/glances/)
* [Headphones automated music downloader](https://github.com/linuxserver/docker-headphones)
* [Homer - Server Home Page](https://github.com/bastienwirtz/homer)
* [Homer Icons - Icons for Homer](https://github.com/NX211/homer-icons)
* [Jackett Tracker API and Proxy](https://github.com/Jackett/Jackett)
* [Jellyfin Free Software Media System](https://github.com/jellyfin/jellyfin)
* [Lidarr Music collection manager](https://lidarr.audio/)
* [Maintainerr library management system](https://maintainerr.info/)
* [MeTube Web GUI for youtube-dl](https://github.com/alexta69/metube)
* [Minio cloud storage](https://www.minio.io/)
* [NetData System Monitoring](https://github.com/netdata/netdata)
* [NZBGet Usenet Downloader](https://nzbget.net/)  
* [NZBHydra2 Meta Search](https://github.com/theotherp/nzbhydra2)  
* [Ombi media assistant](http://www.ombi.io/)
* [Overseerr Media Library Request Management](https://github.com/sct/overseerr)
* [Plex media server](https://www.plex.tv/)
* [Portainer Docker Container manager](https://portainer.io/)
* [Prowlarr indexer manager/proxy](https://github.com/Prowlarr/Prowlarr)
* [Radarr movie library manager](https://radarr.video/)
* [Requestrr Chatbot for Sonarr/Radarr/Ombi](https://github.com/darkalfx/requestrr)
* [SABnzbd Usenet download tool](https://github.com/sabnzbd/sabnzbd)
* [SickChill TV library manager](https://github.com/SickChill/SickChill)
* [Sonarr TV library manager](https://sonarr.tv/)
* [Speedtest - Tracker](https://github.com/henrywhitaker3/Speedtest-Tracker)
* [SQLitebrowser DB browser for SQLite](https://sqlitebrowser.org/)
* [Tautulli Plex Media Server monitor](https://github.com/tautulli/tautulli)
* [Tdarr Distributed Transcoding System](https://tdarr.io)
* [TubeSync - YouTube PVR](https://github.com/meeb/tubesync)
* [Watchtower Automatic container updater](https://github.com/containrrr/watchtower)

## Prerequisites

* [Ubuntu 24.04 LTS](https://www.ubuntu.com/)
* [VPN account from Private internet Access](https://www.privateinternetaccess.com/) (Please see [binhex's Github Repo](https://github.com/binhex/arch-delugevpn) if you want to use a different VPN)
* [Git](https://git-scm.com/)
* [Docker](https://www.docker.com/)
* [Docker-Compose](https://docs.docker.com/compose/)

### **PLEASE NOTE**

For simplicity's sake (eg. automatic dependency management), the method used to install these packages is Ubuntu's default package manager, [APT](https://wiki.debian.org/Apt).  There are several other methods that work just as well, if not better (especially if you don't have superuser access on your system), so use whichever method you prefer.  Continue when you've successfully installed all packages listed.

### Installation

(You'll need superuser access to run these commands successfully)

## Installation (Ubuntu 24.04.3 LTS)

### 1) Update and upgrade packages
```bash
sudo apt update && sudo apt full-upgrade
```

### 2) Install prerequisites
```bash
sudo apt install -y curl git bridge-utils whiptail
```

### 3) Remove old Docker (OK if nothing to remove)
```bash
sudo apt remove -y docker docker-engine docker.io containerd runc
sudo snap remove docker
```

### 4) Install Docker CE (official method)
```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify:
```bash
docker --version
docker compose version
```

### 5) Add your user to the docker group
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 6) DelugeVPN kernel module
```bash
sudo /sbin/modprobe iptable_mangle
echo iptable_mangle | sudo tee -a /etc/modules
```

### 7) Reboot (recommended if Docker group just added)
```bash
sudo reboot
```
## Using mediabox

Once the prerequisites are all taken care of you can move forward with using mediabox.

### 8) Clone Mediabox
```bash
git clone https://github.com/jamesvthompson/mediabox.git
cd mediabox
```

### 9) Configure & Deploy
```bash
# Run the Mediabox setup script (collects .env and prepares compose)
./mediabox.sh
```

### Notes
- **Plex tag:** set `PMSTAG` in `.env` (e.g., `public` or `plexpass`). Example image:
  `image: plexinc/pms-docker:${PMSTAG:-public}`
- If you change image tags, test them directly first:
  
## Using mediabox

### Please be prepared to supply the following details after you run Step 3 above

As the script runs you will be prompted for:

1. Your Private Internet Access credentials
    * **username**
    * **password**

2. The version of Plex you want to run
    * **latest**
    * **public**
    * **plexpass**

    Note: If you choose plexpass as your version you may optionally specify CLAIM_TOKEN - you can get your claim token by logging in at [plex.tv/claim](https://www.plex.tv/claim)

3. Credentials for the NBZGet interface and the Deluge daemon which needed for the CouchPotato container.
    * **username**
    * **password**

Upon completion, the script will launch your mediabox containers.  

Portainer has been switched to the **CE** branch  

* **A Password** will now be required - the password can be set at initial login to Portiner.  
* **Initial Username** The initial username for Portainer is **admin**  

### **Mediabox has been tested to work on Ubuntu 18.04 LTS / 20.04 LTS - Server and Desktop**

**Thanks go out to:**

[@kspillane](https://github.com/kspillane)

[@mnkhouri](https://github.com/mnkhouri)

[@danipolo](https://github.com/danipolo)

[binhex](https://github.com/binhex)

[LinuxServer.io](https://github.com/linuxserver)

[Docker](https://github.com/docker)

[Portainer.io](https://github.com/portainer)

---

If you enjoy the project -- Fuel it with some caffeine :)

[![Donate](https://img.shields.io/badge/Donate-SquareCash-brightgreen.svg)](https://cash.me/$TomMorgan)

---

## Disclaimer

THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## License

MIT License

Copyright (c) 2017 Tom Morgan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
