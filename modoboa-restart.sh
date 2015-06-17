# Restart
function restart {
        # to restart, use RESTART=true
        if $RESTART; then
                # PLACE RESTART COMMAND HERE:

                echo "Restarting uWSGI"
                /etc/init.d/uwsgi restart
        fi
}
