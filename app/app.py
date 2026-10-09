from flask import Flask

from telemetry import setup_telemetry

app = Flask(__name__)

setup_telemetry(app)
@app.get("/")
def hello():
    return {"message": "Hello from this ample security project"}


@app.get("/health")
def health():
    return {"status": "healthy"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)