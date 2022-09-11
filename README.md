# google-cloud-x2go-server
Scripts to create, start, stop and destroy an X2Go server in the free-as-in-beer Google Cloud environment
## How to prepare your Google Cloud Shell environment (only needed once per Google Account):
### Run these commands inside the Google Cloud Shell browser window
	git clone git@github.com:stefanbaur/google-cloud-x2go-server.git
	test -d gopath && mv gopath gopath_old
	ln -s google-cloud-x2go-server/gopath gopath
### Edit the file ~/.gcs-x2go (again, inside the Google Cloud Shell browser window)
	export SERVER_USE_ROOT=true
	export SERVERNAME=demoserver
	export CHROOTDEBVERSION="bullseye"
	export USERNAME=demouser
	export USERREALNAME="John Doe"
## How to set up and run the server:
1. Run this command inside the Google Cloud Shell browser window every time your instance was offline (or if you ran <code>destroyserver</code> before):<code>createserver</code>
2. To actually start the server, run <code>startserver-tor</code> inside the Google Cloud Shell browser window
(Note: <code>startserver-reversetunnel</code> is no longer actively tested or maintained, but still provided in case you prefer it over using Tor)
4. Load the QR code into an authenticator app of your choice
## How to prepare the client (only needed once per client)
### Install required packages
	sudo apt install tor netcat x2goclient
### Edit ~/.ssh/config:
	Host X2GoTorBox
		Hostname YourOnionAddressGoesHere.onion
		ProxyCommand nc -X 5 -x 127.0.0.1:9050 %h %p</code>
### Configure X2GoClient
1. Create a new session
2. Start with the "Session" Tab
3. Enter a Session name, like X2GoGoogleCloud
4. Enter 127.0.0.1 as Host
5. Enter the username you chose in .gcs-x2go
6. Enter 222 as Port
7. Check "Try auto login" if you're using an SSH key
8. Check the "Use Proxy server for SSH connection" box *This is actually a workaround as X2GoClient seems to crash during the connection phase when using the X2GoTorBox alias or the Onion-Address directly*
9. Select "SSH" as Proxy Type
10. Enter "X2GoTorBox" as the Proxy Host name
11. Enter 222 as Proxy Port
12. Check the "Same login as on X2GoServer" box
13. Check the "Same password as on X2GoServer" box 
14. Check "SSH Agent or default SSH key" if you're using an SSH key
15. Select "XFCE4" or "Published Applications" as session type
16. Go to the "Media" Tab
17. Un-Check "Enable Sound Support"
18. Click "OK"
## How to start an X2Go Session
1. Make sure the Server side is up and running: Run <code>startserver-tor</code> on the **Server** (i.e. inside your browser's cloud shell window) if you haven't done so already.
2. Unless you have set it to start automatically, start the Tor service on the **Client** (i.e. on your local machine) by running <code>sudo service tor start</code> *Note: It may take a few minutes before the server becomes available via the Tor network*
3. Start X2GoClient
4. Start the Session by double-clicking on the *X2GoGoogleCloud* session tile.
5. If/when prompted, enter Username, Password, and 2FA code.
## Recommendation
Use Palemoon (it's installed automatically) for browsing the web - Chrome/Chromium and Firefox tend to be a bit sluggish via X2Go-NX. This may change once X2Go-KDrive becomes stable.
## Shutting down
1. Properly terminate your session from within *X2GoClient*.
2. Run <code>stopserver</code> on the **Server** (i.e. inside your browser's cloud shell window) 
3. Once your Cloud Shell session expires, Google will purge the server installation, only the home directory will remain as long as your regular Cloud Shell home directory exists.
4. To manually purge the server, run <code>destroyserver</code> after it has been stopped with <code>stopserver</code>.
5. Stop the Tor service on your **Client** if you don't intend to keep it running. To stop it, run: <code>sudo service tor stop</code> on your local machine.
