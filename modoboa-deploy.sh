#!/bin/bash

#
# Modoboa redeployment script
#

DATE=$(date +%Y-%m-%d-%H%M)

source modoboa-deploy.ini
source modoboa-restart.ini

VERSION=$2

# Backup old instance
function backup {
        if [ ! -d $BACKUPDIR ]; then
                echo "Creating backup folder"
                mkdir -p $BACKUPDIR
        fi
        if [ -d $DIR ]; then
                echo "Backing up old modoboa deployment to $BACKUPDIR/$DIR-$DATE"
                mv $DIR $BACKUPDIR/$DIR-$DATE
        fi
}


# Install modoboa
function modoboa_update {
        echo "Installing modoboa-$VERISON"
        pip install modoboa==$VERSION
}

# Force reinstall of modoboa
function modoboa_upgrade {
        echo "Forcing modoboa-$VERSION reinstall"
        pip install --upgrade modoboa==$VERSION
}

# Redeploy modoboa
function redeploy {
        echo "Redeploying modoboa"
        cd $SYSDIR
        modoboa-admin.py deploy $DIR \
                --collectstatic \
                --domain $DOMAIN \
                --lang $LANG \
                --timezone $TZ \
                --extensions modoboa_admin modoboa_stats modoboa_sievefilters modoboa_amavis modoboa_webmail \
                --dburl default:$DBTYPE://$MAINDBUSER:$MAINDBPW@$HOST:$PORT/$MAINDB amavis:$DBTYPE_AMAVIS://$AMAVISDBUSER:$AMAVISDBPW@$AMAVIS_HOST:$AMAVIS_PORT/$AMAVISDB
}

# Patch settings.py file
function settings {
        # to patch setting, use PATCHSETTINGS=true
        if $PATCHSETTINGS; then
                echo "Patching $SYSDIR/$DIR/$DIR/$MCONF"
                # replace sitestatic string
                sed -i "s,${SITESTATICDIR_ORIG},${SITESTATICDIR_NEW},g" $SYSDIR/$DIR/$DIR/$MCONF
                # replace media string
                sed -i "s,${MEDIADIR_ORIG},${MEDIADIR_NEW},g" $SYSDIR/$DIR/$DIR/$MCONF

                # make new line
                echo "" >> $SYSDIR/$DIR/$DIR/$MCONF
                # if deployed in subdirectory, LOGIN_URL is mandatory in order for modoboa to work
                echo "LOGIN_URL = '$SUBDIR/accounts/login/'" >> $SYSDIR/$DIR/$DIR/$MCONF

                # to use own logo, use OWNLOGO=true
                if $OWNLOGO; then
                        # we use our own logo
                        echo "MODOBOA_CUSTOM_LOGO = os.path.join(MEDIA_URL, '$LOGO')" >> $SYSDIR/$DIR/$DIR/$MCONF
                        cp $LOGO $SYSDIR/$DIR/$MEDIADIR_ORIG.
                fi
        fi
}

# redeploy only
function std {
        backup
        redeploy
        settings
        restart
}

# update only
function update {
        backup
        modoboa_update
        redeploy
        settings
        restart
}

# force update
function upgrade {
        backup
        modoboa_upgrade
        redeploy
        settings
        restart
}

# default output
function help {
        echo "Options:"
        echo "std               backup, redeploy and patch settings"
        echo "update X.X.X      reinstall modoboa via pip install modoboa==X.X.X additionaly to std"
        echo "upgrade X.X.X     reinstall modoboa via pip install --upgrade modoboa==X.X.X additionaly to std"
}

# what to do, if...
if [ -z "$1" ]
        then help
elif [ $1 == "std" ]
        then std
elif [ $1 == "update" ]
        then update
elif [ $1 == "upgrade" ]
        then upgrade
fi
