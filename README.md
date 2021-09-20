# BucketList

BucketList is a simple Flask application designed to allow you to add ToDo items, and hopefully help you also achieve them.

## Running BucketList

Since this application is packaged as a docker image and published to DockerHub, running locally is as simple as doing:

```shell
docker run -it -p 5000:5000 rebelthor/bucketlist:latest
```

Afterwards, the app can be access via http://localhost:5000 in your browser.

Note that running the app without any parameters will cause a fallback to the internal SQLITE database engine, meaning that any changes you do will be lost as soon as the container dies.

## Tools used
* [The Flask Framework|https://flask.palletsprojects.com/en/2.0.x/]
* [FontAwesome Icons|https://fontawesome.com/]
## K8s Deployment

* Run the terraform code in the _terraform_ folder against your GCP account. Your terraform.tfvars file can be similar to this:
```properties
region          = "us-west1"
zones           = ["us-west1-a"]
billing_account = "012345-67890-ABCDEF"
master_authorized_networks = [
  {
    cidr_block   = "80.90.100.110/32"
    display_name = "Home"
  },
]
```
* Connect to your cluster and make sure it works as expected, create the bucketlist namespace 
```shell
gcloud container clusters get-credentials bucketlist-0os2 --region us-west1-a --project bucketlist-0os2
kubectl create ns bucketlist
```
* Install the helm chart
```shell
helm install bucketlist chart/
```
* Setup a port-forward to the database, and set up the tables
```shell
kubectl port-forward bucketlist-postgresql-primary-0 5432:5432
export DATABASE_URL=postgresql://username:password@localhost/bucketlist
flask db init
flask db migrate
flask db update
```
* Validate that the app is running fine:
```shell
k get pods
NAME                              READY   STATUS    RESTARTS   AGE
bucketlist-557bfdcb87-6l477       1/1     Running   4          15m
bucketlist-557bfdcb87-7d9l7       1/1     Running   4          15m
bucketlist-557bfdcb87-khxdh       1/1     Running   4          15m
bucketlist-postgresql-primary-0   1/1     Running   0          15m
bucketlist-postgresql-read-0      1/1     Running   0          15m
```