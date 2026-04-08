# Argo CD repository credentials (do not commit private keys)

GitHub blocks pushes that contain SSH private keys. Keep keys on your machine or in a secret manager; apply with `kubectl` or Sealed Secrets.

## `manifest-files` (GitHub)

```bash
kubectl -n argocd create secret generic manifest-files-repo \
  --from-literal=url='git@github.com:koneksi-tech/manifest-files.git' \
  --from-file=sshPrivateKey="${HOME}/.ssh/your_deploy_key" \
  --dry-run=client -o yaml \
  | kubectl label --local -f - argocd.argoproj.io/secret-type=repository -o yaml \
  | kubectl apply -f -
```

## Other remotes (e.g. Bitbucket)

Use the same pattern: `url` + `sshPrivateKey` file, label `argocd.argoproj.io/secret-type=repository`.
