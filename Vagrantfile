Vagrant.configure("2") do |config|
  config.vm.box = "windows-2019-amd64"
  config.vm.provider "libvirt" do |lv, config|
    lv.memory = 2048
    lv.cpus = 2
    lv.cpu_mode = "host-passthrough"
    lv.keymap = "pt"
    config.vm.synced_folder ".", "/vagrant", type: "smb", smb_username: ENV["USER"], smb_password: ENV["VAGRANT_SMB_PASSWORD"]
  end
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = 2048
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
  end
  #config.vm.hostname = 'postgresql' # NB setting the hostname is too unreliable to use.
  config.vm.network :private_network, ip: '10.10.10.101', libvirt__forward_mode: 'route', libvirt__dhcp_enabled: false
  config.vm.provision "shell", inline: "'10.10.10.101 postgresql.example.com' | Out-File -Encoding Ascii -Append c:/Windows/System32/drivers/etc/hosts"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-chocolatey.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-base.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-certificates.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-postgresql.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-postgres_exporter.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-pgadmin.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-dbeaver.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/python/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/java/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/csharp/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/csharp-efcore/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/go/run.ps1"
end
