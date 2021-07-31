import json
import logging

from flask import Flask, g
import requests

logging.basicConfig(level=logging.DEBUG)
app = Flask(__name__)

@app.route('/api', methods=['POST', 'GET'])
def hello_api():
    with open('publickey', "rb") as fp:
        return fp.read()

if __name__ == '__main__':
    app.run(host='0.0.0.0',debug=True)
