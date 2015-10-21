virtdb-gui
==========

The user interface of VirtDB.

### Authentication ###
  The GUI contains a basic http authentication which can be turned on by creating a file with name ```auth.json```. This file should contain two property ```user``` and ```password```.
  
### SSL/TLS ###
  If you would like to have the GUI running on https instead of http, you need to make sure that there is a server certificate in the ./ssl folder.
  If you don't have the certificate yet, you can easily generate a self-signed one by running
  
  ``` ./create-local-server-cert.sh```
  
  command.
