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

# Output is saved into ./output/3_output.txt

# NOTE: there are differences between DynamoDB that runs locally and the DynamoDB Web Service
# see them here: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.UsageNotes.html
# For instance, provisioned throughput settings are ignored in downloadable DynamoDB
# so you will see "ConsumedCapacity": null
# when querying/scanning data in DynamoDB local version

#==============================
# QUERIES
#==============================
echo 'QUERIES' | tee -a ./output/3_output.txt
# to invoke Query we must specify --key-condition-expression option (aka WHERE in SQL)
# Two ways:
# 1. only partition key is mentioned --> returns all items in collection (Example 1)
# 2. Partition key + Sort Key Condition --> returns a subset that matches condition (Example 2)

# In Reply table partition key is Id, sort key is ReplyDateTime
# --filter-expresion option limits the results based on non-key attributes

# Example 1:
echo 'find all the replies in Thread 1 that were posted by User B' | tee ./output/3_output.txt

aws dynamodb --no-cli-pager query \
    --table-name Reply \
    --key-condition-expression 'Id = :Id' \
    --filter-expression 'PostedBy = :user' \
    --expression-attribute-values '{
        ":Id" : {"S": "Amazon DynamoDB#DynamoDB Thread 1"},
        ":user" : {"S": "User B"}
    }' \
    --endpoint-url http://localhost:8000 >> ./output/3_output.txt


# Example 2:
echo 'find only replies in a thread that were posted after 2015-09-21' | tee -a ./output/3_output.txt
aws dynamodb --no-cli-pager query \
    --table-name Reply \
    --key-condition-expression 'Id = :Id and ReplyDateTime > :ts' \
    --expression-attribute-values '{
        ":Id" : {"S": "Amazon DynamoDB#DynamoDB Thread 1"},
        ":ts" : {"S": "2015-09-21"}
    }' \
    --endpoint-url http://localhost:8000 >> ./output/3_output.txt

echo 'return only the first reply to a thread --> similar to "ORDER BY ReplyDateTime ASC LIMIT 1"' | tee -a ./output/3_output.txt
aws dynamodb --no-cli-pager query \
    --table-name Reply \
    --key-condition-expression 'Id = :Id' \
    --expression-attribute-values '{ ":Id" : {"S": "Amazon DynamoDB#DynamoDB Thread 1"} }' \
    --max-items 1 \
    --scan-index-forward  \
    --endpoint-url http://localhost:8000 >> ./output/3_output.txt

echo 'return only the most recent reply for a thread --> “ORDER BY ReplyDateTime DESC LIMIT 1”' | tee -a ./output/3_output.txt
aws dynamodb --no-cli-pager query \
    --table-name Reply \
    --key-condition-expression 'Id = :Id' \
    --expression-attribute-values '{
        ":Id" : {"S": "Amazon DynamoDB#DynamoDB Thread 1"}
    }' \
    --max-items 1 \
    --no-scan-index-forward  \
    --endpoint-url http://localhost:8000 >> ./output/3_output.txt

#==============================
# SCANS
#==============================
echo 'SCANS' | tee -a ./output/3_output.txt
# scans perform full table scan and return the items in 1MB chunks
# (if more than 1MB is returned -> --starting-token is issued that can be used in subsequent request
# to continue scan)
# scans are COSTLY!
# even if you specify --filter-expression option (to limit the number of returned items),
# you still pay for scanning the whole table which could deplete your funds fast

echo 'find all the replies in the Reply that were posted by User A' | tee -a ./output/3_output.txt
aws dynamodb --no-cli-pager scan \
    --table-name Reply \
    --filter-expression 'PostedBy = :user' \
    --expression-attribute-values '{
        ":user" : {"S": "User A"}
    }' \
    --endpoint-url http://localhost:8000 >> ./output/3_output.txt


echo 'write a scan command to return only the Forums that have more than 1 thread and more than 50 views' | tee -a ./output/3_output.txt
aws dynamodb --no-cli-pager scan \
    --table-name Forum \
    --filter-expression 'Threads >= :threads AND #v >= :views' \
    --expression-attribute-values '{
        ":threads" : {"N": "1"},
        ":views": {"N": "50"}
    }' \
    --expression-attribute-names '{"#v": "Views"}' \
    --endpoint-url http://localhost:8000 >> ./output/3_output.txt

# NOTE: Views is a reserved word. So we need to replace it with #v
