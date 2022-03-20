#!/bin/bash

# Author: Katerina Bosko

# Creates a transaction and Global Secondary Index (GSI) in local instance of DynamoDB
# IMPORTANT: this script requires installed jq for parsing JSON

# Requires sample data imported into local instance of DynamoDB
# To install DynamoDB locally see README
# To import data run `./1_import_data_to_dynamodb.sh`

# Output is saved into ./output/4_output.txt

# This tutorial is based on
# Amazon DynamoDB Labs > Hands-on Labs for Amazon DynamoDB
# https://master.amazon-dynamodb-labs.com/hands-on-labs.html
# adopted to work on local machine and run as bash script

# NOTE: there are differences between DynamoDB that runs locally and the DynamoDB Web Service
# see them here: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.UsageNotes.html
# For instance, provisioned throughput settings are ignored in downloadable DynamoDB
# so you will see "ConsumedCapacity": null
# when querying/scanning data in DynamoDB local version

#==============================
# TRANSACTIONS
#==============================
# In DynamoDB you can specify a transaction that groups up to 25 action requests into a synchronous write operation
# (subject to an aggregate 4MB size limit for the transaction)
# These actions can target items in different tables, but not in different AWS accounts or Regions,
# and no two actions can target the same item.
# completed ATOMICALLY so that either all of the actions succeed, or all of them fail.
# Also, you can't execute the same transaction with the same --client-request-token more than once
# so if you rerun this script, you will see no updates

# Previously we needed to perform two actions in separate steps - put new message into Reply table
# and update the counter
# These are good candidates for a transaction, since we want "all or nothing" as a result

echo 'check current Forum counter before transaction' | tee -a ./output/4_output.txt
aws dynamodb --no-cli-pager get-item \
    --table-name Forum \
    --key '{
        "Name" : {"S": "Amazon DynamoDB"}
    }' \
    --projection-expression "Messages" \
    --endpoint-url http://localhost:8000 >> ./output/4_output.txt

echo 'create transaction for adding a message to Reply table and updating message counter in Forum table' | tee -a ./output/4_output.txt
aws dynamodb transact-write-items --no-cli-pager --client-request-token TRANSACTION-1 --transact-items '[
    {
        "Put": {
            "TableName" : "Reply",
            "Item" : {
                "Id" : {"S": "Amazon DynamoDB#DynamoDB Thread 2"},
                "ReplyDateTime" : {"S": "2021-05-16T14:22:31Z"},
                "Message" : {"S": "DynamoDB Thread 2 Reply 4 text"},
                "PostedBy" : {"S": "User C"}
            }
        }
    },
    {
        "Update": {
            "TableName" : "Forum",
            "Key" : {"Name" : {"S": "Amazon DynamoDB"}},
            "UpdateExpression": "ADD Messages :inc",
            "ExpressionAttributeValues" : { ":inc": {"N" : "1"} }
        }
    }
]' \
--endpoint-url http://localhost:8000

echo 'check if item is added' | tee -a ./output/4_output.txt
aws dynamodb --no-cli-pager get-item \
    --table-name Reply \
    --key '{"Id" : {"S": "Amazon DynamoDB#DynamoDB Thread 2"},
           "ReplyDateTime" : {"S": "2021-05-16T14:22:31Z"}}' \
    --projection-expression "Id, ReplyDateTime, Message, PostedBy" \
    --endpoint-url http://localhost:8000 >> ./output/4_output.txt

echo 'check if Forum counter is updated' | tee -a ./output/4_output.txt
aws dynamodb --no-cli-pager get-item \
    --table-name Forum \
    --key '{
        "Name" : {"S": "Amazon DynamoDB"}
    }' \
    --projection-expression "Messages" \
    --endpoint-url http://localhost:8000 >> ./output/4_output.txt

#==============================
# INDEXING
#==============================
# because full scans are expensive in DynamoDB (see SCANS section in 2_CRUD_operations.sh),
# we can make use of indexing to save on costs and improve performance


echo 'create Global Secondary Index (GSI) on all attributes in Reply table' | tee -a ./output/4_output.txt
aws dynamodb --no-cli-pager update-table \
    --table-name Reply \
    --attribute-definitions AttributeName=PostedBy,AttributeType=S AttributeName=ReplyDateTime,AttributeType=S \
    --global-secondary-index-updates '[{
        "Create":{
            "IndexName": "PostedBy-ReplyDateTime-gsi",
            "KeySchema": [
                {
                    "AttributeName" : "PostedBy",
                    "KeyType": "HASH"
                },
                {
                    "AttributeName" : "ReplyDateTime",
                    "KeyType" : "RANGE"
                }
            ],
            "ProvisionedThroughput": {
                "ReadCapacityUnits": 5, "WriteCapacityUnits": 5
            },
            "Projection": {
                "ProjectionType": "ALL"
            }
        }
    }
]' \
--endpoint-url http://localhost:8000 >> ./output/4_output.txt


echo 'checking if GSI is ready  --> status should be "ACTIVE" instead of "CREATING"' | tee -a ./output/4_output.txt

STATUS=$(aws dynamodb --no-cli-pager describe-table --table-name Reply --endpoint-url http://localhost:8000 | jq -r '.Table.GlobalSecondaryIndexes | .[0].IndexStatus')
echo $STATUS

while [ $STATUS == "CREATING" ]
do
   echo $STATUS
   STATUS=$(aws dynamodb --no-cli-pager describe-table --table-name Reply --endpoint-url http://localhost:8000 | jq -r '.Table.GlobalSecondaryIndexes | .[0].IndexStatus')
done

echo 'find all the Replies written by User C using query command and index' | tee -a ./output/4_output.txt
aws dynamodb --no-cli-pager query \
    --table-name Reply \
    --index-name PostedBy-ReplyDateTime-gsi \
    --key-condition-expression 'PostedBy = :user' \
    --expression-attribute-values '{
        ":user" : {"S": "User C"}
    }' \
    --endpoint-url http://localhost:8000 >> ./output/4_output.txt

echo 'remove GSI' | tee -a ./output/4_output.txt
aws dynamodb --no-cli-pager update-table \
    --table-name Reply \
    --global-secondary-index-updates '[{
        "Delete":{
            "IndexName": "PostedBy-ReplyDateTime-gsi"
        }
    }
]' \
--endpoint-url http://localhost:8000 | grep IndexStatus >> ./output/4_output.txt
