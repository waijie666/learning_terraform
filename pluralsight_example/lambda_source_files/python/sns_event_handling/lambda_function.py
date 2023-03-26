import json
import os
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info('## ENVIRONMENT VARIABLES')
    logger.info(os.environ)
    logger.info('## EVENT')
    response = {
        'statusCode': 200,
        'body': json.dumps('Handling events yep yep'),
        "event": event
    }
    logger.info(response)
    return response
