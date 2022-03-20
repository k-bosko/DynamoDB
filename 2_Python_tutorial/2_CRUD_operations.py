# Author: Katerina Bosko

# Performs CRUD operations
# Requires Meals table to be imported into DynamoDB
# To import data run `python 1_import_data_to_dynamodb.py`

# Tutorial is based on "Getting Started Developing with Python and DynamoDB"
# https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Python.html
# but uses custom data

from pprint import pprint
import boto3
from botocore.exceptions import ClientError
from decimal import Decimal

def get_meal(meal_name, dynamodb=None):
    '''
    Returns given meal's information
    '''
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', endpoint_url="http://localhost:8000")

    table = dynamodb.Table('Meals')

    try:
        response = table.get_item(Key={'meal_name': meal_name})
    except ClientError as e:
        print(e.response['Error']['Message'])
    else:
        return response['Item']

def put_meal(brand_name, meal_name, meal_desc, calories, price, dynamodb=None):
    '''
    Inserts new meal item
    '''
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', endpoint_url="http://localhost:8000")

    table = dynamodb.Table('Meals')
    response = table.put_item(
       Item={
            'brand_name': brand_name,
            'meal_name': meal_name,
            'meal_desc': meal_desc,
            'calories': calories,
            'price': price
        }
    )
    return response

def update_meal(meal_name, new_price, new_calories, dynamodb=None):
    '''
    Updates given meal's price and calories
    '''
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', endpoint_url="http://localhost:8000")

    table = dynamodb.Table('Meals')

    response = table.update_item(
        Key={
            'meal_name': meal_name
        },
        UpdateExpression="set price=:p, calories=:c",
        ExpressionAttributeValues={
            ':p': Decimal(new_price),
            ':c': Decimal(new_calories)
        },
        ReturnValues="UPDATED_NEW"
    )
    return response

def increase_price(meal_name, price_increase, dynamodb=None):
    '''
    Increases given meal's price by a given amount
    '''
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', endpoint_url="http://localhost:8000")

    table = dynamodb.Table('Meals')

    response = table.update_item(
        Key={
            'meal_name': meal_name,
        },
        UpdateExpression="set price = price + :val",
        ExpressionAttributeValues={
            ':val': Decimal(price_increase)
        },
        ReturnValues="UPDATED_NEW"
    )
    return response

def delete_meal_conditionally(meal_name, price, dynamodb=None):
    '''
    Deletes meal if its price is less than specified
    '''
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', endpoint_url="http://localhost:8000")

    table = dynamodb.Table('Meals')

    try:
        response = table.delete_item(
            Key={
                'meal_name': meal_name
            },
            ConditionExpression="price <= :val",
            ExpressionAttributeValues={
                ":val": Decimal(price)
            }
        )
    except ClientError as e:
        if e.response['Error']['Code'] == "ConditionalCheckFailedException":
            print(e.response['Error']['Message'])
        else:
            raise
    else:
        return response

if __name__ == '__main__':
    # create
    new_meal = put_meal("Burgertoom", "Double Burger with Cheddar", "Two Special Burgers with cheddar for a price of one", Decimal("800"), Decimal("9.99"))
    print("Put meal succeeded:")
    pprint(new_meal)

    # read
    meal = get_meal("Double Burger with Cheddar")
    if meal:
        print("Get meal succeeded:")
        pprint(meal)

    # update
    update_response = update_meal(
        "Double Burger with Cheddar", Decimal("14.99"), Decimal("1200"))
    print("Update meal succeeded:")
    pprint(update_response)

    # increment atomic counter
    get_response = get_meal("Pizza Hawaii")
    print(f"Current price of Pizza Hawaii: {get_response['price']}")
    update_response = increase_price("Pizza Hawaii", 5)
    print("Price increase succeeded:")
    pprint(update_response)

    # conditional delete
    print("Attempting a conditional delete (expecting failure)...")
    delete_response = delete_meal_conditionally("Mac N Cheese", 15)
    if delete_response:
        print("Delete movie succeeded:")
        pprint(delete_response)

    print("Attempting a conditional delete (expecting succeed)...")
    delete_response = delete_meal_conditionally("Mac N Cheese", 20)
    if delete_response:
        print("Delete movie succeeded:")
        pprint(delete_response)



