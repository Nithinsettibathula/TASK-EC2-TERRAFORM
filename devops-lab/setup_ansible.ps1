# setup_ansible.ps1

# 1. Set the Server IP (I put your specific IP here automatically)
$ServerIP = "56.228.18.35"

# 2. Create Directory Structure
$dirs = @(
    "ansible",
    "ansible/roles/common/tasks",
    "ansible/roles/stack/tasks",
    "ansible/roles/stack/templates"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# 3. Create Inventory File
$inventoryContent = @"
[web]
$ServerIP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/devops-key.pem
"@
Set-Content -Path "ansible/inventory.ini" -Value $inventoryContent

# 4. Create Ansible Config
$cfgContent = @"
[defaults]
host_key_checking = False
remote_user = ubuntu
private_key_file = ~/.ssh/devops-key.pem
inventory = inventory.ini
"@
Set-Content -Path "ansible/ansible.cfg" -Value $cfgContent

# 5. Create Master Playbook (site.yml)
$siteContent = @"
---
- name: Configure DevOps Lab Server
  hosts: web
  become: true
  roles:
    - common
    - stack
"@
Set-Content -Path "ansible/site.yml" -Value $siteContent

# 6. Create Role: Common (Docker Setup)
$commonTaskContent = @"
---
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600

- name: Install required packages
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
      - python3-pip
    state: present

- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add Docker Repository
  apt_repository:
    repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable
    state: present

- name: Install Docker CE
  apt:
    name: docker-ce
    state: present

- name: Install Docker SDK for Python
  pip:
    name: docker

- name: Ensure Docker is running
  service:
    name: docker
    state: started
    enabled: yes

- name: Initialize Docker Swarm
  docker_swarm:
    state: present
"@
Set-Content -Path "ansible/roles/common/tasks/main.yml" -Value $commonTaskContent

# 7. Create Role: Stack (Tasks)
$stackTaskContent = @"
---
- name: Create project directory
  file:
    path: /opt/devops-lab
    state: directory

- name: Copy SQL Seed Data
  copy:
    src: init.sql
    dest: /opt/devops-lab/init.sql

- name: Copy Prometheus Config
  template:
    src: prometheus.yml.j2
    dest: /opt/devops-lab/prometheus.yml

- name: Copy Docker Compose File
  template:
    src: docker-compose.yml.j2
    dest: /opt/devops-lab/docker-compose.yml

- name: Deploy the Stack
  docker_stack:
    state: present
    name: prod
    compose:
      - /opt/devops-lab/docker-compose.yml
"@
Set-Content -Path "ansible/roles/stack/tasks/main.yml" -Value $stackTaskContent

# 8. Create Template: SQL Seed
$sqlContent = @"
CREATE TABLE IF NOT EXISTS interns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL
);
INSERT INTO interns (name, status) VALUES ('Nithin', 'Hired');
INSERT INTO interns (name, status) VALUES ('DevOps Bot', 'Active');
"@
Set-Content -Path "ansible/roles/stack/templates/init.sql" -Value $sqlContent

# 9. Create Template: Prometheus Config
$promContent = @"
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'mysql_exporter'
    static_configs:
      - targets: ['mysql-exporter:9104']
"@
Set-Content -Path "ansible/roles/stack/templates/prometheus.yml.j2" -Value $promContent

# 10. Create Template: Docker Compose
$composeContent = @"
version: '3.8'

services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    deploy:
      replicas: 1

  mysql:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: devops_db
    volumes:
      - mysql_data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

  postgres:
    image: postgres:13
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: password
    volumes:
      - pg_data:/var/lib/postgresql/data

  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

  node-exporter:
    image: prom/node-exporter
    deploy:
      mode: global

  mysql-exporter:
    image: prom/mysqld-exporter
    environment:
      DATA_SOURCE_NAME: "root:rootpassword@(mysql:3306)/"
    depends_on:
      - mysql

volumes:
  mysql_data:
  pg_data:
"@
Set-Content -Path "ansible/roles/stack/templates/docker-compose.yml.j2" -Value $composeContent

Write-Host "SUCCESS! All Ansible files have been created." -ForegroundColor Green