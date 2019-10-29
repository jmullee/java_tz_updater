# java_tz_updater

Linux bash script to update java timezone database

This has been tested on debian/ubuntu type host with Java *8*

tzupdater.jar is from :

    https://www.oracle.com/technetwork/java/javase/tzupdater-readme-136440.html#installation

    see that page for how to download tzupdater.jar.

installation :

    as root:

        # install dependencies
        apt install coreutils findutils git grep lzip make openjdk-8-jre-headless sudo tar wget

        # create user
        adduser tzupdateuser

        # add sudoers file (make sure to set JAVA_HOME first)
        echo "tzupdateuser ALL=(ALL) NOPASSWD: ${JAVA_HOME}/bin/java" > /etc/sudoers.d/javatzupdate

        # copy files to users home dir
        cp upd_tz_db.sh /home/tzupdateuser/
        cp tzupdater.jar /home/tzupdateuser/

        # set appropriate permissions
        chown tzupdateuser /home/tzupdateuser/*
        chmod 0600 /home/tzupdateuser/tzupdater.jar
        chmod 0700 /home/tzupdateuser/upd_tz_db.sh

        # setup monthly cron
        echo -e "#!/bin/sh\nsudo -u tzupdateuser /home/tzupdateuser/upd_tz_db.sh\n" > /etc/cron.monthly/javatzupdate
