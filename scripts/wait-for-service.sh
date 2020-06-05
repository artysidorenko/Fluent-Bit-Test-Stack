#!/bin/sh
# wait-for-service.sh

echo hello

unavailable()
{
  >&2 echo "$1 is unavailable - waiting $2 seconds"
  sleep $2
  continue
}

set -e

service="$1"
host="$2"
port="$3"
pause="5"

# Remove service, host and port from arguments array
shift 3
cmd="$@"

# Keep polling until service is available
while true; do
  # (--spider checks for response size, throws error if unreachable)
  wget --spider $host:$port || unavailable $service $pause
  break
done

>&2 echo "$service endpoint is up - executing next command"

# Execute remaining arguments
exec $cmd


