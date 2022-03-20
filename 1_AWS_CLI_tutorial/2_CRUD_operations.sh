#!/bin/bash

# Author: Katerina Bosko

# Example AWS CLI commands to perform CRUD operations in DynamoDB
# Requires sample data imported into local instance of DynamoDB
# To install DynamoDB locally see README
# To import data run `./1_import_data_to_dynamodb.sh`

# This tutorial is based on
# Amazon DynamoDB Labs > Hands-on Labs for Amazon DynamoDB
# https://master.amazon-dynamodb-labs.com/hands-on-labs.html
# adopted to work on local machine and run as a bash script

# Output is saved into ./output/2_output.txt

# NOTE: there are differences between DynamoDB that runs locally and the DynamoDB Web Service
# see them here: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.UsageNotes.html
# For instance, provisioned throughput settings are ignored in downloadable DynamoDB
# so you will see "ConsumedCapacity": null
# when querying/scanning data in DynamoDB local version

mkdir output
#==============================
# READING SAMPLE DATA
#==============================
echo 'READING SAMPLE DATA' | tee ./output/2_output.txt
# the simplest way to get all data from a table is with scan command
# however, scans are costly! (see SCANS section)
echo 'retrieve all data from ProductCatalog table' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager scan \
    --table-name ProductCatalog \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

echo 'get information about product with id=101 from ProductCatalog'
aws dynamodb get-item \
    --table-name ProductCatalog \
    --key '{"Id":{"N":"101"}}' \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt


#==============================
# CREATE
#==============================
echo 'CREATE' | tee -a ./output/2_output.txt
echo 'add item to Reply table with key Amazon DynamoDB#DynamoDB Thread 2' | tee -a ./output/2_output.txt
aws dynamodb put-item \
    --table-name Reply \
    --item '{
        "Id" : {"S": "Amazon DynamoDB#DynamoDB Thread 2"},
        "ReplyDateTime" : {"S": "2021-04-27T17:47:30Z"},
        "Message" : {"S": "DynamoDB Thread 2 Reply 3 text"},
        "PostedBy" : {"S": "User C"}
    }' \
    --endpoint-url http://localhost:8000

echo 'check if item is added' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager get-item \
    --table-name Reply \
    --key '{"Id" : {"S": "Amazon DynamoDB#DynamoDB Thread 2"},
           "ReplyDateTime" : {"S": "2021-04-27T17:47:30Z"}}' \
    --projection-expression "Id, ReplyDateTime, Message, PostedBy" \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

#==============================
# UPDATE
#==============================
echo 'UPDATE' | tee -a ./output/2_output.txt
echo 'check number of messages for Forum item with key Amazon DynamoDB' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager get-item \
    --table-name Forum \
    --key '{
        "Name" : {"S": "Amazon DynamoDB"}
    }' \
    --projection-expression "Messages" \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

echo 'update Forum item to note that there are 5 messages now instead of 4' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager update-item \
    --table-name Forum \
    --key '{
        "Name" : {"S": "Amazon DynamoDB"}
    }' \
    --update-expression "SET Messages = :newMessages" \
    --condition-expression "Messages = :oldMessages" \
    --expression-attribute-values '{
        ":oldMessages" : {"N": "4"},
        ":newMessages" : {"N": "5"}
    }' \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

echo 'check if item is updated' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager get-item \
    --table-name Forum \
    --key '{
        "Name" : {"S": "Amazon DynamoDB"}
    }' \
    --projection-expression "Messages" \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt


echo 'check colors for ProductCatalog item where Id=201' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager get-item \
    --table-name ProductCatalog \
    --key '{"Id":{"N":"201"}}' \
    --projection-expression "Color" \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

echo 'update the ProductCatalog item where Id=201 to add new colors “Blue” and “Yellow” to the list of colors for that bike type' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager update-item \
    --table-name ProductCatalog \
    --key '{"Id":{"N":"201"}}' \
    --update-expression "SET Color = list_append(Color, :newColors)" \
    --expression-attribute-values '{
        ":newColors" : {
            "L": [
                {"S" : "Blue"},
                {"S" : "Yellow"}
            ]
        }
    }' \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

echo 'check if updated' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager get-item \
    --table-name ProductCatalog \
    --key '{"Id":{"N":"201"}}' \
    --projection-expression "Color" \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt


echo 'undo previous update' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager update-item \
    --table-name ProductCatalog \
    --key '{"Id":{"N":"201"}}' \
    --update-expression "REMOVE #Color[2], #Color[3]" \
    --expression-attribute-names '{"#Color": "Color"}' \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

echo 'check if previous update is undone' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager get-item \
    --table-name ProductCatalog \
    --key '{"Id":{"N":"201"}}' \
    --projection-expression "Color" \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

#==============================
# DELETE
#==============================
echo 'DELETE' | tee -a ./output/2_output.txt
echo 'get Reply item with sort key 2021-04-27 that will be deleted' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager get-item \
    --table-name Reply \
    --key '{
        "Id" : {"S": "Amazon DynamoDB#DynamoDB Thread 2"},
        "ReplyDateTime" : {"S": "2021-04-27T17:47:30Z"}
    }' \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

echo 'delete previously inserted item in Reply table (see Insert)' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager delete-item \
    --table-name Reply \
    --key '{
        "Id" : {"S": "Amazon DynamoDB#DynamoDB Thread 2"},
        "ReplyDateTime" : {"S": "2021-04-27T17:47:30Z"}
    }' \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

echo 'check if deleted by scanning ReplyDateTime attribute for all items in Reply table' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager scan \
    --table-name Reply \
    --projection-expression "ReplyDateTime" \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

# Usually you can't aggregate in NoSQL databases unlike RDBMS
# Hence you need to update all running constants on your own
# Here we track number of messages in Forum table
# so after deleting a message in previous step, we need to update the counter
echo 'update Forum messages counter after delete' | tee -a ./output/2_output.txt
aws dynamodb --no-cli-pager update-item \
    --table-name Forum \
    --key '{
        "Name" : {"S": "Amazon DynamoDB"}
    }' \
    --update-expression "SET Messages = :newMessages" \
    --condition-expression "Messages = :oldMessages" \
    --expression-attribute-values '{
        ":oldMessages" : {"N": "5"},
        ":newMessages" : {"N": "4"}
    }' \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt

echo 'check that Forum messages counter is updated (should be 4)'
aws dynamodb --no-cli-pager get-item \
    --table-name Forum \
    --key '{
        "Name" : {"S": "Amazon DynamoDB"}
    }' \
    --projection-expression "Messages" \
    --endpoint-url http://localhost:8000 >> ./output/2_output.txt
