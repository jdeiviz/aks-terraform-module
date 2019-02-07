apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: ${letsencrypt_environment}
spec:
  acme:
    server: ${acme_server}
    email: ${issuer_email}
    privateKeySecretRef:
      name: ${letsencrypt_environment}
    http01: {}
