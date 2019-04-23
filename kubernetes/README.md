# Desafio 02: Kubernetes

## Requisitos

Para executar a resolução deste desafio você precisará de um _cluster_ Kubernetes. A opção mais simples é instalar o [minikube](https://github.com/kubernetes/minikube) seguindo [essas](https://kubernetes.io/docs/tasks/tools/install-minikube/) instruções. Executadas corretamentes as instruções, você também terá instalado na sua máquina o [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/). Inicie então o _cluster_ com o comando:

```shell
$ minikube start
```

Confira se seu cluster está pronto executando:

```shell
$ kubectl get nodes
NAME       STATUS   ROLES    AGE    VERSION
minikube   Ready    master   2m3s   v1.14.0
```

Além disso, você poderá escolher por fazer o _deploy_ da aplicação utilizando o [HELM](https://helm.sh). Se assim preferir, siga as [instruções](https://helm.sh/docs/using_helm/#installing-the-helm-client) de instalação e depois execute o comando abaixo. Este comando iniciará o _Tiller_, o servidor do HELM que se comunica com o _cluster_. Mais detalhes de como instalar o _Tiller_ podem ser encontrados [aqui](https://helm.sh/docs/using_helm/#installing-tiller).

```shell
$ helm init
```

## Construindo a imagem Docker

Como estamos utilizando minikube, se a imagem for construída na máquina _host_ ela terá que ser transferida para dentro da VM do minikube de alguma maneira. Isso pode ser feito enviando para um _registry_ remoto acessível pela VM. Outra opção, é construir a imagem dentro da VM do minikube. Para fazer isso, dentro da pasta raíz deste repositório execute:

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

Antes de fazer o _deploy_ da aplicação, é necessário adicionar ao cluster um _ingress controller_. Para isso, foi escolhido o [nginx](https://github.com/kubernetes/ingress-nginx). Esse processo pode ser feito aplicando manifestos ou utilizando o HELM. Escolha a opção que preferir e execute os comandos dentro da pasta `kubernetes`. Neste controlador é possível definir um _backend_ padrão no qual as rotas inexistentes serão redirecionadas. Para a configuração feita com o HELM ele é criado automaticamente, por outro lado, ao se utilizar os manifestos, deve-se também aplicar um manifesto específico que faz o _deploy_ do _backend_ e cria um serviço para este, que por sua vez é acessado pelo _ingress controller_. Vale ressaltar que neste caso está sendo utilizado um _backend_ que retorna uma mensagem padrão, mas qualquer outro serviço poderia ser configurado como o _backend_ padrão para este _ingress controller_.

* ### k8s-manifests

```shell
$ kubectl apply -f manifests/nginx.yaml -f manifests/nginx-default-backend.yaml
```

* ### helm

```shell
$ helm install stable/nginx-ingress -f helm-values/nginx.yaml  --version 1.5.0 --namespace apps-ingress --name apps-ingress
```

De acordo com a [documentação](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#via-the-host-network) do nginx, ao se utilizar a configuração com _host network_, recomenda-se desabilitar o serviço criado para o controlador. Contudo, o HELM _chart_ do nginx não o faz e nem oferece a opção para desabilitar. Portanto, deve-se também executar o comando a seguir para excluir este serviço criado. Mais detalhes nas [observações](#observações).

```shell
$ kubectl get svc -n apps-ingress -o name | grep controller | xargs kubectl delete -n apps-ingress
```

### Verificando a configuração do _ingress controller_

Todos os recursos do controlador são provisionados no namespace _apps-ingress_. Esses recursos podem ser listados executando:

```shell
$ kubectl get all -n apps-ingress
NAME                                                 READY   STATUS    RESTARTS   AGE
pod/nginx-ingress-controller-2sprn                   1/1     Running   0          17m
pod/nginx-ingress-default-backend-84dccf4b65-2sqb4   1/1     Running   0          17m

NAME                                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/nginx-ingress-default-backend   ClusterIP   10.105.36.203   <none>        80/TCP    17m

NAME                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/nginx-ingress-controller   1         1         1       1            1           <none>          17m

NAME                                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-ingress-default-backend   1/1     1            1           17m

NAME                                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-ingress-default-backend-84dccf4b65   1         1         1       17m
```

Uma vez que existe um _backend_ padrão associado ao controlador, pode-se testar o funcionamento deste acessando no _browser_ o IP da VM criada pelo minikube, uma vez que o controlador foi configurado no _namespace_ de rede da VM (_host network_). Para obter este endereço, execute:

```shell
$ minikube ip
192.168.99.100
```

Ou se preferir, ao invés de acessar no _browser_:

```shell
$ curl 192.168.99.100
default backend - 404
```

## Fazendo o _deploy_ da aplicação

Escolha o método que preferir e execute o comando dentro da pasta `kubernetes`:

* ### k8s-manifests

```shell
$ ./scripts/run-manifests.bash
```

* ### helm

```shell
$ ./scripts/run-helm.bash
```

### Verificando o funcionamento da aplicação

Os recursos criados após o _deploy_ da aplicação são alocados no _namespace_ `greeter-app-ns`. Assim como foi feito para o _ingress controller_, os recursos podem ser listados:

```shell
$ kubectl get all -n greeter-app-ns
NAME                              READY   STATUS    RESTARTS   AGE
pod/greeter-app-cb6449577-6k5wt   1/1     Running   0          14s

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/greeter-app   ClusterIP   10.100.44.178   <none>        80/TCP    14s

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/greeter-app   1/1     1            1           14s

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/greeter-app-cb6449577   1         1         1       14s
```

Uma vez que foi feita a configuração do _ingress_ para acessar o serviço _http_ exposto pela aplicação,  este pode ser acecssado utilizando o IP da VM do minikube, assim como foi feito para se testar o _ingress controller_. Foram adicionadas ás rotas da aplicação o caminho `/greeter`. Portanto, para testar a aplicação, execute o comando abaixo ou acesse esta URL no _browser_.

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

## Removendo a aplicação

Todos os recursos da aplicação são no _namespace_ _greeter-app-ns_, portanto ao excluí-lo, todos os recursos são deletados. Entretando, é possível realizar a remoção com os _scripts_ utilizados para fazer o _deploy_ da aplicação. Dependendo do método escolhido, execute o comando abaixo:

* ### k8s-manifests

```shell
$ ./scripts/run-manifests.bash delete
```

* ### helm

```shell
$ ./scripts/run-helm.bash delete
```

## Observações

- O manifesto `manifests/nginx.yaml` foi adaptado do [repositório](https://github.com/kubernetes/ingress-nginx/blob/nginx-0.24.1/deploy/mandatory.yaml) oficial. As mudanças realizadas estão abaixo. Tais mudanças foram baseadas na [documentação](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#via-the-host-network) do nginx, para a configuração em _clusters bar-metal_. Foi escolhida a configuração via _host network_ por se julgar como a mais próxima de um ambiente de nuvem, uma vez que o contêiner que o controlador do nginx fica no _namespace_ de rede do _host_, sendo assim possível acessá-lo através de um IP diferente dos internos ao cluster.

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

- Ao se configurar o _ingress controller_ utilizando o HELM, foi removido o serviço criado associado ao controlador após a instalação, devido a uma [recomendação](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#via-the-host-network) da documentação do nginx ao se fazer a instalação via _host network_. Este problema também foi reportado nesta [_issue_](https://github.com/helm/charts/issues/10921), e já existe um [_pull request_](https://github.com/helm/charts/pull/11911) pendente para fixá-la.

- Foram adicionadas duas rotas na aplicação `app.js`. Uma para a checagem do estado do serviço, `/healthz`, e a segunda, `/make-unhealthy` que força o serviço a apresentar um estado que indique um problema. Isso foi feito apenas para testar o _health check_ do _Pod_ criado. Em ambientes de produção essas checagens podem incluir, por exemplo, a verificação se um banco de dados está acessível, e então, indicar ou não uma falha.

- Tanto no manifesto _deployment.yaml_ quanto no arquivo de configuração _greeter-app-values.yaml_, a política para dar _pull_ na imagem (_imagePullPolicy_) foi configurada como _Never_. Isso por que a imagem foi construída localmente e não foi enviada para um _registry_. Em ambientes de produção esta configuração não faz sentido. (Mais detalhes sobre esta política [aqui](https://kubernetes.io/docs/concepts/configuration/overview/#container-images)).

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