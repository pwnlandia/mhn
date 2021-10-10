Vagrant.configure("2") do |config|
	# If attempting unattended this will skip the request for SMB credentials
	config.vm.synced_folder '.', '/vagrant', disabled: true
	config.vm.define "server" do |server|
		# These images are regularly updated and compatible
		# with hyperv, parallels, virtualbox, and vmware_desktop
		#server.vm.box = "bento/ubuntu-16.04"
		server.vm.box = "bento/ubuntu-18.04"
		#server.vm.box = "bento/centos-6"
		server.vm.provider "hyperv" do |hv|
			hv.memory = 4096
			hv.cpus = 2
		end
		# If attempting unattended without SMB the repo needs
		# to be downloaded
		server.vm.provision :shell, inline: 'sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/'
		# Absolute path needs to be specified
		server.vm.provision :shell, inline: 'sudo bash /opt/mhn/install.sh'
	end
end
