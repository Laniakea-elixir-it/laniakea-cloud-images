Laniakea Images
===============

Recipes for building virtual machine images for Laniaekea

Setup script
------------

The setup script can used to create Laniakea cloud images. It is compatible with CentOS 7 and Ubuntu 16.04. CentOS 7 is the recommended OS.
This script update all CentOS or Ubuntu image packages. CVMFS client is installed by default. Other installed packages: vim, wget, git.
On CentOS 7 epel repository are enabled by default.
 
The script exploits Laniakea ansible roles to install Galaxy, all its companion software and a set of tools in the image.
It is possible to install different galaxy flavours using the $galaxy_flavor environment variable (see option in-line).

For flavours availability check the Galaxy flavours repository: https://github.com/indigo-dc/Galaxy-flavors-recipes

The follwoing Galaxy flaovurs are currently available:

- galaxy-minimal: Galaxy production-grade server (Galaxy, PostgreSQL, NGINX, proFTPd, uWSGI).
- galaxy-CoVaCS: workflow for genotyping and variant annotation of whole genome/exome and target-gene sequencing data (https://www.ncbi.nlm.nih.gov/pubmed/29402227).
- galaxy-GDC_Somatic_Variant: port of the Genomic Data Commons (GDC) pipeline for the identification of somatic variants on whole exome/genome sequencing data (https://gdc.cancer.gov/node/246).
- galaxy-rna-workbench: more than 50 tools for RNA centric analysis (https://www.ncbi.nlm.nih.gov/pubmed/28582575).
- galaxy-epigen: based on Epigen project (http://www.epigen.it/).

The script support also the following special flavours:
- base_image: an up-to-date image with all needed galaxy dependencies to speed-up Galaxy deployment
- update_image: used to update the base_image.

Control variables
-----------------

Ansible is installed in a virtual environment.
It is possibile to configure the path of the virtual environment and the Ansible version.
By default, since the INDIGO PaaS Orchestrator and the Infrastructure Manager, currently, are using ansible 2.3.3.0, the same version is used.

``ansible_venv``: /tmp/myansible

``ANSIBLE_VERSION``: 2.3.3.0

Galaxycloud ansible roles branch.
This script exploits Laniakea ansible roles in INDIGO GitHub repository.
It is possible to configure ansible roles branch to download. By default the master branch is used.

indigo-dc.galaxycloud: install the Galaxy production environment

``BRANCH``: 'master'

indigo-dc.galaxycloud-tools: install Galaxy tools and dependencies 

``TOOLS_BRANCH``: 'master'

Ansible roles installation directory

``role_dir``: /tmp/roles

It is possible to automatically download a script to clean the image:
https://raw.githubusercontent.com/Laniakea-elixir-it/laniakea-images/devel/scripts/clean_instance.sh
The script is automatically downloaded to /tmp/clean_instance.sh and has to be run manually
after the setup procedure.

``download_clean_instance_script``: true

Specific configuration for Laniakea@ReCaS
Enable ReCaS 2-nic configuration
WARNING: DO NOT ENABLE
``enable_2nic_config``: false

On Galaxy cluster express the galaxy user must be already created in the image, to grant the right permissions.
The galaxy user is created with 4001 UID and GID, that are the galaxy user default UID and GID on galaxy images, thus granting the right permissions.
Enable this option only for worker nodes image creation.
To create the image for the worker nodes set the galaxy_flavor to base_image.

``create_galaxy_user``: false

Create a tar.gz with conda tools dependencies on /export
The created tarball will have the galaxy flavour name.

``create_tool_deps_tar``: true

Playbook variables
The default playbook is located here: https://raw.githubusercontent.com/Laniakea-elixir-it/laniakea-images/master/playbooks/galaxy.yml

``repository_url``: 'https://raw.githubusercontent.com/Laniakea-elixir-it/laniakea-images/master'

``playbook``: 'galaxy.yml'

Set the Galaxy version.

``galaxy_version``: "release_19.05"

Set the galaxy flavors.
- "base_image": an up-to-date image with all needed galaxy dependencies to speed-up Galaxy deployment
- "update_image": used to update the base_image.
- galaxy-no-tools
- galaxy-CoVaCS
- galaxy-GDC_Somatic_Variant
- galaxy-rna-workbench
- galaxy-epigen

``galaxy_flavor``: "galaxy-no-tools"

Install a ssh public key on Galaxy and root user.
This key will be removed after Galaxy and tools installation.
See the galaxy playbook: https://raw.githubusercontent.com/Laniakea-elixir-it/laniakea-images/master/playbooks/galaxy.yml

``galaxy_instance_key_pub``: ""

Path for tools install.

``export_dir``: "/export"

Usage with Packer
-----------------

json variables
--------------

``tenant_id``: your tenant id on openstack

``ssh_keypair_name``: ssh_keypair_name present in openstack

``ssh_private_key_file``: path to the private key on the packerVM

``username``: openstack username 

``password``: openstack password

``region``: openstack region

``domain_name``: openstack domain name (if your openstack installation use domain, if not omit it)

``ssh_username``: user of the Vm that will be used to create the image

``image_name``: chose a name for your immage

``source_image``: image ID of the base image present on openstack

``vm_flavour``: flavor of the vm that will be deployed

``networks``: openstack network ID (has to be the same of packer VM )

``security_groups": name of the security group (port 22 has to be open to allow ssh protocol)

Procedure
---------

- Create an Ubuntu VM on the Openstack tenant minimum requirements (2vcpu, 4Gb RAM, storage 40Gb)
- Install [Packer] (https://packer.io/intro/getting-started/install.html) and move the binary to `/usr/bin`
- Git clone this repository
- Add `export OS_AUTH_URL=https://<keystoneendpoint>:5000/v3` to `~/.bashrc` and `source ~/.bashrc`
- Open `TestPackerGalaxy.json` and configure it with the variables are present on your `openrc.sh`
- Configure `setupLogScreen.sh` as explained in Setup script section
- Run the packer script `packer build TestPackerGalaxy.json`
- The image will be added to Glance


Author
------

setup script: Tangaro Marco: ma.tangaro@ibiom.cnr.it
Packer implementation: Mandreoli Pietro: pietro.mandreoli@unimi.it
