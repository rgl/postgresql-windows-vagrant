Vagrant.configure("2") do |config|
  config.vm.box = "windows-2016-amd64"
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = 2048
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
  end
  config.vm.hostname = 'pgsql'
  config.vm.network :private_network, ip: '10.10.10.101'
  config.vm.provision "shell", inline: "'10.10.10.101 pgsql.example.com' | Out-File -Encoding Ascii -Append c:/Windows/System32/drivers/etc/hosts"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-chocolatey.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-base.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-certificates.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-postgresql.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "provision-dbeaver.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/python/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/java/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/csharp/run.ps1"
  config.vm.provision "shell", path: "ps.ps1", args: "examples/go/run.ps1"
end
