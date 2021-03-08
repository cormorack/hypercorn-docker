#! /usr/bin/env sh
set -e

if [ -f /app/app/main.py ]; then
    DEFAULT_MODULE_NAME=app.main
elif [ -f /app/main.py ]; then
    DEFAULT_MODULE_NAME=main
fi
MODULE_NAME=${MODULE_NAME:-$DEFAULT_MODULE_NAME}
VARIABLE_NAME=${VARIABLE_NAME:-app}
export APP_MODULE=${APP_MODULE:-"$MODULE_NAME:$VARIABLE_NAME"}

if [ -f /app/hypercorn_conf.py ]; then
    DEFAULT_HYPERCORN_CONF=/app/hypercorn_conf.py
elif [ -f /app/app/hypercorn_conf.py ]; then
    DEFAULT_HYPERCORN_CONF=/app/app/hypercorn_conf.py
else
    DEFAULT_HYPERCORN_CONF=/hypercorn_conf.py
fi
export HYPERCORN_CONF=${HYPERCORN_CONF:-$DEFAULT_HYPERCORN_CONF}
export WORKER_CLASS=${WORKER_CLASS:-"asyncio"}

# If there's a prestart.sh script in the /app directory or other path specified, run it before starting
PRE_START_PATH=${PRE_START_PATH:-/app/prestart.sh}
echo "Checking for script in $PRE_START_PATH"
if [ -f $PRE_START_PATH ] ; then
    echo "Running script $PRE_START_PATH"
    . "$PRE_START_PATH"
else 
    echo "There is no script $PRE_START_PATH"
fi

# Start Gunicorn
exec hypercorn -k "$WORKER_CLASS" -c "file:$HYPERCORN_CONF" "$APP_MODULE"
