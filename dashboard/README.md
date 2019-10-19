# Smashing Dashboard for PeekabooAV



### Installing:

- Run ```install.sh```

  - It adds a new user called peekaboo-dashboard and installs the dependencies

- Edit ```updatePostfixStats.sh``` and ```updatePeekabooStats.sh``` and change $DASHBOARD_URL to your setup (the IP/hostname of the machine that is serving the dashboard is needed)

- Install ```updatePostfixStats.sh``` as a cronjob on the machine that runs Postfix usually the same machine that runs PeekabooAV

  - ```bash
    crontab -e
    
    # TODO: replace path with the location of th script
    
    # this runs updatePostfixStats.sh every 10 seconds
    * * * * * ( /home/peekaboo/updatePostfixStats.sh )  
    * * * * * ( sleep 10 ; /home/peekaboo-dashboard/updatePostfixStats.sh )  
    * * * * * ( sleep 20 ; /home/peekaboo-dashboard/updatePostfixStats.sh )  
    * * * * * ( sleep 30 ; /home/peekaboo-dashboard/updatePostfixStats.sh )  
    * * * * * ( sleep 40 ; /home/peekaboo-dashboard/updatePostfixStats.sh )  
    * * * * * ( sleep 50 ; /home/peekaboo-dashboard/updatePostfixStats.sh )
    ```

- Place ```updatePeekabooStats.sh``` 

  - Install ```updatePeekabooStats.sh``` as a cronjob on the machine that runs PeekabooAV

  - ```bash
    crontab -e
    
    # this runs updatePeekabooStats.sh every 10 seconds
    * * * * * ( /home/peekaboo-dashboard/updatePeekabooStats.sh )  
    * * * * * ( sleep 10 ; /home/peekaboo-dashboard/updatePeekabooStats.sh )  
    * * * * * ( sleep 20 ; /home/peekaboo-dashboard/updatePeekabooStats.sh )  
    * * * * * ( sleep 30 ; /home/peekaboo-dashboard/updatePeekabooStats.sh )  
    * * * * * ( sleep 40 ; /home/peekaboo-dashboard/updatePeekabooStats.sh )  
    * * * * * ( sleep 50 ; /home/peekaboo-dashboard/updatePeekabooStats.sh )
    ```

  - 
