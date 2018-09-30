from flask import Flask, request
from flask_sqlalchemy import SQLAlchemy
from flask_boto3 import Boto3
from flask_mail import Mail, Message
from datetime import datetime
from os import environ

app = Flask(__name__)

app.config["SQLALCHEMY_DATABASE_URI"] = "postgresql://{db_user}:{db_password}@{db_host}:5432/{db_name}".format(
    db_user=environ.get("DB_USER"),
    db_password=environ.get("DB_PASSWORD"),
    db_host=environ.get("DB_HOST"),
    db_name=environ.get("DB_NAME")
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)

app.config["BOTO3_ACCESS_KEY"] = environ.get("AWS_ACCESS_KEY")
app.config["BOTO3_SECRET_KEY"] = environ.get("AWS_SECRET_KEY")
app.config["BOTO3_REGION"] = environ.get("REGION")
app.config["BOTO3_SERVICES"] = ["ec2"]
boto_flask = Boto3(app)

app.config["MAIL_SERVER"] = environ.get("EMAIL_HOST")
app.config["MAIL_USERNAME"] = environ.get("EMAIL_HOST_USER")
app.config["MAIL_PASSWORD"] = environ.get("EMAIL_HOST_PASSWORD")
app.config["MAIL_PORT"] = environ.get("EMAIL_PORT")
app.config["MAIL_DEFAULT_SENDER"] = environ.get("EMAIL_DEFAULT_SENDER")
mail = Mail(app)


class Blacklist(db.Model):
    __tablename__ = "blacklist"

    id = db.Column(db.Integer, primary_key=True)
    path = db.Column(db.String(50), unique=False, nullable=False)
    ip_address = db.Column(db.String(15), unique=False, nullable=False)
    access_datetime = db.Column(db.DateTime, unique=False, nullable=False)

    def __init__(self, path, ip_address, access_datetime):
        self.path = path
        self.ip_address = ip_address
        self.access_datetime = access_datetime


@app.route("/")
def index():
    return "Hello world!"


@app.route("/blacklisted")
def blacklist():
    path = request.path
    if request.headers.getlist("X-Forwarded-For"):
        ip_address = request.headers.getlist("X-Forwarded-For")[0]
    else:
        ip_address = request.remote_addr
    access_datetime = datetime.now()

    ec2 = boto_flask.resources["ec2"]
    network_acl = ec2.NetworkAcl(environ.get("NETWORK_ACL_ID"))

    for i in network_acl.entries:
        if i["CidrBlock"] == "{}/32".format(ip_address):
            ip_address_present_acl = True
            break
    else:
        ip_address_present_acl = False

    ip_address_present_db = db.session.query(Blacklist).filter(Blacklist.ip_address == ip_address).count()

    if ip_address_present_db and ip_address_present_acl:
        return "IP Address: {ip_address}<br>is already blocked".format(ip_address=ip_address)

    if not ip_address_present_db:
        reg = Blacklist(
            path=path,
            ip_address=ip_address,
            access_datetime=access_datetime
        )
        db.session.add(reg)
        db.session.commit()

    rule_number = Blacklist.query.filter_by(ip_address=ip_address).first().id
    if not ip_address_present_acl:
        response = network_acl.create_entry(
            CidrBlock="{ip_address}/32".format(ip_address=ip_address),
            Egress=False,
            PortRange={
                "From": 80,
                "To": 80
            },
            Protocol="6",
            RuleAction="deny",
            RuleNumber=rule_number
        )
    msg_body = "Path: {path}<br>IP Address: {ip_address}<br>Access Datetime: {access_datetime}<br>Blocked!".format(
        path=path,
        ip_address=ip_address,
        access_datetime=access_datetime
    )
    msg = Message("IP Blocked", recipients=["test@domain.com"], body=msg_body)
    mail.send(msg)
    return msg_body


if __name__ == "__main__":
    db.create_all()
    app.run(host="0.0.0.0", debug=True)
