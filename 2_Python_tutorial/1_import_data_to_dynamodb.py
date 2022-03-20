# Author: Katerina Bosko

# Creates three tables Customers, Meals and Orders and imports data into them

# Tutorial is based on "Getting Started Developing with Python and DynamoDB"
# https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Python.html
# but uses custom data

# NOTE:
# DynamoDB does not use the classical JSON format to store items internally.
# Instead, it uses a "marshalled" format.
# DynamoDB wraps all the attribute values in objects where the Key indicates its type
# and attribute value stays as-is.
# For instance: { value: 3 } becomes { value: { N: "3" } }.
# Source: https://dynobase.dev/dynamodb-json-converter-tool/

import boto3
import json
from decimal import Decimal

def create_custom_table(dynamodb_client, table_name, hash_key_name, hash_key_type, \
                        sort_key_name=None, sort_key_type=None):

    if sort_key_name and sort_key_type:
        response = dynamodb_client.create_table(
            AttributeDefinitions=[
                {
                    'AttributeName': hash_key_name,
                    'AttributeType': hash_key_type,
                },
                {
                    'AttributeName': sort_key_name,
                    'AttributeType': sort_key_type,
                },
            ],
            KeySchema=[
                {
                    'AttributeName': hash_key_name,
                    'KeyType': 'HASH',
                },
                {
                    'AttributeName': sort_key_name,
                    'KeyType': 'RANGE',
                },
            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 5,
                'WriteCapacityUnits': 5,
            },
            TableName=table_name,
        )
    else:
        response = dynamodb_client.create_table(
            AttributeDefinitions=[
                {
                    'AttributeName': hash_key_name,
                    'AttributeType': hash_key_type,
                }
            ],
            KeySchema=[
                {
                    'AttributeName': hash_key_name,
                    'KeyType': 'HASH',
                }
            ],
            ProvisionedThroughput={
                'ReadCapacityUnits': 5,
                'WriteCapacityUnits': 5,
            },
            TableName=table_name,
        )
    print(f"table {table_name} created")
    return response

def import_JSON(table_name):
    with open(f'./original_JSON/{table_name}.json') as json_file:
        json_obj = json.load(json_file, parse_float=Decimal)
    return json_obj

def main():
    dynamodb_client = boto3.client('dynamodb', endpoint_url="http://localhost:8000")
    dynamodb_resource = boto3.resource('dynamodb', endpoint_url="http://localhost:8000")

    # import JSON data
    customers_json = import_JSON("Customers")
    orders_json = import_JSON("Orders")
    meals_json = import_JSON("Meals")

    existing_tables = dynamodb_client.list_tables()['TableNames']

    # check if tables already exist -> boolean
    tables_exist = all(x in existing_tables for x in ['Customers', 'Orders', 'Meals'])

    # create tables if they do not exist
    if not tables_exist:
        create_custom_table(dynamodb_client, "Customers", "id", "N", "last_name", "S")
        create_custom_table(dynamodb_client, "Meals", "meal_name", "S")
        create_custom_table(dynamodb_client, "Orders", "customer_id", "N", "order_time", "S")

    print("current tables:")
    print(dynamodb_client.list_tables()['TableNames'])

    customers = dynamodb_resource.Table('Customers')
    orders = dynamodb_resource.Table('Orders')
    meals = dynamodb_resource.Table('Meals')

    #import JSON data into DynamoDB
    print("importing Customers data")
    for customer in customers_json:
        customers.put_item(Item=customer)
    print("finished importing to Customers table")

    print("importing Orders data")
    for order in orders_json:
        orders.put_item(Item=order)
    print("finished importing to Orders table")

    print("importing Meals data")
    for meal in meals_json:
        meals.put_item(Item=meal)
    print("finished importing to Meals table")


if __name__ == '__main__':
    main()

