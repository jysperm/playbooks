#!/usr/bin/env bash

BODY=$(cat $1)

for i in $(egrep '{{(.+)}}' $1)
do
  NAME=$(echo $i | sed 's/.*{{//' | sed 's/}}.*//')
  PASS=$(pass show $NAME)
  BODY=$(echo $BODY | sed "s|{{$NAME}}|$PASS|")
done

printf "%s\n" $BODY
