     #!/bin/bash

     # A variable to hold an array of all the plugins to be installed

     plugins=(
     workflow-basic-steps:948.v2c72a_091b_b_68
     blueocean:1.27.4 
     credentials-binding:604.vb_64480b_c56ca_
     git-changelog:3.30
     git-client:4.2.0
     git-server:99.va_0826a_b_cdfa_d
     git:5.0.1
     )

     # A for loop to iterate over the plugins array, and execute the jenkins-plugin-cli command to instal each plugin.

     for plugin in "${plugins[@]}"
     do
       echo "Installing ${plugin}"
       jenkins-plugin-cli --plugins ${plugin}
     done