#!/usr/bin/env bash
# Builds the OSB config jar from the sources under projects/ and imports it into
# the running domain. Both steps run inside the osbms1 container, which is where
# the OSB tooling lives. Run this from the host once the stack is up.
#
# Note on set -e: setenv.sh returns a non-zero status, so sourcing it under
# set -e aborts the script before configjar ever runs. The commands inside the
# container are therefore deliberately not run under set -e.
set -uo pipefail

CONTAINER=osbms1
CONFIGJAR_HOME=/u01/oracle/osb/tools/configjar

run_in_container() {
  podman exec "$CONTAINER" bash -c "
    mkdir -p /tmp/osb-demo
    export MW_HOME=/u01/oracle
    cd $CONFIGJAR_HOME
    . ./setenv.sh > /dev/null 2>&1
    $1
  " 2>&1
}

echo "==> Building config jar"
build_out=$(run_in_container "./configjar.sh -settingsfile /u01/osb-demo/configjar-settings.xml")
if ! grep -q 'created successfully' <<<"$build_out"; then
  echo "Build failed:"
  grep -E '<Error>|<Warning>|severe' <<<"$build_out" | sed 's/^.*BEA-000000> //'
  exit 1
fi
echo "    config jar built"

echo "==> Importing into the domain"
import_out=$(run_in_container "./wlst.sh /u01/osb-demo/import.py")
# Report validation results and the activation outcome. The SOA WLST extensions
# print unrelated NoClassDefFoundError noise on startup, which is filtered out.
grep -E 'Discarding stale|Activated|imported:|Import failed|Valid$|CannotCommit|Invalid xml' <<<"$import_out" \
  | sed 's/^/    /'

if ! grep -q 'Activated' <<<"$import_out"; then
  echo "==> Import did not activate. Full validation detail:"
  grep -E 'CannotCommit|Invalid xml|Expected' <<<"$import_out" | sed 's/^/    /'
  exit 1
fi

echo "==> Done. Try it with:"
echo "    curl -s -X POST -H 'Content-Type: application/json' \\"
echo "         -d '{\"hello\":\"world\"}' http://localhost:8002/demo/echo"
