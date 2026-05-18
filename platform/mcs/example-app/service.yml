# example-app/service.yml

apiVersion: v1
kind: Service
metadata:
  name: example-service
  labels:
    app: example-app
spec:
  selector:
    app: example-app
  ports:
    - protocol: TCP
      name: http
      port: 80
      targetPort: 80