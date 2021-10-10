# https://github.com/jonashackt/vagrant-github-actions
Vagrant.configure("2") do |config|

  # Prevent SharedFoldersEnableSymlinksCreate errors
  config.vm.synced_folder ".", "/vagrant", disabled: true

	config.vm.define "ubuntu1604" do |ubuntu1604|

		ubuntu1604.vm.box = "generic/ubuntu1604"

		ubuntu1604.vm.provision :shell, inline: 'sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/'
		ubuntu1604.vm.provision :shell, inline: 'sudo bash /opt/mhn/install.sh'
	end

  config.vm.define "ubuntu1804" do |ubuntu1804|

		ubuntu1804.vm.box = "generic/ubuntu1804"

		ubuntu1804.vm.provision :shell, inline: 'sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/'
		ubuntu1804.vm.provision :shell, inline: 'sudo bash /opt/mhn/install.sh'
	end

	config.vm.define "centos6" do |centos6|

		centos6.vm.box = "generic/centos6"

		centos6.vm.provision :shell, inline: 'sudo yum install git -y'
		centos6.vm.provision :shell, inline: 'sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/'
		centos6.vm.provision :shell, inline: 'sudo bash /opt/mhn/install.sh'
	end
end
