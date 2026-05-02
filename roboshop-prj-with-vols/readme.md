Pre-Requisites to configure roboshop project using K8S tech

Step 1: OIDC provider
eksctl utils associate-iam-oidc-provider --cluster <cluster_name> --approve

Step 2: IRSA role
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster <cluster_name> \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve

Step 3: Install the EBS 

helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system \
  --set controller.serviceAccount.create=false \
  --set controller.serviceAccount.name=ebs-csi-controller-sa

Step 4: Verify
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver