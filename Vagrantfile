Vagrant.configure("2") do |config|
  #config.vm.box = "ubuntu/trusty64"
  config.vm.box = "ubuntu/xenial64"
  #config.vm.box = "ubuntu/bionic64"
  config.vm.provision :shell, path: "vagrant-bootstrap.sh"
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 8
  end
end
