
#!/bin/bash

# Author: Katerina Bosko

# Creates and imports data into local instance of DynamoDB
# Requires locally installed DynamoDB (see README)

# This tutorial is based on
# Amazon DynamoDB Labs > Hands-on Labs for Amazon DynamoDB
# https://master.amazon-dynamodb-labs.com/hands-on-labs.html
# adopted to work on local machine and run as bash script

# NOTE: there are differences between DynamoDB that runs locally and the DynamoDB Web Service
# see them here: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.UsageNotes.html
# For instance, provisioned throughput settings are ignored in downloadable DynamoDB
# so you will see "ConsumedCapacity": null
# when querying/scanning data in DynamoDB local version

echo 'creating table ProductCatalog'
aws dynamodb --no-cli-pager create-table \
    --table-name ProductCatalog \
    --attribute-definitions \
        AttributeName=Id,AttributeType=N \
    --key-schema \
        AttributeName=Id,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=10,WriteCapacityUnits=5\
    --endpoint-url http://localhost:8000

echo 'creating table Forum'
aws dynamodb --no-cli-pager create-table \
    --table-name Forum \
    --attribute-definitions \
        AttributeName=Name,AttributeType=S \
    --key-schema \
        AttributeName=Name,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=10,WriteCapacityUnits=5 \
    --endpoint-url http://localhost:8000

echo 'creating table Thread'
aws dynamodb --no-cli-pager create-table \
    --table-name Thread \
    --attribute-definitions \
        AttributeName=ForumName,AttributeType=S \
        AttributeName=Subject,AttributeType=S \
    --key-schema \
        AttributeName=ForumName,KeyType=HASH \
        AttributeName=Subject,KeyType=RANGE \
    --provisioned-throughput \
        ReadCapacityUnits=10,WriteCapacityUnits=5\
    --endpoint-url http://localhost:8000

echo 'creating table Reply'
aws dynamodb --no-cli-pager create-table \
    --table-name Reply \
    --attribute-definitions \
        AttributeName=Id,AttributeType=S \
        AttributeName=ReplyDateTime,AttributeType=S \
    --key-schema \
        AttributeName=Id,KeyType=HASH \
        AttributeName=ReplyDateTime,KeyType=RANGE \
    --provisioned-throughput \
        ReadCapacityUnits=10,WriteCapacityUnits=5\
    --endpoint-url http://localhost:8000

aws dynamodb wait table-exists --table-name ProductCatalog && \
aws dynamodb wait table-exists --table-name Reply && \
aws dynamodb wait table-exists --table-name Forum && \
aws dynamodb wait table-exists --table-name Thread --endpoint-url http://localhost:8000

echo 'Downloading and unziping the sample data'
wget https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/samples/sampledata.zip
unzip sampledata.zip

echo 'Loading the sample data using the batch-write-item CLI'
aws dynamodb --no-cli-pager batch-write-item --request-items file://ProductCatalog.json --endpoint-url http://localhost:8000
aws dynamodb --no-cli-pager batch-write-item --request-items file://Forum.json --endpoint-url http://localhost:8000
aws dynamodb --no-cli-pager batch-write-item --request-items file://Thread.json --endpoint-url http://localhost:8000
aws dynamodb --no-cli-pager batch-write-item --request-items file://Reply.json --endpoint-url http://localhost:8000
