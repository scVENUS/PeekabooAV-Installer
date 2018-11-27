# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder '.', '/home/vagrant/peekabooav-installer'

  config.vm.define "peekaboo" do |peekaboo|
    peekaboo.vm.box       = "generic/ubuntu1804"
    peekaboo.vm.hostname  = "peekabooav.int"
    config.ssh.username   = 'vagrant'
    config.ssh.password   = 'vagrant'
    config.ssh.insert_key = 'true'

    peekaboo.vm.network "private_network", ip: "192.168.56.5"
    #peekaboo.vm.network "public_network", type: "dhcp"
    peekaboo.vm.network "forwarded_port", guest: 8000, host: 8000, host_ip: "127.0.0.1"

    peekaboo.vm.provider "virtualbox" do |vb|
      vb.name   = "PeekabooAV"
      vb.memory = 2048
      vb.cpus   = 2
    end
  end

  config.vm.provision "shell" do |install|
    # change directory first (args + env not suitable)
    install.inline = "/bin/bash -c 'cd peekabooav-installer; NOANSIBLE=yes ./PeekabooAV-install.sh --quiet'"
  end

  config.vm.provision "ansible_local" do |ansible|
    ansible.become         = true
    ansible.provisioning_path = "/home/vagrant/peekabooav-installer"
    ansible.playbook       = "PeekabooAV-install.yml"
    ansible.inventory_path = "ansible-inventory"
    ansible.limit          = "all"
  end

  config.vm.provision 'shell', inline: 'passwd --delete vagrant'
end
