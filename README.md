# Provision and Configure Server (terraform + ansible fully automated)
This is a project where the terraform script will provision the resources and execute the ansible script to configure the servers with the required configuration needed.

## Architecture
<img src="https://github.com/rghdrizzle/Docker-ansible-project-2-/blob/main/ansibleproject2workflow.png">

## Explanation
The terraform file is the usual script to provision the resources required but there is one change made to actually automate the process of provisioning and configuring the servers.
Now before I show you the changes let us see why we need to automate this process. Well first normally we would execute the terrafrom file and ansible script separately to provision and configure the server respectively. Instead of us manually executing separatly we can automate the whole process by letting terrafrom execute the ansible script in the server while it provisions , this improves the workflow and efficiency of the process.
```HCL:
provisioner "local-exec" {
    working_dir = "./ansible"
    command = "ansible-playbook --inventory '${self.public_ip_address},' deploy-docker.yaml --private-key ${var.ssh_key_path} --user azureuser"
  }
  ```
This block of code is inside the resource block of the virtual machine. This is responsible for executing a local file in the host machine. As you can see I told the script to go to the directory where the ansible scripts are present and then told the script to execute the `ansible-playbook` command to run the playbook and configure the server. I could have used a <a href="https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource">null_resource</a> from terraform to execute this separatly instead of it running inside the vm resource block.

## Outputs

### Resources provisioned by terraform
<img src="https://github.com/rghdrizzle/Docker-ansible-project-2-/blob/main/Screenshot%20(182).png">

### Outputs after executing the terraform script
As you can see it also configured the server with the help of ansible and in the last image you can find that docker has been successfully installed in the server
<img src="https://github.com/rghdrizzle/Docker-ansible-project-2-/blob/main/Screenshot%20(179).png">
<img src="https://github.com/rghdrizzle/Docker-ansible-project-2-/blob/main/Screenshot%20(180).png">
<img src="https://github.com/rghdrizzle/Docker-ansible-project-2-/blob/main/Screenshot%20(181).png">
## Thank you
Thank you for reading this.

### Links used
https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
https://docs.ansible.com/ansible/latest/collections/ansible/builtin/wait_for_module.html
https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax
