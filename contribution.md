# How to install and run VirtDB GUI on a new Debian 32bit machine?
This is a short description about installing virtdb-gui as a standalone component, so that we or GUI developers could
do a GUI test drive.

All steps `described with this style` are meant to be executed in the shell (bash, zsh, etc.)

### Prerequisities
```bash
apt-get install sudo
```

#### Node.js and getting source from git
1. `apt-get install sudo`
2. `sudo apt-get install curl`
3. `curl --silent --location https://deb.nodesource.com/setup_0.12 | sudo bash -`
4. `sudo apt-get install --yes nodejs`
5. `sudo npm install --global gulp`
6. `npm install --save-dev gulp`
7. Navigate to the folder where you would like to have virtdb-gui
8. `git clone https://github.com/starschema/virtdb-gui.git`

      (You might need to enter your github credentials here.)
   
#### ZeroMQ
09. `sudo apt-get install make, libtool, pkg-config, build-essential, autoconf, automake`
15. Download ZeroMQ from www.zeromq.org (when I downloaded the version was 4.1.2)
16. `sudo apt-get install uuid-dev`
17. `sudo apt-get install uuid`
18. Download libsodium from https://download.libsodium.org/doc/ (the version was 1.0.3)
19. Extract the downloaded libsodium and navigate to the extracted folder
20. `./autogen.sh`
21. `./configure`
22. `make`
23. `sudo make install`
24. Navigate to the extracted ZeroMQ folder
25. `./configure`
26. `make`
27. `sudo make install`

#### Protocol Buffers
28. Download Protocol Buffers v2.6.1 from https://github.com/google/protobuf/releases
29. Extract files and navigate to the extracted folder
30. `./configure`
31. `make`
32. `sudo make install`
33. `sudo apt-get install protobuf-compiler`

## Build VirtDB GUI
34. Navigate to the virtdb-gui folder
35. `npm install`
36. `gulp build --offline=true`
37. `node app.js --offline=true`


And now the GUI should be running on port 3000. (But you can check the output of node app.js command for the exact port.)