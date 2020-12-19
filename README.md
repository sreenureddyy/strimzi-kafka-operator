## Strmizi Kafka Operator on VMware Kuberbnetes WCP & GCM Clusters

**Procedure to Run**
 

1. Create a namespace with name as `kafka`. Don’t use any other names.
2. SCP to your WCP master vm and upload the kafka-operator.tar
3. Untar
   ```
   tar -xf kafka-operator.tar
   ```
4. cd to kafka-operator folder
5. Run below command to bringup the kafka operator. This command will take ~10-15 minutes to bringup the Kafka-Operator with 3 Zookeper & Kafka replicas
    
    ```
    sh create-kafka-operator.sh
    ```
        
        
6. To tear down the Kafka operator. Run the below command
       
    ```
    sh delete-kafka-operator.sh
    ```
    
7. To verify the logs are straming to the kafka-operator. Run the following command to bring up the **consumer** as container

    ```
    kubectl -n kafka run kafka-consumer -ti --image=strimzi/kafka:0.19.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap:9092 --topic containerlog
    ```
     
** Scripts & YAML files will do necessary actions**
* Creation of topic in Kafka
* Rebalancing Kafka
* Bring up the cruise control
* Adding routes, Modifies the inputs, filters to already running Fluentbit
* Restarts the fluenbit and starts streaming the container logs, audit logs to Kafka operator

**Kafka Producer**
```
kubectl -n kafka run kafka-producer -ti --image=strimzi/kafka:0.19.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list my-cluster-kafka-bootstrap:9092 --topic containerlog
```

**Kafka LoadBalancer IP**
```
kubectl get service my-cluster-kafka-external-bootstrap -o=jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}' -n kafka
```

**Kafka REST Api**
```
curl -v GET http://my-bridge-bridge-service.kafka.svc.cluster.local:8080/healthy

curl -X POST \
  http://my-bridge-bridge-service.kafka.svc.cluster.local:8080/topics/containerlog \
  -H 'content-type: application/vnd.kafka.json.v2+json' \
  -d '{
    "records": [
        {
            "key": "key-1",
            "value": "hello"
        },
        {
            "key": "key-2",
            "value": "world"
        }
    ]
}'

curl -X POST http://my-bridge-bridge-service.kafka.svc.cluster.local:8080/consumers/my-group \
  -H 'content-type: application/vnd.kafka.v2+json' \
  -d '{
    "name": "my-consumer",
    "format": "json",
    "auto.offset.reset": "earliest",
    "enable.auto.commit": false
  }'
  
  
curl -X POST http://my-bridge-bridge-service.kafka.svc.cluster.local:8080/consumers/my-group/instances/my-consumer/subscription \
  -H 'content-type: application/vnd.kafka.v2+json' \
  -d '{
    "topics": [
        "containerlog"
    ]
}'

curl -X GET http://my-bridge-bridge-service.kafka.svc.cluster.local:8080/consumers/my-group/instances/my-consumer/records \
  -H 'accept: application/vnd.kafka.json.v2+json'

```

**Fluentbit configuration**
```
[INPUT]
        Name              tail
        Tag               kube.*
        Path              /var/log/containers/*.log
        Parser            docker
        DB                /var/log/vmware/fluentbit/flb_kube.db
        Buffer_Max_Size   12MBb
        Mem_Buf_Limit     32MB
        Skip_Long_Lines   On
        Refresh_Interval  10

[INPUT]
        Name              tail
        Tag               audit.*
        Path              /var/log/vmware/audit/*.log
        Parser            docker
        DB                /var/log/vmware/fluentbit/flb_kafka.db
        Buffer_Max_Size   12MBb
        Mem_Buf_Limit     32MB
        Skip_Long_Lines   On
        Refresh_Interval  10

[FILTER]
        Name grep
        Match audit.*
        Regex verb (?:create|delete)

[FILTER]
        Name grep
        Match audit.*
        Regex stage ResponseComplete

[OUTPUT]
        Name            kafka
        Match           kube.*
        Brokers         my-cluster-kafka-external-bootstrap.kafka.svc.cluster.local:9094
        Topics          containerlog
        File            kafka-container-log.log

[OUTPUT]
        Name            kafka
        Match           audit.*
        Brokers         my-cluster-kafka-external-bootstrap.kafka.svc.cluster.local:9094
        Topics          auditlog
        File            kafka-container-log.log

```


**Fluentbit commands**
* restart demonset 
```
kubectl rollout restart daemonset.apps/fluentbit -n vmware-system-logging 
```

* Get all from namespace
```
kubectl get all -n vmware-system-logging
```

* edit configmap
```
kubectl edit -n vmware-system-logging cm fluentbit-config  
```



**Reference**
-  https://strimzi.io/install/latest?namespace=kafka
-  https://strimzi.io/blog/2019/05/13/accessing-kafka-part-4/
-  https://strimzi.io/blog/2020/07/22/tips-and-tricks-for-running-strimzi-with-kubectl/
-  https://strimzi.io/blog/2020/06/15/cruise-control/
-  https://strimzi.io/docs/operators/master/using.html
-  https://strimzi.io/blog/2019/11/05/exposing-http-bridge/
