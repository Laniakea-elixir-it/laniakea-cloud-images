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

Usage
-----
```
/bin/bash setup.sh
```

Control variables
-----------------

Ansible is installed in a virtual environment.
It is possibile to configure the path of the virtual environment and the Ansible version.
By default, since the INDIGO PaaS Orchestrator and the Infrastructure Manager, currently, are using ansible 2.2.1, the same version is used.

``ansible_venv``: /tmp/myansible

``ANSIBLE_VERSION``: 2.2.1

Galaxycloud ansible roles branch.
This script exploits Laniakea ansible roles in INDIGO GitHub repository.
It is possible to configure ansible roles branch to download. By default the master branch is used.
indigo-dc.galaxycloud: install the Galaxy production environment

``BRANCH``: 'master'

indigo-dc.galaxycloud-tools: install Galaxy tools and dependencies 

``TOOLS_BRANCH``: 'master'

# Ansible roles installation directory
role_dir=/tmp/roles

# It is possible to automatically download a script to clean the image:
# https://raw.githubusercontent.com/Laniakea-elixir-it/laniakea-images/devel/scripts/clean_instance.sh
# The script is automatically downloaded to /tmp/clean_instance.sh and has to be run manually
# after the setup procedure.
download_clean_instance_script=true

# Specific configuration for Laniakea@ReCaS
# Enable ReCaS 2-nic configuration
# WARNING: DO NOT ENABLE
enable_2nic_config=false

# On Galaxy cluster express the galaxy user must be already created in the image, to grant the right permissions.
# The galaxy user is created with 4001 UID and GID, that are the galaxy user default UID and GID on galaxy images, thus granting the right permissions.
# Enable this option only for worker nodes image creation.
create_galaxy_user=false

# Crate a tar.gz with conda tools dependencies on /export
# The created tarball will have the galaxy flavour name.
create_tool_deps_tar=true

# Playbook variables
# The default playbook is located here: https://raw.githubusercontent.com/Laniakea-elixir-it/laniakea-images/master/playbooks/galaxy.yml
repository_url='https://raw.githubusercontent.com/Laniakea-elixir-it/laniakea-images/master'
playbook='galaxy.yml'
# Set the Galaxy version.
galaxy_version="release_19.05"
# Set the galaxy flavors.
# "base_image": an up-to-date image with all needed galaxy dependencies to speed-up Galaxy deployment
# "update_image": used to update the base_image.
# galaxy-no-tools
# galaxy-CoVaCS
# galaxy-GDC_Somatic_Variant
# galaxy-rna-workbench
# galaxy-epigen
galaxy_flavor="$galaxy_flavor"
# Install a ssh public key on Galaxy and root user.
# This key will be removed after Galaxy and tools installation.
# See the galaxy playbook: https://raw.githubusercontent.com/Laniakea-elixir-it/laniakea-images/master/playbooks/galaxy.yml
galaxy_instance_key_pub="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDy787GZIVdHW7QV+Wu2q9q5k5CiTOq04ENioVig88IIVGNqi8qiX+3fhZx/w2hhlz6AePrYu8CfVPplCRdSMjP46av53V1M7r0+yqJvuk1PC2f/rSoEL95TvaeiV28+5Wy4MC58UvYuewuhIHcbfPiXHf3NEE3scd38GXCYKLhAP28mUQ950Ar4SoWv4irv21maJwkwqn5AYXcy1yrbBZtaTbQELVPa/E6X9j+k29bn32ITmmtKBA3ne/QlFRaaYI3XggvMXhhSSIYsJUdlSOjUTriB2DraHsxMGfOPjmPXkjvrXp9MfOzjMg10fb7K2Mda8u/ujK/dvx3BnhlSIpn marco@marco-Latitude-3440"
# Path for tools install.
export_dir="/export"


Author
------

Tangaro Marco: ma.tangaro@ibiom.cnr.it
