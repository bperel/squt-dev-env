# squt-dev-env
A Vagrant box to setup the environment necessary for next-gen squt development

# How to install
```bash
vagrant plugin install vagrant-vbguest
vagrant up
```
# Misc

The `vagrant-vbguest` plugin that allows to install guest additions on the VM is a bit buggy, you may have to install them manually through the Virtualbox GUI