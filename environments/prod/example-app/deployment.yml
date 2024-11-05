apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-deploy
  labels:
    app: example-app
spec:
  selector:
    matchLabels:
      app: example-app
  replicas: 1
  template:
    metadata:
      labels:
        app: example-app
    spec:
      containers:
      - name: example-app
        image: gingersociety/example-service  # Use Apache2 image
        ports:
        - containerPort: 80  # Apache defaults to port 80