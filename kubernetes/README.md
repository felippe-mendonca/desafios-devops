# Desafio 02: Kubernetes

## Requisitos

Para executar a resolução deste desafio você precisará de um cluster Kubernetes. A opção mais simples é instalar o [minikube](https://github.com/kubernetes/minikube) seguindo [essas](https://kubernetes.io/docs/tasks/tools/install-minikube/) instruções. Executadas corretamentes as instruções, você também instalará na sua máquina o [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/). Inicie então o cluster com o comando:

```shell
$ minikube start
```

Confira se seu cluster está pronto executando:

```shell
$ kubectl get nodes
NAME       STATUS   ROLES    AGE    VERSION
minikube   Ready    master   2m3s   v1.14.0
```

## Construindo a imagem Docker

Como estamos utilizando minikube, se a imagem for construída na máquina _host_, ela terá que ser transferida para dentro da VM do minikube de alguma maneira. Isso pode ser feito enviando para um _registry_ remoto acessível pela VM. Outra opção, é construir a imagem dentro da VM do minikube. Para fazer isso, dentro da pasta raíz deste repositório execute:

```shell
$ minikube mount `pwd`:/develop
```

Em outro terminal, entre na VM e acesse a pasta montada com os arquivos do repositório. Por fim, construa a imagem:

```shell
$ minikube ssh
$ cd /develop/kubernetes
$ docker build . -f Dockerfile -t greeter-app
```

## Configuração do _Ingress Controller_

Antes de fazer o _deploy_ da aplicação, é necessário adicionar ao cluster um _ingress controller_. Para isso, foi escolhido o [nginx](https://github.com/kubernetes/ingress-nginx). Esse processo pode ser feito aplicando o manifesto `manifests/nginx.yaml`.

Para isso, execute o seguinte comando de dentro da pasta `kubernetes`:
```shell
$ kubectl apply -f manifests/nginx.yaml
```

## Fazendo o _deploy_ da aplicação

Dentro da pasta `kubernetes`, execute o script:

```shell
$ ./run.sh
```

E para remover todos os recursos criados pelo comando anteior:

```shell
$ ./run.sh delete
```

## Testando a aplicação

Uma vez que foi feita a configuração do _ingress_ para acessar o serviço _http_ exposto pela aplicação externamente ao cluster, podemos utlizar o IP da VM criada pelo minikube para fazer isso. Este IP pode ser obtido com o seguinte comando:

```shell
$ minikube ip
192.168.99.100
```

E então:

```shell
$ curl http://192.168.99.100/greeter
Olá Felippe Mendonça!
```

Para simular uma falha do serviço, execute:

```shell
$ curl http://192.168.99.100/greeter/make-unhealthy
```

E então monitore o estado do _Pod_. Você observará que ele será reiniciado. 

```shell
$ kubectl get pods -n greeter-app-ns
NAME                           READY   STATUS    RESTARTS   AGE
greeter-app-5b5677b566-d2xm2   1/1     Running   1          4m
```

## Observações

- No manifesto _deployment.yaml_, a política para dar _pull_ na imagem (_imagePullPolicy_) foi configurada como _Never_ apenas por que a imagem foi construída localmente. Em ambientes de produção esta configuração não faz sentido. (Mais detalhes sobre esta política [aqui](https://kubernetes.io/docs/concepts/configuration/overview/#container-images).

- O manifesto `manifests/nginx.yaml` foi adaptado do [repositório](https://github.com/kubernetes/ingress-nginx/blob/nginx-0.24.1/deploy/mandatory.yaml) oficial. As mudanças realizadas estão abaixo. Tais mudanças foram baseadas na [documentação](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#via-the-host-network) do nginx, para a configuração utilizando em _clusters bar-metal_. Foi escolhida a configuração via _host network_ por se julgar como a mais próxima de um ambiente de nuvem, uma vez que o contêiner que o controlador do nginx fica no _namespace_ de rede do _host_, sendo assim possível acessá-lo através de um IP diferente dos internos ao cluster.

```diff
@@ -186,7 +186,7 @@ subjects:
 ---
 
 apiVersion: apps/v1
-kind: Deployment
+kind: DaemonSet
 metadata:
   name: nginx-ingress-controller
   namespace: ingress-nginx
@@ -194,7 +194,6 @@ metadata:
     app.kubernetes.io/name: ingress-nginx
     app.kubernetes.io/part-of: ingress-nginx
 spec:
-  replicas: 1
   selector:
     matchLabels:
       app.kubernetes.io/name: ingress-nginx
@@ -209,6 +208,7 @@ spec:
         prometheus.io/scrape: "true"
     spec:
       serviceAccountName: nginx-ingress-serviceaccount
+      hostNetwork: true
       containers:
         - name: nginx-ingress-controller
           image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.24.1

```

- Foram adicionadas duas rotas na aplicação `app.js`. Uma para a checagem do estado do serviço, `/healthz`, e a segunda para forçar que o serviço apresente um estado que indique um problema, `/make-unhealthy`. Isso foi feito apenas para testar o _health check_ do _Pod_ criado. Em ambientes de produção essas checagens podem incluir, por exemplo, a verificação se um banco de dados está acessível.


# Descrição

## Motivação

Kubernetes atualmente é a principal ferramenta de orquestração e _deployment_ de _containers_ utilizado no mundo, práticamente tornando-se um padrão para abstração de recursos de infraestrutura. 

Na IDWall todos nossos serviços são containerizados e distribuídos em _clusters_ para cada ambiente, sendo assim é importante que as aplicações sejam adaptáveis para cada ambiente e haja controle via código dos recursos kubernetes através de seus manifestos. 

## Objetivo
Dentro deste repositório existe um subdiretório **app** e um **Dockerfile** que constrói essa imagem, seu objetivo é:

- Construir a imagem docker da aplicação
- Criar os manifestos de recursos kubernetes para rodar a aplicação (_deployments, services, ingresses, configmap_ e qualquer outro que você considere necessário)
- Criar um _script_ para a execução do _deploy_ em uma única execução.
- A aplicação deve ter seu _deploy_ realizado com uma única linha de comando em um cluster kubernetes **local**
- Todos os _pods_ devem estar rodando
- A aplicação deve responder à uma URL específica configurada no _ingress_


## Extras 
- Utilizar Helm [HELM](https://helm.sh)
- Divisão de recursos por _namespaces_
- Utilização de _health check_ na aplicação
- Fazer com que a aplicação exiba seu nome ao invés de **"Olá, candidato!"**

## Notas

* Pode se utilizar o [Minikube](https://github.com/kubernetes/minikube) ou [Docker for Mac/Windows](https://docs.docker.com/docker-for-mac/) para execução do desafio e realização de testes.

* A aplicação sobe por _default_ utilizando a porta **3000** e utiliza uma variável de ambiente **$NAME**

* Não é necessário realizar o _upload_ da imagem Docker para um registro público, você pode construir a imagem localmente e utilizá-la diretamente.