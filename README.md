# google-cloud-x2go-server
Scripts to create, start, stop and destroy an X2Go server in the free-as-in-beer Google Cloud environment

## How to prepare your Google Cloud Shell environment (only needed once per Google Account)

### Run these commands inside the Google Cloud Shell browser window
	git clone https://github.com/stefanbaur/google-cloud-x2go-server.git
	test -d gopath && mv gopath gopath_old
	ln -s google-cloud-x2go-server/gopath gopath

### Edit the file ~/.gcs-x2go (again, inside the Google Cloud Shell browser window)
	export SERVER_USE_ROOT=true
	export SERVERNAME=demoserver
	export CHROOTDEBVERSION="bookworm"
	export USERNAME=demouser
	export USERREALNAME="John Doe"
	# optional - allowed values are "stable", "heuler" (nightly builds), and "saimaa" (ESR)
	export USEX2GOREPO="stable"
	# experimental - setting this to true will force USEX2GOREPO to "heuler"
	export X2GOHTML5=false
Notes:
1. Feel free to change the values of <code>SERVERNAME</code>, <code>USERNAME</code>, and <code>USERREALNAME</code>, but remember that setting any of the username or servername values to a name usually associated with you will mean you are no longer anonymous.
2. If you do not set USEX2GOREPO to "stable" or "heuler", you will not be able to use KDrive. Unsetting the variable, leaving it empty, set to "saimaa", or to an invalid value means you will get the stock packages from Debian 11/Debian 12, or the ESR packages from the X2Go repository, all of which do not contain a working KDrive implementation.

## What is KDrive? ##
KDrive is a replacement protocol for NoMachine NX, the protocol that X2Go has been using since its inception. The problem with NX is that newer desktops like GNOME3, and modern web browsers like Chrome/Chromium and Firefox don't play nice with NX any more. GNOME will likely refuse to run at all, Chrome/Chromium and Firefox will be very sluggish, even with lots of bandwidth. KDrive solves all these issues, but will require slightly more bandwidth than an NX connection. X2Go now incorporates both protocols, you can choose which one to use in each session's configuration tab.

