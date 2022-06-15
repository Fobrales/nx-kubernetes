# Проект для изучения Kubernetes

## 1. Создание образа docker

### 1.1 Созданы [index.html](index.html) и [nginx.conf](nginx.conf):

``` html
// index.html

<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Hello World</title>
    </head>
    <body>
        <h2>Hello World!</h2>
        <h3>I'm Anna :)</h3>
    </body>
</html>
```
```
// nginx.conf

error_log  /var/log/nginx/error.log warn;
pid /tmp/nginx.pid;
events {
  worker_connections  1024;
}

http {

  include       /etc/nginx/mime.types;
  fastcgi_temp_path /tmp/fastcgi_temp;
  uwsgi_temp_path /tmp/uwsgi_temp;
  proxy_temp_path /tmp/proxy_temp;
  scgi_temp_path /tmp/scgi_temp;
  client_body_temp_path /tmp/client_body;
  default_type  application/octet-stream;

    server {
    index index.php index.html hello.html;
    listen 8000;
    root /app/;

    }
}
```
**Note.** Так как проект запускается в контейнере не от имени root-пользователя, ОС будет блокировать создание соответствующих папок для nginx уже после сборки образа и запуска контейнера, в логе сервера будет ошибка permission denied для операции mkdir. Аналогичная ситуация будет для команды npm install, которой нужно создать папки вне рабочего каталога. Поэтому для nginx нужно указать все необходимые пути к уже существующим папкам, начиная с папки /tmp.

### 1.2. Создан [dockerfile](dockerfile):
```docker
FROM nginx

ARG UID=1001
ARG GID=1001
ARG USER=app
RUN useradd ${USER} \
&& usermod -u $UID ${USER} \
&& groupmod -g $GID ${USER} \
&& mkdir -p /app \
&& chown -R ${USER}:${USER} /app

USER ${USER}

COPY --chown=$USER:$USER nginx.conf /etc/nginx/nginx.conf
COPY --chown=$USER:$USER index.html /app

WORKDIR /app

EXPOSE 8000
```

### 1.3. Сборка образа
```
docker build -t fobrales/web:1.0.0
```

### 1.4. Создание контейнера и запуск для теста
```
docker run -ti -p 8000:8000 --name web fobrales/web:1.0.0
```

### 1.5. Просмотр результата по адресу http://127.0.0.1:8000/index.html

![index.html](https://i.ibb.co/1ZkPV1F/image.png)

### 1.6. Аутентификация в docker с push ([DockerHub](https://hub.docker.com/r/fobrales/web)):

```
>>> docker push fobrales/web:1.0.0

The push refers to repository [docker.io/fobrales/web]
5f70bf18a086: Layer already exists
cb7aa12321df: Layer already exists
586f23514eba: Layer already exists
c48d39c09ef4: Layer already exists
33e3df466e11: Layer already exists
747b7a567071: Layer already exists
57d3fc88cb3f: Layer already exists
53ae81198b64: Layer already exists
58354abe5f0e: Layer already exists
ad6562704f37: Layer already exists
1.0.0: digest: sha256:38d7ec65852bb059146c86363d77eea11f16f1b42196cca5ed83cafabd8786e7 size: 2398
```

## 2 Запуск kubernetes

### 2.1 Установка [kubelet](https://kubernetes.io/ru/docs/tasks/tools/install-kubectl) и [minikube](https://minikube.sigs.k8s.io/docs/start/)

### 2.2 Запуск кластера:
```
>>> minikube start --embed-certs

😄  minikube v1.25.2 на Microsoft Windows 10 Pro 10.0.19044 Build 19044
✨  Используется драйвер docker на основе существующего профиля
👍  Запускается control plane узел minikube в кластере minikube
🚜  Скачивается базовый образ ...
🔄  Перезагружается существующий docker container для "minikube" ...
🐳  Подготавливается Kubernetes v1.23.3 на Docker 20.10.12 ...
    ▪ kubelet.housekeeping-interval=5m
🔎  Компоненты Kubernetes проверяются ...
    ▪ Используется образ gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Включенные дополнения: storage-provisioner, default-storageclass

❗  C:\Program Files\Docker\Docker\resources\bin\kubectl.exe is version 1.21.5, which may have incompatibilites with Kubernetes 1.23.3.
    ▪ Want kubectl v1.23.3? Try 'minikube kubectl -- get pods -A'
🏄  Готово! kubectl настроен для использования кластера "minikube" и "default" пространства имён по умолчанию
```

### 2.3 Проверка статуса, конфигов, проверка подключения к кластерам, получение namespaces командами:
```
>>> minikube status
>>> kubectl config view
>>> kubectl cluster-info
>>> kubectl get ns
>>> kubectl get all -A
```
**Результаты команд показаны на скриншотах в [.pptx файле](kubernetes.pptx).**

### 2.4 Просмотр Pod'ов:

```
>>> kubectl get pod kube-apiserver-minikube -n kube-system

NAME                      READY   STATUS    RESTARTS      AGE
kube-apiserver-minikube   1/1     Running   1 (38h ago)   38h

>>> kubectl get pod kube-apiserver-minikube -n kube-system -o yaml

```

### 2.5 Создание файла [pod.yaml](pod.yaml):
```
apiVersion: v1
kind: Pod
metadata:
  name: web
  labels:
    env: test
spec:
  containers:
  - name: webapp
    image: fobrales/web:1.0.0
    imagePullPolicy: IfNotPresent
```

### 2.6 Создание pod по манифесту pod.yaml и проверка: 
```
>>> kubectl apply -f pod.yaml -n default

pod/web created

>>> kubectl get pod web -n default --watch

AME   READY   STATUS    RESTARTS   AGE
web    1/1     Running   0          83s
```

### 2.7 Просмотр описания pod'а.

```
>>> kubectl describe pod web -n default

Name:         web
Namespace:    default
Priority:     0
Node:         minikube/192.168.49.2
Start Time:   Wed, 15 Jun 2022 15:10:53 +0300
Labels:       env=test
Annotations:  <none>
Status:       Running
IP:           172.17.0.3
IPs:
  IP:  172.17.0.3
Containers:
  webapp:
    Container ID:   docker://d55e511c6b7bd2eea5334137a7519c5c1cad3120c889f9d051ef15e92473a822
    Image:          fobrales/web:1.0.0
    Image ID:       docker-pullable://fobrales/web@sha256:38d7ec65852bb059146c86363d77eea11f16f1b42196cca5ed83cafabd8786e7
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Wed, 15 Jun 2022 15:10:55 +0300
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-z4dx6 (ro)
Conditions:
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  kube-api-access-z4dx6:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  112s  default-scheduler  Successfully assigned default/web to minikube
  Normal  Pulled     111s  kubelet            Container image "fobrales/web:1.0.0" already present on machine
  Normal  Created    110s  kubelet            Created container webapp
  Normal  Started    110s  kubelet            Started container webapp
```
### 2.7 Проброс наружу порта web-приложения и просмотр http://127.0.0.1:8080:

```
>>> kubectl port-forward pods/web 8080:8000

Forwarding from 127.0.0.1:8080 -> 8000
Forwarding from [::1]:8080 -> 8000
Handling connection for 8080
Handling connection for 8080
```
![результат](https://i.ibb.co/Xt32PHM/image.png)

### 2.8 Остановка и удаление:

```shell
kubectl delete po web
minikube stop
```
