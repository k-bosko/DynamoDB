# Author: Katerina Bosko

# Performs scan and querying operations
# Requires Orders and Customers tables to be imported into DynamoDB
# To import data run `python 1_import_data_to_dynamodb.py`

# Tutorial is based on "Getting Started Developing with Python and DynamoDB"
# https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Python.html
# but uses custom data

from pprint import pprint
import boto3
from boto3.dynamodb.conditions import Key

def query_and_project_orders(customer_id, order_time_range, dynamodb=None):
    '''
    Find orders by given customer in given time range
    '''
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', endpoint_url="http://localhost:8000")

    table = dynamodb.Table('Orders')

    response = table.query(
        KeyConditionExpression=
            Key('customer_id').eq(customer_id) & Key('order_time').between(order_time_range[0], order_time_range[1])
    )
    return response['Items']

def scan_customers(customers_range, display_customers, dynamodb=None):
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', endpoint_url="http://localhost:8000")

    table = dynamodb.Table('Customers')
    scan_kwargs = {
        'FilterExpression': Key('id').between(*customers_range),
        'ProjectionExpression': "id, last_name, first_name",
    }

    done = False
    start_key = None
    while not done:
        if start_key:
            scan_kwargs['ExclusiveStartKey'] = start_key
        response = table.scan(**scan_kwargs)
        display_customers(response.get('Items', []))
        start_key = response.get('LastEvaluatedKey', None)
        done = start_key is None

def print_customers(customers):
    for customer in customers:
        print(f"{customer['first_name']} {customer['last_name']}")

if __name__ == '__main__':
    query_customer_id = 12
    query_range = ('11/1/2021', '11/31/2021')
    print(f"Get orders by customer with id={query_customer_id} in November ")
    orders = query_and_project_orders(query_customer_id, query_range)
    for order in orders:
        pprint(order)

    scan_range = (1, 50)
    print(f"Scanning for customers with customer id ranging from {scan_range[0]} to {scan_range[1]}...")
    scan_customers(scan_range, print_customers)


