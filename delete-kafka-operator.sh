kubectl apply -f /usr/lib/vmware-wcp/objects/common/99-fluentbit/fluentbit.yaml -n vmware-system-logging

sleep 5s

kubectl rollout restart daemonset.apps/fluentbit -n vmware-system-logging
sleep 5s
kubectl rollout status -w daemonset.apps/fluentbit -n vmware-system-logging

sleep 5s
kubectl delete -f kafka-bridge.yaml -n kafka

kubectl delete -f kafka-rebalance.yaml -n kafka

kubectl delete -f kafka-topic.yaml -n kafka

kubectl delete -f kafka-operator.yaml -n kafka

kubectl delete -f kafka-crd.yaml -n kafka

kubectl delete -f kafka-np.yaml -n kafka
