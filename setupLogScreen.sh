#!/bin/bash

# ELIXIR-ITALY
# IBIOM-CNR
#
# Contributors:
# author: Tangaro Marco Antonio
# email: ma.tangaro@ibiom.cnr.it
#
# This script can used to create Laniakea cloud images. It is compatible with CentOS 7 and Ubuntu 16.04.
# CentOS 7 is the recommended OS.
# This script update all image packages.
# CVMFS client is installed by default
# Other installed packages: vim, wget, git.
# On CentOS 7 epel repository are enabled by default.
# 
# The script exploits Laniakea ansible roles to install Galaxy, all its companion software and a set of tools in the image.
# It is possible to install different galaxy flavours using the $galaxy_flavor environment variable (see option in-line).
# For flavours availability check the README file: https://github.com/Laniakea-elixir-it/laniakea-images/blob/master/README.md
# and the Galaxy flavours repository: https://github.com/indigo-dc/Galaxy-flavors-recipes
# The script support also the following special flavours:
# "base_image": an up-to-date image with all needed galaxy dependencies to speed-up Galaxy deployment
# "update_image": used to update the base_image.
#
# Usage: /bin/bash setup.sh

#________________________________
# Control variables

# Ansible is installed in a virtual environment.
# It is possibile to configure the path of the virtual environment and the Ansible version.
# By default, since the INDIGO PaaS Orchestrator and the Infrastructure Manager, currently, are using ansible 2.2.1, the same version is used.
ansible_venv=/tmp/myansible
ANSIBLE_VERSION=2.3.3.0

# Galaxycloud ansible roles branch.
# This script exploits Laniakea ansible roles in INDIGO GitHub repository.
# It is possible to configure ansible roles branch to download. By default the master branch is used.
#
# indigo-dc.galaxycloud: install the Galaxy production environment
BRANCH='master'
# indigo-dc.galaxycloud-tools: install Galaxy tools and dependencies 
TOOLS_BRANCH='master'

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
# To create the image for the worker nodes set the galaxy_flavor to base_image.
create_galaxy_user=false

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
# galaxy-vinyl
galaxy_flavor="galaxy-testing-lite"
# Install a ssh public key on Galaxy and root user.
# This key will be removed after Galaxy and tools installation.
# See the galaxy playbook: https://raw.githubusercontent.com/Laniakea-elixir-it/laniakea-images/master/playbooks/galaxy.yml
galaxy_instance_key_pub=""
# Path for tools install.
export_dir="/export"

# Attach nfs to provide external storage to packer



# Create a tar.gz with conda tools dependencies on /export
# The created tarball will have the galaxy flavour name and version tag.
# Tools will be uploaded on Openstack Swift, if properly configured.
create_tool_deps_tar=true

# Switft details
swift_OS_PROJECT_DOMAIN_ID=default
swift_OS_USER_DOMAIN_ID=default
swift_OS_PROJECT_NAME=INDIGO_CNR
swift_OS_TENANT_NAME=INDIGO_CNR
swift_OS_USERNAME=*****
swift_OS_PASSWORD=*****
swift_OS_AUTH_URL=https://cloud.recas.ba.infn.it:5000/v3
swift_OS_IDENTITY_API_VERSION=3
swift_OS_REGION=recas-cloud

swift_container=Laniakea-galaxy-tools-tar-999
galaxy_flavor_image_tag=999

#________________________________
# Start logging
LOGFILE="/tmp/setup.log"
now=$(date +"%b %d %y - %H.%M.%S")
rm -f $LOGFILE
echo "Start log: ${now}"
echo "Start log: ${now}" &>>  $LOGFILE

#________________________________
# Get Distribution
DISTNAME=''
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo $ID 
    if [ "$ID" = "ubuntu" ]; then
      echo 'Distribution Ubuntu' 
      DISTNAME='ubuntu'
    else
      echo 'Distribution: CentOS' 
      DISTNAME='centos'
    fi
else
    echo "Not running a distribution with /etc/os-release available" 
fi

#________________________________
# Install prerequisites
function prerequisites(){

  if [[ $DISTNAME = "ubuntu" ]]; then
    apt-get -y update
    apt-get -y install git vim wget
  else
    yum install -y epel-release
    yum update -y
    yum install -y git vim wget
  fi

}

