import base64
import json
import logging
import random
import datetime
import time
import os
import boto3

kinesis = boto3.client('kinesis')

STREAM_NAME = os.getenv('SOURCE_STREAM_NAME')


def getReferrer():
    x = random.randint(1,5)
    x = x*50
    y = x+30

    return {
        'user_id': random.randint(x,y),
        'device_id': random.choice([
            'mobile',
            'computer',
            'tablet',
            'mobile',
            'computer'
        ]),
        'client_event': random.choice([
            'beer_vitrine_nav',
            'beer_checkout',
            'beer_product_detail',
            'beer_products',
            'beer_selection',
            'beer_cart'
        ]),
        'client_timestamp': str(datetime.datetime.now())
    }


def lambda_handler(event, context):

    event_num = 100
    partition_key = 'partitionkey'

    records = [
        dict(
            Data=json.dumps(getReferrer()),
            PartitionKey=partition_key
        )
        for _ in range(event_num)
    ]
    kinesis.put_records(
        StreamName=STREAM_NAME,
        Records=records
    )
