from flask import request, Flask, make_response
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)

def generateDebugInfo():
    res = ""
    for i in request.headers.items():
        res = res + ' = '.join(i) + '\n'
    return res

@app.route('/')
def metrics():
    response = make_response(generateDebugInfo(), 200)
    response.mimetype = "text/plain"
    return response


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
