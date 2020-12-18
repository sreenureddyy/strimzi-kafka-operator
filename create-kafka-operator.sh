
echo "Creating Kafka Operator CRD"
kubectl apply -f kafka-crd.yaml -n kafka
echo "Waiting to create Kafka Operator CRD"
kubectl wait --for=condition=Established -f kafka-crd.yaml 

echo "Applying Kafka Operator"
kubectl apply -f kafka-operator.yaml -n kafka

echo "Creating zookeeper pods"
sleep 15s
kubectl wait --for=condition=ready --timeout=600s pod my-cluster-zookeeper-0 -n kafka
kubectl wait --for=condition=ready --timeout=600s pod my-cluster-zookeeper-1 -n kafka
kubectl wait --for=condition=ready --timeout=600s pod my-cluster-zookeeper-2 -n kafka

echo "Creating kafka pods"
sleep 30s
kubectl wait --for=condition=ready --timeout=600s pod my-cluster-kafka-0 -n kafka
kubectl wait --for=condition=ready --timeout=600s pod my-cluster-kafka-1 -n kafka
kubectl wait --for=condition=ready --timeout=600s pod my-cluster-kafka-2 -n kafka

echo "Creating Kafka cluster"
sleep 15s
kubectl wait --for=condition=available --timeout=600s deployment.apps/my-cluster-entity-operator -n kafka

echo "Creating Kafka cruise-control"
sleep 15s
kubectl wait --for=condition=available --timeout=600s deployment.apps/my-cluster-cruise-control -n kafka

echo "Creating Kafka topic"
sleep 15s
kubectl apply -f kafka-topic.yaml -n kafka

echo "Rebalancing Kafka cluster"
sleep 15s
kubectl apply -f kafka-rebalance.yaml -n kafka

echo "Waiting for kafka rebalance proposal"
kubectl wait --for=condition=ProposalReady --timeout=900s kafkarebalance.kafka.strimzi.io/my-rebalance -n kafka

echo "Approve kafka rebalance proposal"
kubectl annotate kafkarebalance my-rebalance strimzi.io/rebalance=approve -n kafka

echo "Refresh kafka rebalance proposal"
sleep 30s
kubectl annotate kafkarebalance my-rebalance strimzi.io/rebalance=refresh -n kafka

echo "describe kafka rebalance proposal"
sleep 15s
kubectl describe kafkarebalance my-rebalance -n kafka

echo "Waiting for kafka rebalance proposal ready"
kubectl wait --for=condition=Ready --timeout=900s kafkarebalance.kafka.strimzi.io/my-rebalance -n kafka

echo "Creating kafka bridge to get access over http"
sleep 15s
kubectl apply -f kafka-bridge.yaml -n kafka

echo "Waiting kafka bridge to get access over http"
sleep 30s
kubectl wait --for=condition=available --timeout=600s deployment.apps/my-bridge-bridge -n kafka

echo "Create network policy to access the Kafka over LB"
kubectl apply -f kafka-np.yaml -n kafka

echo "Apply fluent bit changes to stream the container logs & Audit logs to Kafka"
sleep 10s
kubectl apply -f fluent-bit.yaml -n vmware-system-logging

echo "Restart fluent bit to apply the kakfa routings"
sleep 15s
kubectl rollout restart daemonset.apps/fluentbit -n vmware-system-logging

echo "Waiting for fluent bit rollout to apply Kafka routings"
sleep 15s
kubectl rollout status -w daemonset.apps/fluentbit -n vmware-system-logging