## How to set up and run the server
1. Run this command inside the Google Cloud Shell browser window every time your instance was offline (or if you ran <code>destroyserver</code> before):<code>createserver</code>
2. To actually start the server, run <code>startserver-tor</code> (if you want to connect via Tor) or <code>startserver-google-jumphost</code> (lower latency, but requires the gcloud SDK on the client) inside the Google Cloud Shell browser window. (Note: <code>startserver-reversetunnel</code> is no longer actively tested or maintained, but still provided in case you prefer it over using Tor or gcloud SDK)
4. Only when using Tor: Load the QR code into an authenticator app of your choice *(Note: the QR code will remain the same unless the server's home directory gets deleted)* and copy the emergency codes to a safe location

## How to prepare the client (only needed once per client)

Note that you only need to set up one connection method (Tor, Google Cloud SDK, external jumphost) to the server, but you can set up as many as you like.

### Install required packages - all methods
	sudo apt install x2goclient
Afterwards, run the command <code>dpkg -l x2gokdriveclient | grep "^ii"</code>. If it does not return an empty result on your client, you can also try out our new KDrive protocol in addition to NooMachine NX (X2Go's default).
If it _does_ come up empty, then you can try installing it manually with
	sudo apt install x2gokdriveclient
If that package isn't available, or you experience instability, please make sure you're on a supported version of your distribution and/or try installing from X2Go's own repository/PPA, instead of your distribution's.

Instructions for Debian can be found [here](https://wiki.x2go.org/doku.php/wiki:repositories:debian).

Instructions for Ubuntu can be found [here](https://wiki.x2go.org/doku.php/wiki:repositories:ubuntu).

For other Linux distributions, check [this page](https://wiki.x2go.org/doku.php/doc:installation:x2goclient).

For Windows, try the preview build from [this directory](https://code.x2go.org/releases/binary-win32/x2goclient/previews/4.1.2.3/).

Sadly, there is currently no macOS support for KDrive. Sponsors welcome! See [here](https://wiki.x2go.org/doku.php/doc:sponsors) for more info on sponsoring X2Go's development.

### Tor connection setup

#### Install additional packages needed for the Tor connection
	<code>sudo apt install tor netcat</code>

#### Edit <code>~/.ssh/config</code> for the Tor connection
	Host X2GoTorBox
		Hostname YourOnionAddressGoesHere.onion
		ProxyCommand nc -X 5 -x 127.0.0.1:9050 %h %p

#### Configure X2GoClient for the Tor connection
1. Create a new session
2. Start with the "Session" Tab
3. Enter a Session name, like X2GoGoogleCloud
4. Enter X2GoTorBox as Host
5. Enter the username you chose in .gcs-x2go
6. Enter 222 as Port
7. Check "Try auto login" if you're using an SSH key
8. Select "XFCE4" or "Published Applications" as session type - if you are running a KDrive-enabled client, you can also try to check the "Run in X2GoKDrive" box right above this entry when using a full desktop environment. 
9. Go to the "Media" Tab
10. Un-Check "Enable Sound Support"
11. Click "OK"

### Google Cloud SDK connection setup

#### Install additional packages for the Google Cloud SDK connection
	<code>snap install google-cloud-sdk</code>

#### Configure your Google Cloud SDK client
1. Run <code>gcloud auth login</code>
2. Look for a new web browser window being spawned
3. Enter your credentials to authorize access to your account
4. Follow the instructions on screen regarding creating an SSH key pair etc. - make sure to pick a good passphrase (not password) for the key pair and store it somewhere safe.

#### Configure X2GoClient for the Google Cloud SDK connection
1. Create a new session
2. Start with the "Session" Tab
3. Enter a Session name, like X2GoGoogleCloud
4. Enter 127.0.0.1 as Host
5. Enter the username you chose in .gcs-x2go
6. Enter 222 as Port
7. Select "Use Proxy server for SSH connection"
8. Select Type "SSH"
9. Enter Host (IP), Port, and Username - IP (and possibly port as well) will likely change each time you start your Cloud Shell instance. 
10. Either specify the path to your Google Cloud Shell SSH Public Key File, or load the key into your SSH Agent and check the SSH Agent box.
11. Make sure you either keep your "gcloud cloud-shell ssh" session running or actually run the sshfs mount command suggested by <code>startserver-google-jumphost</code>and keep the sshfs mounted while you intend to use your X2Go Cloud Server. Do not forget to run "fusermount -u YOUR_SSHFS_MOUNTPOINT_HERE" once you are done if you used the sshfs command or your instance will keep running - remember, your usage is limited to a certain amount of hours in a seven-day window! *Note: The YOUR_SSHFS_MOUNTPOINT_HERE directory needs to exist before you can issue the sshfs mount command from step #1. Use the mkdir command if necessary.*
12. Check "Try auto login" if you're using an SSH key
13. Select "XFCE4" or "Published Applications" as session type - if you are running a KDrive-enabled client, you can also try to check the "Run in X2GoKDrive" box right above this entry when using a full desktop environment.
14. Go to the "Media" Tab
15. Un-Check "Enable Sound Support"
16. Click "OK"

### External Jumphost connection setup

#### Install additional packages for the External Jumphost connection
	None required.

#### Configure X2GoClient for the External Jumphost connection
1. Create a new session
2. Start with the "Session" Tab
3. Enter a Session name, like X2GoGoogleCloud
4. Enter 127.0.0.1 as Host
5. Enter the username you chose in .gcs-x2go
6. Enter 2345 as Port
7. Select "Use Proxy server for SSH connection"
8. Select Type "SSH"
9. Enter Host (IP), Port, and Username of your External Jumphost
10. Either specify the path to your SSH Public Key File, or load the key into your SSH Agent and check the SSH Agent box.
11. Check "Try auto login" if you're using an SSH key
12. Select "XFCE4" or "Published Applications" as session type - if you are running a KDrive-enabled client, you can also try to check the "Run in X2GoKDrive" box right above this entry when using a full desktop environment.
13. Go to the "Media" Tab
14. Un-Check "Enable Sound Support"
15. Click "OK"

# Starting a Connection
## How to start an X2Go Session
1. Make sure the Server side is up and running: Run <code>startserver-tor</code>, <code>startserver-google-jumphost</code> or <code>startserver-reversetunnel</code> on the **Server** (i.e. inside your cloud shell session) if you haven't done so already.
2. Only when using Tor: Unless you have set it to start automatically, start the Tor service on the **Client** (i.e. on your local machine) by running <code>sudo service tor start</code> *Note: It may take a few minutes before the server becomes available via the Tor network*
3. Start X2GoClient
4. Only when using the Google Cloud SDK: Make sure to follow the instructions on screen after running <code>startserver-google-jumphost</code> and update your SSH proxy settings in X2GoClient's session settings accordingly.
5. Start the Session by double-clicking on the *X2GoGoogleCloud* session tile.
6. If/when prompted, enter Username, Password, and 2FA code.

## Recommendations
1. Use Palemoon (it's installed automatically) for browsing the web when using X2Go's standard NX protocol - Chrome/Chromium and Firefox tend to be a bit sluggish that way. If you're using KDrive instead of NX, Chrome/Chromium and Firefox should work smoothly as well.
2. Keep an eye on your Google Cloud Shell browser window when running cloud shell via the web browser. Google might prompt you "Hey, are you still there?" if you seem to be inactive from their perspective, and if you don't respond, your Google Cloud Shell session will be terminated, crashing your server. Sadly, activity via Tor/SSH doesn't count, it needs to take place within the Google Cloud Shell browser window. This may be different for ssh sessions and sshfs mounts initiated using the Google Cloud SDK command line tool "gcloud".

## Shutting down
1. Properly terminate your session from within *X2GoClient*.
2. Run <code>stopserver</code> on the **Server** (i.e. inside your browser's cloud shell window) 
3. Once your Cloud Shell session expires, Google will purge the server installation, only the home directory will remain as long as your regular Cloud Shell home directory exists.
4. To manually purge the server, run <code>destroyserver</code> after it has been stopped with <code>stopserver</code>.
5. Stop the Tor service on your **Client** if you don't intend to keep it running. To stop it, run: <code>sudo service tor stop</code> on your local machine.

## Freezing and Thawing a server image
You can now "freeze" a server image using the <code>freezeserver</code> command. It will shut down the server, then create a <code>$SERVERNAME.tar.xz</code> tarball in <code>~/$SERVERNAME-home/</code>.
That way, packages you installed inside your changeroot will survive a shutdown. Note that a base installed server (taking up about 3.4GB uncompressed) will be compressed down to roughly 880MB, but this process takes about 30 minutes in which you need to stay connected to the cloud shell (i.e. you're "wasting" 30 minutes of your time contingent). A fresh install using <code>createserver</code>, where only your home directory is preserved, takes only about 10-12 minutes. "Thawing" a previously frozen server using <code>thawserver</code> takes only about two minutes, though. So with a more complex installation, freezing and thawing might be the better choice; for a run-off-the-mill server without any extra packages, creating it each time you need it will be faster overall.
