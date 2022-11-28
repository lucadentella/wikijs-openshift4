# Wiki.js in Openshift 4
How to install [Wiki.js](https://js.wiki/) in Openshift 4 (using *sideloading* mode)

Prerequisites:
- running Openshift or OKD cluster with persistant storage setup


 1. Create a project:
    ```bash
    oc new-project wikijs
    ```

2. Install the Crunchy Postgres for Kubernete operator from OperatorHub or following the instructions here:
https://access.crunchydata.com/documentation/postgres-operator/v5/quickstart/


    Choose all namespaces if you want it to be usuable in more than one, if not use the wikijs one that we created before.

3. Install the postgres DB as follows, making sure your oc command is using the right context. Change the values if needed - currently it's 20GB.

    ```bash
    oc apply -f postgres.yaml
    ```

4. Now you should have a PostgresCluster CR under the tab under installed operators. You should be able to connect from the local machine with psql like so (make sure psql is installed):

    ```bash
    PG_CLUSTER_PRIMARY_POD=$(oc get pod -n wikijs -o name -l postgres-operator.crunchydata.com/cluster=wikijs,postgres-operator.crunchydata.com/role=master)

    kubectl -n wikijs port-forward "${PG_CLUSTER_PRIMARY_POD}" 5432:5432 & 

    PG_CLUSTER_USER_SECRET_NAME=wikijs-pguser-wikijs
    PGPASSWORD=$(kubectl get secrets -n wikijs "${PG_CLUSTER_USER_SECRET_NAME}" -o go-template='{{.data.password | base64decode}}') PGUSER=$(kubectl get secrets -n wikijs "${PG_CLUSTER_USER_SECRET_NAME}" -o go-template='{{.data.user | base64decode}}') PGDATABASE=$(kubectl get secrets -n wikijs "${PG_CLUSTER_USER_SECRET_NAME}" -o go-template='{{.data.dbname | base64decode}}') psql -h localhost
    ```

    You shoud get a shell that shows the connection is using TLS, which is the default with this operator.

5. For me it did not work to have Wiki.js connect to PostgreSQL with SSL, I needed to add the CA cert as described in the docs: 

    https://docs.requarks.io/install/docker (DB_SLL_CA - Database CA certificate content, as a single line string (without spaces or new lines), without the prefix and suffix lines. (optional, requires 2.3+))

    This is stored in the pgo-root-cacert secret, run the script to get it in the right format:
    ```bash
    ./getPsqlRootCAString.sh 
    ```
    It will give something like : 
    ```bash
    MIIBgTCCASegAwIBAgIQFlUx8CFOhxtbNv8baQQh7jAKBggqhkjOPQQDAzAfMR0wGwYDVQQDExRwb3N0Z3Jlcy1vcGVyYXRvci1jYTAeFw0yMjExMjUxMjM1NDNaFw0zMjExMjIxMzM1NDNaMB8xHTAbBgNVBAMTFHBvc3RncmVzLW9wACBhdG9yLWNhMFkwEwNHKoZIzj0CAQYIKoZIzj0DAQcDQgAElokygIJH/U06gVTTQRZB0B1cdSV8bP/HWVJ7BYOhcuOUymQsPnKDg27DgQSa9zVVLADHf24vuMg8Uo/NDfjaf6NFMEMwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFN/HmCEkp7HKceaU/QACugp4tu/LMAoGCCqGSM49BAMDA0gAMEUCIQC/qZJx55pqzB0QmSRL6UmhnSeUl85rf2+X3eods2miKgIgM3swV3UuTMgdDm8scsW1aDwhkPpCkwOXbaM0mX2jDvM=
    ```
    Add this to the deploymentConfig.yaml, snippet:
    ```bash
        - name: DB_SSL_CA
          value: MIIBgTCCASegAwIBAgIQFlUx8CFOhxtbNv8baQQh7jAKBggqhkjOPQQDAzAfMR0wGwYDVQQDExRwb3N0Z3Jlcy1vcGVyYXRvci1jYTAeFw0yMjExMjUxMjM1NDNaFw0zMjExMjIxMzM1NDNaMB8xHTAbBgNVBAMTFHBvc3RncmVzLW9wACBhdG9yLWNhMFkwEwNHKoZIzj0CAQYIKoZIzj0DAQcDQgAElokygIJH/U06gVTTQRZB0B1cdSV8bP/HWVJ7BYOhcuOUymQsPnKDg27DgQSa9zVVLADHf24vuMg8Uo/NDfjaf6NFMEMwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFN/HmCEkp7HKceaU/QACugp4tu/LMAoGCCqGSM49BAMDA0gAMEUCIQC/qZJx55pqzB0QmSRL6UmhnSeUl85rf2+X3eods2miKgIgM3swV3UuTMgdDm8scsW1aDwhkPpCkwOXbaM0mX2jDvM=
    ```
    Now we are ready to deploy it.
6. The deployment file contains a reference to the docker image the author of the mentioned reference made. 
As mentioned, this can be build from the Dockerfile which is included.

For convenience we can use that image, to user your own, build the image and tag it: 
    docker build -t yourusername/repository-name .
    I used docker hub :
    ```bash
    docker build -t vgerris/wikijs:2 .
    ```
    then push it to your registry of choice and update the reference in the deployment file
    more info : https://docs.docker.com/engine/reference/commandline/push/
    ```bash
    docker push vgerris/wikijs:2
    ```

    Now apply the deployment:
    ```bash
    oc apply -f deploymentConfig.yaml 
    ```
7. Now that the app is deployed we can add a service and a route te expose it.

    Update the route file with your server URL:
    ```bash
    oc apply -f service.yaml
    oc apply -f route.yaml
    ```
    You should have the application running and exposed on the route now, you can finish setting it up.
    Enjoy Wiki.js !


Based on this tutorial that uses a PostgreSQL app template:

http://www.lucadentella.it/2022/04/20/installare-wiki-js-in-openshift-4/


and references:

https://access.crunchydata.com/documentation/postgres-operator/v5/quickstart/

https://docs.requarks.io/install/docker

https://docs.docker.com/engine/reference/commandline/push/

