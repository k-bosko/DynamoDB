# DynamoDB

DynamoDB is highly available NoSQL database service provided by Amazon since 2012. Because DynamoDB runs on AWS, AWS handles scaling, availability and updates for its customers. As a result, DynamoDB users don’t need to worry about managing infrastructure. 

While you need AWS account to use Amazon DynamoDB as a web service, you can download a local version of DynamoDB. This is an ideal option if you're just starting out with DynamoDB or want to first develop and test your application without incurring any costs. However, you will need DynamoDB web service to deploy your application in production.

In this repo, I explain how to install DynamoDB via Docker container and run it locally. I also have two tutorials to get started - one on how to use AWS CLI and another one on how to use Python SDK.

## Installation 

There are 2 options to install DynamoDB locally - either through **direct download** or through **Docker**. Here, I explain how to start DynamoDB by using container but if you want to use direct download option, please refer to the following [documentation page](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.DownloadingAndRunning.html).

1. Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. Create a `docker-compose.yml` with following information (or download it from this repo):

```
version: '3.8'
services:
  dynamodb-local:
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
```
Compose is a tool for defining and running multi-container Docker applications. Here, however, we configure just one container. If you want to connect your app with DynamoDB, please refer to [this documentation page](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.DownloadingAndRunning.html).

So what does `docker-compose.yml` do? Basically, it downloads a container image for a DynamoDB local version, calls it dynamodb-local and runs this service  on port 8000 both on our local machine and inside container. It also attaches a local volume to our container such that every table that is created locally (./docker/dynamodb) is automatically copied over to /home/dynamodblocal/data inside container.

Now to start DynamoDB container we just need to run one command:

`docker-compose up`

## AWS CLI Tutorial

There are several ways how you can work with DynamoDB locally - either by using AWS CLI or AWS SDKs. The latter option is currently available for Java, JavaScript, Node.js, .NET, PHP, Python, Ruby, C++, Go, Android and iOS. 

In the following, I will explain how to get started in two ways 1) by using **AWS CLI** and 2) through **Python SDK** as these are the most familiar to me.


### Installing AWS CLI

To be able to run DynamoDB commands in the terminal, we first need to install AWS command line interface (CLI). 

**To install AWS CLI on MacOS** assuming that you have sudo permissions, run the following commands:

```
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
aws --version
```

The first line uses curl utility to download the package and -o option specifies the destination file name. The second line installs the AWSCLIV2.pkg package. The final line just verifies whether AWS CLI was installed successfully.

If you have a different OS, please refer to [this documentation page](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

### AWS CLI Tutorial

Download shell scripts from `1_AWS_CLI_tutorial` folder in this repo and run:

```
./1_import_data_to_dynamodb.sh
./2_CRUD_operations.sh
./3_scans_and_queries.sh
./4_transactions_and_indexing.sh
```

**NOTE:** To access DynamoDB running locally, use the --endpoint-url parameter. Otherwise you get `AccessDeniedException` because aws tries to access a web service. To run 4_transactions_and_indexing.sh successfully you need **jq** installed.

## Python tutorial

You need `boto3` library which is AWS SDK for Python:

`pip install boto3`

Download Python scripts from `2_Python_tutorial` folder in this repo and run:
```
python 1_import_data_to_dynamodb.py
python 2_CRUD_operations.py
python 3_scans_and_queries.py
```

## Useful Resources

Hands-on tutorials:

* [Introduction: Create and Manage a Nonrelational Database](https://aws.amazon.com/getting-started/hands-on/create-manage-nonrelational-database-dynamodb/)

* [Introduction: Design a Database for a Mobile App with Amazon DynamoDB](https://aws.amazon.com/getting-started/hands-on/design-a-database-for-a-mobile-app-with-dynamodb/)

* [Build a turn-based game with Amazon DynamoDB and Amazon SNS](https://aws.amazon.com/getting-started/hands-on/turn-based-game-dynamodb-amazon-sns/)

* [Introduction: Modeling Game Player Data with Amazon DynamoDB](https://aws.amazon.com/getting-started/hands-on/data-modeling-gaming-app-with-dynamodb/)

* [Building a Mars Rover Application with DynamoDB](https://www.infoq.com/articles/mars-rover-application-DynamoDB/)

Courses & Guides:

* [DynamoDB, explained. A Primer on the DynamoDB NoSQL database.](https://www.dynamodbguide.com/what-is-dynamo-db)

* [Amazon DynamoDB for Serverless Architectures](https://explore.skillbuilder.aws/learn/course/external/view/elearning/67/amazon-dynamodb-for-serverless-architectures)


## References
[Deploying DynamoDB Locally on Your Computer](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.DownloadingAndRunning.html)

[Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

[Getting Started Developing with Python and DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Python.html)

[Hands-on Labs for Amazon DynamoDB](https://master.amazon-dynamodb-labs.com/hands-on-labs.html)