#________________________________
# Ansible management
function install_ansible(){

  echo 'Remove ansible virtualenv if exists'
  rm -rf $ansible_venv

  if [[ $DISTNAME = "ubuntu" ]]; then
    #Remove old ansible as workaround for https://github.com/ansible/ansible-modules-core/issues/5144
    dpkg -r ansible
    apt-get autoremove -y
    apt-get -y update
    apt-get install -y python-pip python-dev libffi-dev libssl-dev python-virtualenv
  else
    yum install -y epel-release
    yum update -y
    yum groupinstall -y "Development Tools"
    yum install -y python-pip python-devel libffi-devel openssl-devel python-virtualenv
  fi

  # Install ansible in a specific virtual environment
  virtualenv --system-site-packages $ansible_venv
  . $ansible_venv/bin/activate
  pip install pip --upgrade

  #install ansible 2.2.1 (version used in INDIGO)
  pip install ansible==$ANSIBLE_VERSION

  # workaround for https://github.com/ansible/ansible/issues/20332
  cd $ansible_venv
  wget https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg  -O $ansible_venv/ansible.cfg

  sed -i 's\^#remote_tmp     = ~/.ansible/tmp.*$\remote_tmp     = $HOME/.ansible/tmp\' $ansible_venv/ansible.cfg
  sed -i 's\^#local_tmp      = ~/.ansible/tmp.*$\local_tmp      = $HOME/.ansible/tmp\' $ansible_venv/ansible.cfg
  #sed -i 's:#remote_tmp:remote_tmp:' /tmp/myansible/ansible.cfg

  # Enable ansible log file
  sed -i 's\^#log_path = /var/log/ansible.log.*$\log_path = /var/log/ansible.log\' $ansible_venv/ansible.cfg

}

# Remove ansible
function remove_ansible(){

  echo "Removing ansible venv"
  deactivate
  rm -rf $ansible_venv

  echo 'Removing roles'
  rm -rf $role_dir

  echo 'Removing ansible'
  if [[ $DISTNAME = "ubuntu" ]]; then
    apt-get -y autoremove ansible
  else
    yum remove -y ansible
  fi

}

#________________________________
# Install ansible roles
function install_ansible_roles(){

  mkdir -p $role_dir

  # Dependencies
  ansible-galaxy install --roles-path $role_dir indigo-dc.cvmfs-client

  # 1. indigo-dc.galaxycloud
  git clone https://github.com/indigo-dc/ansible-role-galaxycloud.git $role_dir/indigo-dc.galaxycloud
  cd $role_dir/indigo-dc.galaxycloud && git checkout $BRANCH

  # 2. indigo-dc.galaxycloud-tools
  git clone https://github.com/indigo-dc/ansible-role-galaxycloud-tools.git $role_dir/indigo-dc.galaxycloud-tools
  cd $role_dir/indigo-dc.galaxycloud-tools && git checkout $TOOLS_BRANCH

}

#________________________________
# Postgresql management
function start_postgresql(){

  echo 'Start postgresql'
  if [[ $DISTNAME = "ubuntu" ]]; then
    systemctl start postgresql
  else
    systemctl start postgresql-9.6
  fi

}

#________________________________
# Stop all services with rigth order
function stop_services(){

  echo 'Stop Galaxy'
  /usr/bin/galaxyctl stop galaxy --force

  # shutdown supervisord
  echo 'Stop supervisord'
  kill -INT `cat /var/run/supervisord.pid`

  # stop postgres
  echo 'Stop postgresql'
  if [[ $DISTNAME = "ubuntu" ]]; then
    systemctl stop postgresql
    systemctl disable postgresql
  else
    systemctl stop postgresql-9.6
    systemctl disable postgresql-9.6
  fi

  # stop nginx
  echo 'Stop nginx'
  systemctl stop nginx
  systemctl disable nginx

  # stop proftpd
  echo 'Stop proftpd'
  systemctl stop proftpd
  systemctl disable proftpd

}

#________________________________
# Start all services with rigth order
function start_services(){

  # start postgres
  echo 'Start postgresql'
  if [[ $DISTNAME = "ubuntu" ]]; then
    systemctl start postgresql
    systemctl enable postgresql
  else
    systemctl start postgresql-9.6
    systemctl enable postgresql-9.6
  fi

  # start nginx
  echo 'Start nginx'
  systemctl start nginx
  systemctl enable nginx

  # start proftpd
  echo 'Start proftpd'
  systemctl start proftpd
  systemctl enable proftpd

  # start galaxy
  echo 'Start Galaxy'
  /usr/local/bin/galaxy-startup

}

