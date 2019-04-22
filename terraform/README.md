# Desafio 01: Infrastructure-as-code - Terraform

## Requisitos

Para executar a resolução deste desafio, você precisará instalar o Terraform. Para isso, basta seguir [essas](https://learn.hashicorp.com/terraform/getting-started/install#installing-terraform) instruções. A versão utilizada foi a `v0.11.13`.

A AWS foi a escolhida e você precisará de uma chave de acesso para que o Terraform possa interagir com os serviços providos. Siga [essas](https://aws.amazon.com/pt/blogs/security/wheres-my-secret-access-key/) instruções para obter a chave. Além disso, leia [este](https://aws.amazon.com/pt/blogs/security/a-new-and-standardized-way-to-manage-credentials-in-the-aws-sdks/) guia para saber como gerenciar suas chaves.

Além disso, será necessário um par de chaves cadastrado na região em que será criada a instância. Siga [essas](https://docs.aws.amazon.com/pt_br/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws) instruções caso você precise gerar e/ou importar suas chaves. É importante que a chave privada esteja na sua máquina em um caminho conhecido, pois esta será utilizada durante o processo de provisinamento.

## Criando sua instância

Dentro do diretório `terraform` deste repositório, execute:

```shell
$ terraform init
```

Este comando inicializará módulos e _plug-ins_ necessários para sua execução. Na próxima etapa serão pedidas variáveis de entrada que não possuem valores definidos por padrão. Recomenda-se que estas variáveis de entradas sejam colocadas em um arquivo como no exemplo abaixo. Se este for nomeado por `terraform.tfvars`, ele será carregado automaticamente, ou, se preferir pode passar como parâmetro para os comendos que o requisitarem utilizando a opção `-var-file`. O Terraform irá então sobreescrever as variáveis colocadas neste arquivo. Observe que a variável `ssh-ip-range` é uma lista, e esta foi definida com um endereço de IP com bloco CIDR `/32`, ou seja, apenas o _host_ com este endereço poderá acessar a instância via ssh. Se preferir, você pode definir um _range_ de endereços utilizando um bloco CIDR diferente de `/32`, ou ainda colocar uma lista de endereços e/ou _ranges_.

```
aws-region   = "us-east-1"
ssh-ip-range = ["200.137.67.10/32"]
key-name     = "my_keypair"
```

Agora, execute o comando abaixo para verificar quais serão as mudanças necessárias para realizar este provisionamento. Recomenda-se por salvar a saída deste comando em um arquivo, como mostrado no comando abaixo, para que seja utiliazado posteriormente.

```shell
$ terraform plan -out out.tfplan
```

Agora basta executar o seguinte comando para aplicar as mudanças:

```shell
$ terraform apply "out.tfplan"
```

Ao final será imprimido na tela o IP público desta instância. Caso queira consultá-lo posteriormente, basta executar:

```shell
$ terraform output my-instance-ip
```

## Testando a instância

Junto com a criação da instância, foi instalado nela o docker e uma imagem do Apache foi executada. De posse do ip público, acesse-o utilizando um _browser_ ou execute o comando abaixo para ver o conteúdo da página padrão.

```shell
$ MY_INSTANCE_IP=`terraform output my-instance-ip`
$ curl $MY_INSTANCE_IP
<html><body><h1>It works!</h1></body></html>
```

Você também pode accessar a instância via ssh:

```shell
$ ssh -i <PATH_TO_PRIVATE_KEY> ubuntu@$MY_INSTANCE_IP
```

## Destruindo a instância

Todo o provisionamento descrito realizado, incluindo instância e _security groups_ podem ser removidos com o comando abaixo. Lembrando que se você definiu suas variáveis em um arquivo com nome diferente que `terraform.tfvars`, você deverá especificá-lo ao executar o comando.

```shell
$ terraform destroy
```

# Descrição

## Motivação

Recursos de infraestrutura em nubvem devem sempre ser criados utilizando gerenciadores de configuração, tais como [Cloudformation](https://aws.amazon.com/cloudformation/), [Terraform](https://www.terraform.io/) ou [Ansible](https://www.ansible.com/), garantindo que todo recurso possa ser versionado e recriado de forma facilitada.

## Objetivo

- Criar uma instância **n1-standard-1** (GCP) ou **t2.micro** (AWS) Linux utilizando **Terraform**.
- A instância deve ter aberta somente às portas **80** e **443** para todos os endereços
- A porta SSH (**22**) deve estar acessível somente para um _range_ IP definido.
- **Inputs:** A execução do projeto deve aceitar dois parâmetros:
  - O IP ou _range_ necessário para a liberação da porta SSH
  - A região da _cloud_ em que será provisionada a instância
- **Outputs:** A execução deve imprimir o IP público da instância


## Extras

- Pré-instalar o docker na instância que suba automáticamente a imagem do [Apache](https://hub.docker.com/_/httpd/), tornando a página padrão da ferramenta visualizável ao acessar o IP público da instância
- Utilização de módulos do Terraform

## Notas
- Pode se utilizar tanto AWS quanto GCP (Google Cloud), não é preciso executar o teste em ambas, somente uma.
- Todos os recursos devem ser criados utilizando os créditos gratuitos da AWS/GCP.
- Não esquecer de destruir os recursos após criação e testes do desafio para não haver cobranças ou esgotamento dos créditos.