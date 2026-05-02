Vagrant.configure("2") do |config|
  config.vm.box = "net9/ubuntu-24.04-arm64"
  config.vm.box_version = "1.1"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end

  # 1. THE MASTER NODE (Control Plane)
  config.vm.define "master" do |master|
    master.vm.hostname = "master-node"
    master.vm.network "private_network", ip: "192.168.56.10"
    
    master.vm.provision "shell", inline: <<-SHELL
      echo "Installing K3s Master..."
      # Install K3s server.
      IFACE=$(ip -4 addr show | grep 192.168.56.10 | awk '{print $NF}') 
      # We disable Traefik because instructions require an API Gateway (api-gateway-app).
      curl -sfL https://get.k3s.io | sh -s - server --node-ip=192.168.56.10 --flannel-iface=$IFACE --disable traefik
      # K3s generates a secure token that agents need to join the cluster.
      # We copy this token to the shared /vagrant folder so the Agent VM can read it.
      cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token
      # We copy the kubeconfig file so you can control the cluster from your Mac/Host machine.
      cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
      sed -i 's/127.0.0.1/192.168.56.10/g' /vagrant/k3s.yaml
      
      echo "Master Node is Ready."
    SHELL
  end

  # 2. THE AGENT NODE (Worker)
  config.vm.define "agent1" do |agent|
    agent.vm.hostname = "agent1-node"
    agent.vm.network "private_network", ip: "192.168.56.11"
    # We must wait for the Master to finish booting and generate the token
    # before the Agent tries to join. Vagrant boots VMs in order.
    agent.vm.provision "shell", inline: <<-SHELL
      echo "Installing K3s Agent and joining the cluster..."
      # Read the token the Master saved to the shared folder
      TOKEN=$(cat /vagrant/node-token)
      IFACE=$(ip -4 addr show | grep 192.168.56.11 | awk '{print $NF}')
      # Install K3s agent and point it to the Master's IP
      curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.10:6443 K3S_TOKEN=$TOKEN sh -s - --node-ip=192.168.56.11 --flannel-iface=$IFACE
      
      echo "Agent Node has joined the cluster."
    SHELL
  end
end