#!/bin/bash
set -eo pipefail

NUM_ATTEMPT=10
SERIES=1
WAIT_TIME=10m

cd "$(dirname "$0")"

mkdir ../results/$SERIES
pushd ../

for ((i=1; i<=NUM_ATTEMPT; i++)); do
    echo "Attempt $i: Start"
    terraform apply -auto-approve -no-color > ./results/$SERIES/"$i"_tf.log
    echo "Attempt $i: End. Destroying..."
    terraform destroy -auto-approve -no-color

    if [ "$i" -eq "$NUM_ATTEMPT" ]; then
        break
    fi

    next_attempt=$((i+1))
    echo "Wait $WAIT_TIME for the next attempt: $next_attempt"
    sleep "$WAIT_TIME"
done

popd
find ../results/$SERIES -name '*_tf.log' -print0 |
 xargs -0 grep azurerm_linux_virtual_machine |
 grep 'Creation complete after' |
 sed 's/Creation complete after/Creation complete after:/' |
 sed -e "s/^\.\.\/results\/$SERIES\///" |
 sed 's/_tf.log//' |
 sed -e 's/ \[id.*//' > ../results/$SERIES/extract_vm_creation_time.log

rm ../results/$SERIES/*_tf.log
