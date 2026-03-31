# install operator with helm
```
helm install community-operator mongodb/community-operator --namespace mongodb-operator --create-namespace --set operator.watchNamespace="example"
```