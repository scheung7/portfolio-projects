import pandas as pd
import os
from time import sleep

from requests import Session
from requests.exceptions import ConnectionError, Timeout, TooManyRedirects
import json


API_KEY = '819e86e2-1a96-46fa-8b1b-410cac45b1f1'

currency = 'AUD'
data_limit = '15'
n_calls_daily = 20
call_interval = 60*5    # time between api calls in seconds

def get_crypto_data(key):
    """Calls coinmarketcap public API to get crypto data"""
    
    url = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest'
    parameters = {
    'start':'1',
    'limit':data_limit,
    'convert':currency
    }
    headers = {
    'Accepts': 'application/json',
    'X-CMC_PRO_API_KEY':key,
    }

    session = Session()
    session.headers.update(headers)

    try:
        response = session.get(url, params=parameters)
        data = json.loads(response.text)
    except (ConnectionError, Timeout, TooManyRedirects) as e:
        print(e)


    # store data into dataframe
    crypto_data = pd.json_normalize(data['data'])
    crypto_data['timestamp'] = pd.to_datetime('now')        # time of api call

    # create new csv file if not found
    if not os.path.isfile('./crypto_data.csv'):
        crypto_data.to_csv('./crypto_data.csv', header='column_names', index=False)

    # append to existing file
    else:
        crypto_data.to_csv('./crypto_data.csv', mode='a', header=False, index=False)




if __name__ == '__main__':

    # number of api calls per day
    for i in range(n_calls_daily):
        get_crypto_data(key=API_KEY)
        print(f'{i}: API call completed')

        # sleep for specified call interval
        sleep(call_interval)    
