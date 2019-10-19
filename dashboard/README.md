# Smashing Dashboard for PeekabooAV



### Installing:

* Run ```install.sh```

  * It installs dependencies for smashing

* Install ```updatePostfixStats.sh``` as a cronjob on the machine that runs Postfix usually the same machine that runs PeekabooAV

  * ```bash
    crontab -e
    
    # this runs updatePostfixStats.sh every 10 seconds
    * * * * * ( updatePostfixStats.sh )  
    * * * * * ( sleep 10 ; updatePostfixStats.sh )  
    * * * * * ( sleep 20 ; updatePostfixStats.sh )  
    * * * * * ( sleep 30 ; updatePostfixStats.sh )  
    * * * * * ( sleep 40 ; updatePostfixStats.sh )  
    * * * * * ( sleep 50 ; updatePostfixStats.sh )
    ```

* Place ```updatePeekabooStats.sh``` 

  * Install ```updatePeekabooStats.sh``` as a cronjob on the machine that runs PeekabooAV

  * ```bash
    crontab -e
    
    # this runs updatePeekabooStats.sh every 10 seconds
    * * * * * ( updatePeekabooStats.sh )  
    * * * * * ( sleep 10 ; updatePeekabooStats.sh )  
    * * * * * ( sleep 20 ; updatePeekabooStats.sh )  
    * * * * * ( sleep 30 ; updatePeekabooStats.sh )  
    * * * * * ( sleep 40 ; updatePeekabooStats.sh )  
    * * * * * ( sleep 50 ; updatePeekabooStats.sh )
    ```

  * 

