#!/usr/bin/env bash
# Made by Sinfallas <sinfallas@yahoo.com>
# Licence: GPL-2

curl -X POST "http://192.168.1.1:81/api/tokens" \
     -H "Content-Type: application/json" \
     -d '{
           "identity": "me@example.com",
           "secret": "123456789"
         }'
