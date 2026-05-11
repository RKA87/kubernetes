Pre-Requisites to configure roboshop project using Kubernets Tech
=================================================================
once EKS Cluster build/configured in aws, then run the below command to update the EKS Cluster

aws eks update-kubeconfig 
      --region <REGION> \
      --name <CLUSTER_NAME> \


Step 1: OIDC provider
---------------------
eksctl utils associate-iam-oidc-provider \
  --region <REGION> \
  --cluster <CLUSTER_NAME> \
  --approve

Step 2: Install Helm for installing the drivers using Helm
----------------------------------------------------------
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

Step 3: Create IAM Service Account for ebs, efs and aws load balancer with Association IRSA role
-------------------------------------------------------------------------------------------------
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster <cluster_name> \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole

eksctl create iamserviceaccount \
  --name efs-csi-controller-sa \
  --namespace kube-system \
  --cluster <CLUSTER_NAME> \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EFS_CSI_DriverRole

For Ingress Controller (AWS Load Balancer) we need to download the iam policy and create the policy and association with Service Account

curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.2.1/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name <<AWSLoadBalancerControllerIAMPolicy>> \
    --policy-document file://iam-policy.json

eksctl create iamserviceaccount \
  --name aws-load-balancer-controller \
  --namespace kube-system \
  --cluster <CLUSTER_NAME> \
  --attach-policy-arn arn:aws:iam::<<ACC_ID>>:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --region us-east-1 \
  --approve

Note: <<Regarding the role k8s system will create the IAM Role Automatically>>

Step 4:
-------

<<
  Using bash to install EBS & EFS
  -------------------------------
  aws eks create-addon \
    --cluster-name <CLUSTER_NAME> \
    --addon-name aws-ebs-csi-driver \
    --service-account-role-arn arn:aws:iam::<ACCOUNT_ID>:role/AmazonEKS_EBS_CSI_DriverRole

  aws eks create-addon \
    --cluster-name <CLUSTER_NAME> \
    --addon-name aws-efs-csi-driver \
    --service-account-role-arn arn:aws:iam::<ACCOUNT_ID>:role/AmazonEKS_EFS_CSI_DriverRole
>>

<<
  Using helm to install EBS & EFS
  --------------------------
  helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
  helm repo update
  helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
    --namespace kube-system \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=ebs-csi-controller-sa

  helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/ --force-update
  helm repo update
  helm upgrade --install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa
>>

  Using Helm install the aws load balancer controller (ingress)
  -------------------------------------------------------------
  helm repo add eks https://aws.github.io/eks-charts

  helm repo update

  helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=<CLUSTER_NAME> --set serviceAccount.create=<false> --set serviceAccount.name=aws-load-balancer-controller

  Note: when serviceAccount is set to false, we've alrady create the serviceAccount in step 3. Its a best practice to configure the serviceAccount first and execute the install command with false option in serviceAccount

Step 5: Verification
--------------------
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-efs-csi-driver

kubectl get pods --namespace kube-system -o wide