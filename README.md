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
	export CHROOTDEBVERSION="bullseye"
	export USERNAME=demouser
	export USERREALNAME="John Doe"
	# optional - allowed values are "stable", "heuler" (nightly builds), and "saimaa" (ESR)
	export USEX2GOREPO="stable"
	# experimental - setting this to true will force USEX2GOREPO to "heuler"
	export X2GOHTML5=false
*Note: Feel free to change the values of <code>SERVERNAME</code>, <code>USERNAME</code>, and <code>USERREALNAME</code>, but remember that setting any of the username or servername values to a name usually associated with you will mean you are no longer anonymous.*
## How to set up and run the server
1. Run this command inside the Google Cloud Shell browser window every time your instance was offline (or if you ran <code>destroyserver</code> before):<code>createserver</code>
2. To actually start the server, run <code>startserver-tor</code> inside the Google Cloud Shell browser window
(Note: <code>startserver-reversetunnel</code> is no longer actively tested or maintained, but still provided in case you prefer it over using Tor)
4. Load the QR code into an authenticator app of your choice *(Note: the QR code will remain the same unless the server's home directory gets deleted)* and copy the emergency codes to a safe location
## How to prepare the client (only needed once per client)
### Install required packages
	sudo apt install tor netcat x2goclient
### Edit ~/.ssh/config
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
15. Select "XFCE4" or "Published Applications" as session type - if the command <code>dpkg -l x2gokdriveclient | grep "^ii"</code> does not return an empty result on your client, you can also try to check the "Run in X2GoKDrive" box right above this entry.
16. Go to the "Media" Tab
17. Un-Check "Enable Sound Support"
18. Click "OK"
## How to start an X2Go Session
1. Make sure the Server side is up and running: Run <code>startserver-tor</code> on the **Server** (i.e. inside your browser's cloud shell window) if you haven't done so already.
2. Unless you have set it to start automatically, start the Tor service on the **Client** (i.e. on your local machine) by running <code>sudo service tor start</code> *Note: It may take a few minutes before the server becomes available via the Tor network*
3. Start X2GoClient
4. Start the Session by double-clicking on the *X2GoGoogleCloud* session tile.
5. If/when prompted, enter Username, Password, and 2FA code.
## Recommendations
1. Use Palemoon (it's installed automatically) for browsing the web - Chrome/Chromium and Firefox tend to be a bit sluggish via X2Go-NX. *This may change once X2Go-KDrive becomes stable.*
2. Keep an eye on your Google Cloud Shell browser window. Google might prompt you "Hey, are you still there?" if you seem to be inactive from their perspective, and if you don't respond, your Google Cloud Shell session will be terminated, crashing your server. Sadly, activity via Tor/SSH doesn't count, it needs to take place within the Google Cloud Shell browser window.
## Shutting down
1. Properly terminate your session from within *X2GoClient*.
2. Run <code>stopserver</code> on the **Server** (i.e. inside your browser's cloud shell window) 
3. Once your Cloud Shell session expires, Google will purge the server installation, only the home directory will remain as long as your regular Cloud Shell home directory exists.
4. To manually purge the server, run <code>destroyserver</code> after it has been stopped with <code>stopserver</code>.
5. Stop the Tor service on your **Client** if you don't intend to keep it running. To stop it, run: <code>sudo service tor stop</code> on your local machine.

## Freezing and Thawing a server image
You can now "freeze" a server image using the <code>freezeserver</code> command. It will shut down the server, then create a <code>$SERVERNAME.tar.xz</code> tarball in <code>~/$SERVERNAME-home/</code>.
That way, packages you installed inside your changeroot will survive a shutdown. Note that a base installed server (taking up about 3.4GB uncompressed) will be compressed down to roughly 880MB, but this process takes about 30 minutes in which you need to stay connected to the cloud shell (i.e. you're "wasting" 30 minutes of your time contingent). A fresh install using <code>createserver</code>, where only your home directory is preserved, takes only about 10-12 minutes. "Thawing" a previously frozen server using <code>thawserver</code> takes only about two minutes, though. So with a more complex installation, freezing and thawing might be the better choice; for a run-off-the-mill server without any extra packages, creating it each time you need it will be faster overall.
