Importance of the Service config in Kubernetes

Without a Service, there's no stable way to reach the pod because:

    # Pods get random IPs that change on restart

    # No DNS name is created for the pod

    # No load balancing across multiple pods

The Service gives you:

    # A stable ClusterIP (e.g., 10.100.2.131)

    # A DNS name (service-config-frontend.roboshop.svc.cluster.local)

    # Load balancing if you scale to multiple pods

* So yes, you need a Service to reliably communicate with your frontend pod within the cluster. And to expose it outside the cluster (to users), you'd need a NodePort, LoadBalancer, or Ingress type service instead of ClusterIP.

