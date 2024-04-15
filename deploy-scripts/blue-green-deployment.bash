#!/bin/bash

ACTIVE_COLOR_FILE_PATH="/code/active-color.txt"
BLUE_CONF="/etc/nginx/sites-available/blue.conf"
GREEN_CONF="/etc/nginx/sites-available/green.conf"
ACTIVE_CONF="/etc/nginx/sites-enabled/active.conf"
NGINX_FOLDER="/usr/share/nginx/html"

# We emulate a typical application deployment process
# relying on a relational database that requires database schema migrations
# before the application can be started.
if [ -z "$1" ]; then
    echo "Please provide a version number matching a top-level name in the app-versions directory"
    exit 1
fi

mockDatabaseMigrations() {
    echo "checking database migrations..."
    sleep 2
    echo "applying 5 migration found..."
    for i in {1..5}; do
        echo -n "Update DB Table $i ..."
        sleep 1
        echo " OK"
    done
}

mockStartDelay() {
    echo "Starting application $1..."
    sleep 2
    echo "Application $1 started successfully"
}

moveFiles() {
    dest="$NGINX_FOLDER/$2/index.html"
    echo "Moving files from $1 to $dest"
    cp $NGINX_FOLDER/app-versions/$1/index.html $dest
    echo "Files moved successfully"
}

reloadNginx() {
    service nginx reload
}

switchToGreen() {
    echo "Switching to green"
    echo "green" >$ACTIVE_COLOR_FILE_PATH
    cp $GREEN_CONF $ACTIVE_CONF
    reloadNginx
}

switchToBlue() {
    echo "Switching to blue"
    echo "blue" >$ACTIVE_COLOR_FILE_PATH
    cp $BLUE_CONF $ACTIVE_CONF
    reloadNginx
}

doBlueGreenDeployment() {
    # find the active color
    echo "Deployment started for $1"

    if [ -f $ACTIVE_COLOR_FILE_PATH ]; then
        ACTIVE_COLOR=$(cat $ACTIVE_COLOR_FILE_PATH)
    else
        # green as default color if no active color is found
        # it means that the next deployment will be blue
        echo "green" >$ACTIVE_COLOR_FILE_PATH
        ACTIVE_COLOR="green"
    fi
    # deploy new color
    if [ $ACTIVE_COLOR == "blue" ]; then
        NEW_COLOR="green"
        moveFiles $1 $NEW_COLOR
        mockDatabaseMigrations
        mockStartDelay $1
        switchToGreen
    else
        NEW_COLOR="blue"
        moveFiles $1 $NEW_COLOR
        mockDatabaseMigrations
        mockStartDelay $1
        switchToBlue
    fi
    echo "Deployment completed for $1 (new color: $NEW_COLOR)"
    exit 0
}

doBlueGreenDeployment $1