#________________________________
# Run playbook
function run_playbook(){
  echo "Download playbook" 
  echo "${repository_url}/playbooks/$playbook"  

  wget ${repository_url}/playbooks/$playbook -O /tmp/playbook.yml
  
  cd $ansible_venv
  ansible-playbook /tmp/playbook.yml  --extra-vars "galaxy_version=$galaxy_version galaxy_flavor=$galaxy_flavor galaxy_instance_key_pub=$galaxy_instance_key_pub export_dir=$export_dir"

}

#________________________________
function build_base_image () {

  # Install depdendencies
  if [[ $DISTNAME = "ubuntu" ]]; then
    apt-get -y update
    apt-get -y install python-pip python-dev libffi-dev libssl-dev
    apt-get -y install git vim python-pycurl wget
  else
    yum install -y epel-release
    yum update -y
    yum groupinstall -y "Development Tools"
    yum install -y python-pip python-devel libffi-devel openssl-devel
    yum install -y git vim python-curl wget
    # fix font problem with centos and fastqc tool.
    yum install -y fontconfig dejavu*
    /usr/bin/fc-cache /usr/share/fonts/dejavu
  fi

  # Create galaxy user
  if $create_galaxy_user; then
    echo 'Create galaxy user with uid and gid'
    groupadd -g 4001 galaxy
    useradd -M -u 4001 -g 4001 galaxy
  fi


  # Install cvmfs packages
  echo 'Install cvmfs client'
  if [[ $DISTNAME = "ubuntu" ]]; then
    wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb -O /tmp/cvmfs-release-latest_all.deb
    sudo dpkg -i /tmp/cvmfs-release-latest_all.deb
    rm -f /tmp/cvmfs-release-latest_all.deb
    sudo apt-get update
    apt-get install -y cvmfs cvmfs-config-default
  else
    yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
    yum install -y cvmfs cvmfs-config-default
  fi

}

#________________________________
# Clean package manager cache
function clean_package_manager_cache(){

  echo "Clean package manager cache"
  if [[ $DISTNAME = "ubuntu" ]]; then
    apt-get clean
  else
    yum clean all
  fi

}

#________________________________
# Copy remove cloud-init artifact and user  script
# Run this script after setup finished
function copy_clean_instance_script(){
  wget ${repository_url}/scripts/clean_instance.sh -O /tmp/clean_instance.sh
  chmod +x /tmp/clean_instance.sh
}

#________________________________
# MAIN FUNCTION

{

# install dependencies
prerequisites

if [[ $galaxy_flavor == "base_image" ]]; then
  build_base_image

elif [[ $galaxy_flavor == "update_image" ]]; then
  # The image is updated running prerequisites.
  # Stop services if running
  stop_services

else
  # Update and prepare image
  build_base_image
  # Prepare the system: install ansible, ansible roles
  install_ansible
  install_ansible_roles
  # Run ansible play
  run_playbook
  # Stop all services and remove ansible
  stop_services
  remove_ansible

fi

# Clean the environment
clean_package_manager_cache
if $download_clean_instance_script; then
  copy_clean_instance_script
fi

# Configure image for 2 nic
if $enable_2nic_config; then
  wget https://raw.githubusercontent.com/Laniakea-elixir-it/HEAT-templates/master/recas-nic-config/centos/preconfig.sh -O /tmp/preconfig.sh
  chmod +x /tmp/preconfig.sh
  /tmp/preconfig.sh
fi

# Create tool deps tar gz
# and upload on Swift
if $create_tool_deps_tar; then

  cd $export_dir

  tarball_file=$galaxy_flavor-$galaxy_version-$galaxy_flavor_image_tag.tar.gz
  tar cvzf $tarball_file tool_deps

  # Install Swift client
  virtualenv --system-site-packages /tmp/swift_venv
  . /tmp/swift_venv/bin/activate
  pip install pip --upgrade
  pip install python-swiftclient==3.4.0 python-keystoneclient==3.14.0

  # Upload data
  swift upload --insecure \
        --os-auth-url $swift_OS_AUTH_URL \
        --os-identity-api-version 3 \
        --os-project-domain-id  $swift_OS_PROJECT_DOMAIN_ID \
        --os-user-domain-id $swift_OS_USER_DOMAIN_ID \
        --os-region-name $swift_OS_REGION \
        --os-project-name $swift_OS_PROJECT_NAME \
        --os-tenant-name $swift_OS_PROJECT_NAME \
        --os-username $swift_OS_USERNAME \
        --os-password $swift_OS_PASSWORD \
        $swift_container -S 1073741824 $tarball_file

  # Clean environment
  rm -rf /tmp/swift_venv
  rm -rf $export_dir

fi

} 

echo 'End setup script' 

