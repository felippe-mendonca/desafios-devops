# Desafio 02: Kubernetes

## Requisitos

Para executar a resolução deste desafio você precisará de um cluster Kubernetes. A opção mais simples é instalar o [minikube](https://github.com/kubernetes/minikube) seguindo [essas](https://kubernetes.io/docs/tasks/tools/install-minikube/) instruções. Executadas corretamentes as instruções, você também instalará na sua máquina o [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/). Inicie então o cluster com o comando:

```shell
minikube start
```

Confira se seu cluster está pronto executando:

```shell
kubectl get nodes
```

Você deverá obter algo assim:

```shell
NAME       STATUS   ROLES    AGE    VERSION
minikube   Ready    master   2m3s   v1.14.0
```

## Construindo a imagem Docker

Como estamos utilizando minikube, se a imagem for construída na máquina _host_, ela terá que ser transferida para dentro da VM do minikube de alguma maneira. Isso pode ser feito enviando para um _registry_ remoto acessível pela VM. Outra opção, é construir a imagem dentro da VM do minikube. Para fazer isso, dentro da pasta raíz deste repositório execute:

```shell
minikube mount `pwd`:/develop
```

Em outro terminal, entre na VM e acesse a pasta montada com os arquivos do repositório. Por fim, construa a imagem:

```shell
minikube ssh
cd /develop/kubernetes
docker build . -f Dockerfile -t greeter-app
```

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