# https://github.com/jonashackt/vagrant-github-actions
Vagrant.configure("2") do |config|

    # Prevent SharedFoldersEnableSymlinksCreate errors
    config.vm.synced_folder ".", "/vagrant", disabled: true

	config.vm.define "server-ubuntu1604" do |server-ubuntu1604|

		server-ubuntu1604.vm.box = "bento/ubuntu-18.04"

		server-ubuntu1604.vm.provision :shell, inline: 'sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/'
		server-ubuntu1604.vm.provision :shell, inline: 'sudo bash /opt/mhn/install.sh'
	end

    config.vm.define "server-ubuntu1804" do |server-ubuntu1804|

		server-ubuntu1804.vm.box = "bento/ubuntu-18.04"

		server-ubuntu1804.vm.provision :shell, inline: 'sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/'
		server-ubuntu1804.vm.provision :shell, inline: 'sudo bash /opt/mhn/install.sh'
	end

	config.vm.define "server-centos6" do |server-centos6|

		server-centos6.vm.box = "bento/centos-6"

		server-centos6.vm.provision :shell, inline: 'sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/'
		server-centos6.vm.provision :shell, inline: 'sudo bash /opt/mhn/install.sh'
	end
end
