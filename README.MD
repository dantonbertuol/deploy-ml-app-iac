# Execução

1. Abra o terminal e navegue até a pasta onde você colocou o arquivo Dockerfile
2. Execute o comando `docker build -t machine-learning-app:1.0 .` para criar a imagem
3. Execute o comando para criar o container Docker `docker run -dit --name ml-app -v FULL_PATH_TO_PROJECT:/iac machine-learning-app:1.0 /bin/bash`
4. Acesse o bash do docker através do comando `docker exec -it ml-app /bin/bash` e configure as credencias da AWS através do comando `aws configure`
5. Execute o comando `cd iac/iac_deploy` para acessar a pasta onde estão os arquivos de infraestrutura
6. Execute o comando `terraform init` para inicializar o terraform
7. Execute o comando `terraform apply` para criar a infraestrutura na AWS
8. Acesse o painel da AWS e verifique se os recursos foram criados
9. A variável de output será o DNS do servidor criado, acesse o endereço, no formato `http://DNSDOSERVER:5000` e verifique se a aplicação está funcionando (pode demorar pois precisa instalar os pacotes python e iniciar o gunicorn)
   1.  Você pode verificar os processos python da instância EC2, acessando o EC2 Details, clicando na opção Connect e depois no botão Connect
   2.  Depois que abrir o terminal da máquina digite o comando `ps -ax | grep python`
10. Para destruir a infraestrutura, execute o comando `terraform destroy` e confirme a destruição dos recursos
