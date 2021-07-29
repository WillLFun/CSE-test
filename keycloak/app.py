from flask import Flask
app = Flask(__name__)
@app.route("/")
def hello_world():
    while open('publickey', "rb") as fp:
        return fp.read()
