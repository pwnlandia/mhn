# https://github.com/jonashackt/vagrant-github-actions
Vagrant.configure("2") do |config|

  	# Prevent SharedFoldersEnableSymlinksCreate errors
	config.vm.synced_folder ".", "/vagrant", disabled: true

	config.vm.define "ubuntu1604" do |ubuntu1604|

		ubuntu1604.vm.box = "generic/ubuntu1604"

		ubuntu1604.vm.provision "dependencies", type: "shell", run: "never" do |u16ds|
			$u16dscript = <<-SCRIPT
			sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/
			sudo apt update && sudo apt upgrade -y
			sudo apt install -y python-pip
			sudo pip install --upgrade pip
			sudo apt install apt-transport-https -y
			sudo apt install build-essential -y
			sudo apt remove mongo* -y
			cd /opt/mhn/scripts/
			sudo ./install_hpfeeds.sh
			sudo ./install_mnemosyne.sh
			sudo ./install_honeymap.sh
			SCRIPT

			u16ds.inline = $u16dscript
		end

		ubuntu1604.vm.provision "shell", run: "never" do |u16s|
			$u16script = <<-SCRIPT
			sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/
			sudo bash /opt/mhn/install.sh
			SCRIPT

			u16s.inline = $u16script
		end
	end

	config.vm.define "ubuntu1804" do |ubuntu1804|

		ubuntu1804.vm.box = "generic/ubuntu1804"

		ubuntu1804.vm.provision :shell, inline: 'sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/'
		ubuntu1804.vm.provision :shell, inline: 'sudo bash /opt/mhn/install.sh'
	end

	config.vm.define "centos6" do |centos6|

		centos6.vm.box = "generic/centos6"

		centos6.vm.provision "dependencies", type: "shell", run: "never" do |c6ds|
			$c6dscript = <<-'SCRIPT' 
			sudo export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:$PATH
			sudo yum install git -y
			sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/
			cd /opt/mhn/scripts/
			sudo yum repolist
			sudo yum grouplist | grep -i development
			sudo yum groupinfo mark install "Development Tools"
			sudo yum groupinfo mark convert "Development Tools"
			sudo yum groupinstall "Development Tools" -y
			sudo bash /opt/mhn/scripts/install_sqlite.sh
			sudo bash /opt/mhn/scripts/install_supervisord.sh
			sudo bash /opt/mhn/scripts/install_hpfeeds.sh
			sudo bash /opt/mhn/scripts/install_mnemosyne.sh
			sudo bash /opt/mhn/scripts/install_honeymap.sh
			SCRIPT
			c6ds.inline = $c6dscript
		end

		centos6.vm.provision "shell", run: "never" do |c6s|
			$c6script = <<-SCRIPT
			sudo yum install git -y
			sudo git clone https://github.com/pwnlandia/mhn.git /opt/mhn/
			sudo bash /opt/mhn/install.sh
			SCRIPT

			c6s.inline = $c6script
		end
	end
end
