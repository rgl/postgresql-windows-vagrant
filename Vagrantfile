Vagrant.configure("2") do |config|
  config.vm.box = "windows-2022-amd64"
  config.vm.provider "libvirt" do |lv, config|
    lv.memory = 4*1024
    lv.cpus = 2
    lv.cpu_mode = "host-passthrough"
    lv.keymap = "pt"
    config.vm.synced_folder ".", "/vagrant", type: "smb", smb_username: ENV["USER"], smb_password: ENV["VAGRANT_SMB_PASSWORD"]
    # rsync the examples because some of them do not work correctly over SMB.
    config.vm.synced_folder 'examples', '/examples', type: 'rsync', rsync__exclude: [
      '.vagrant/',
      '.git/',
      '*.box']
  end
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = 4*1024
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
  end
  config.vm.hostname = "postgresql"
  config.vm.network :private_network, ip: "10.10.10.101", libvirt__forward_mode: "none", libvirt__dhcp_enabled: false
  config.vm.provision "shell", inline: "'10.10.10.101 postgresql.example.com' | Out-File -Encoding Ascii -Append c:/Windows/System32/drivers/etc/hosts"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-chocolatey.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-base.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-certificates.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-postgresql.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-postgres_exporter.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-pgadmin.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "c:/examples/java/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "c:/examples/python/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "c:/examples/python-asyncpg/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "c:/examples/csharp/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "c:/examples/csharp-efcore/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "c:/examples/go/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "c:/examples/go-pgx/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "c:/examples/rust/run.ps1"
end
