#!/bin/bash

SERVER_DIR=`dirname $0`
cd $SERVER_DIR

echo 'CREATE TABLE api_key (id INTEGER NOT NULL, api_key VARCHAR(32), user_id INTEGER NOT NULL, PRIMARY KEY (id), UNIQUE (api_key), FOREIGN KEY(user_id) REFERENCES user (id));' | sqlite3 mhn.db

echo "SELECT id FROM user;" | sqlite3 mhn.db | while read USER_ID; 
do 
    APIKEY=$(python -c 'import uuid; print str(uuid.uuid4()).replace("-", "")'); 
    echo "INSERT INTO api_key (api_key,user_id)VALUES('$APIKEY', '$USER_ID');" | sqlite3 mhn.db; 
done

