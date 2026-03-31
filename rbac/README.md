- get the ca cert and ca key from the master node
- create certificate for the user
```
#start with a private key
openssl genrsa -out bob.key 2048
```
Now we have a key, we need a certificate signing request (CSR).
We also need to specify the groups that Bob belongs to.
Let's pretend Bob is part of the Shopping team and will be developing applications for the Shopping
```
openssl req -new -key bob.key -out bob.csr -subj "/CN=Bob Smith/O=Shopping"
```
Use the CA to generate our certificate by signing our CSR.
We may set an expiry on our certificate as well
```
openssl x509 -req -in bob.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out bob.crt -days 1
```
Create a cluster entry which points to the cluster and contains the details of the CA certificate:

```
kubectl config set-cluster dev-cluster --server=https://127.0.0.1:52807 \
--certificate-authority=ca.crt \
--embed-certs=true

#see changes 
nano ~/.kube/new-config

kubectl config set-credentials bob --client-certificate=bob.crt --client-key=bob.key --embed-certs=true

kubectl config set-context dev --cluster=dev-cluster --namespace=shopping --user=bob

kubectl config use-context dev
```
Give Bob Smith Access
```
cd kubernetes/rbac
kubectl create ns shopping

kubectl -n shopping apply -f .\role.yaml
kubectl -n shopping apply -f .\rolebinding.yaml
```