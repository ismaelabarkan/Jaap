#!/bin/sh
qdrant &
sleep 3
/app/dist/api
