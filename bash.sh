#!/bin/bash

# Функция для обновления репозиториев
update_repos() {
    if command -v apt-get &> /dev/null; then
        echo "Используется пакетный менеджер APT (Debian/Ubuntu). Обновляем репозитории..."
        sudo apt-get update
        echo "Устанавливаем Python 3.12 и venv..."
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository ppa:deadsnakes/ppa -y
        sudo apt-get update
        sudo apt-get install -y python3.12 python3.12-venv

    elif command -v yum &> /dev/null; then
        echo "Используется пакетный менеджер YUM (CentOS/RHEL). Обновляем репозитории..."
        sudo yum makecache fast
        echo "Устанавливаем Python 3.12 и venv..."
        sudo yum install -y gcc openssl-devel bzip2-devel libffi-devel
        cd /usr/src
        sudo wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz
        sudo tar xzf Python-3.12.0.tgz
        cd Python-3.12.0
        sudo ./configure --enable-optimizations
        sudo make altinstall

    elif command -v dnf &> /dev/null; then
        echo "Используется пакетный менеджер DNF (Fedora). Обновляем репозитории..."
        sudo dnf makecache
        echo "Устанавливаем Python 3.12 и venv..."
        sudo dnf install -y gcc openssl-devel bzip2-devel libffi-devel
        cd /usr/src
        sudo wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz
        sudo tar xzf Python-3.12.0.tgz
        cd Python-3.12.0
        sudo ./configure --enable-optimizations
        sudo make altinstall

    elif command -v zypper &> /dev/null; then
        echo "Используется пакетный менеджер Zypper (OpenSUSE). Обновляем репозитории..."
        sudo zypper refresh
        echo "Устанавливаем Python 3.12 и venv..."
        sudo zypper install -y python3

    elif command -v pacman &> /dev/null; then
        echo "Используется пакетный менеджер Pacman (Arch Linux). Обновляем репозитории..."
        sudo pacman -Sy
        echo "Устанавливаем Python 3.12 и venv..."
        sudo pacman -S --noconfirm python

    elif command -v apk &> /dev/null; then
        echo "Используется пакетный менеджер APK (Alpine Linux). Обновляем репозитории..."
        sudo apk update
        echo "Устанавливаем Python 3.12 и venv..."
        sudo apk add --no-cache python3

    elif command -v emerge &> /dev/null; then
        echo "Используется пакетный менеджер Portage (Gentoo). Обновляем репозитории..."
        sudo emerge --sync
        echo "Устанавливаем Python 3.12 и venv..."
        sudo emerge dev-lang/python:3.12

    else
        echo "Пакетный менеджер не найден. Обновление репозиториев и установка Python невозможны."
        exit 1
    fi
}

# Вызываем функцию обновления и установки
update_repos
mkdir ~/octodns ~/octodns/config
cd octodns
python3 -m venv octo_venv
source ./octo_venv/bin/activate
pip install octodns octodns_selectel octodns_edgecenter
deactivate
read -p "Введите keystone-токен Selectel: " selectel_token
read -p "Введите токен EdgeCenter: " ec_token
cat > ./config/config.yaml <<EOL
processors:
    no-root-ns:
        class: octodns.processor.filter.IgnoreRootNsFilter
providers:
    selectel:
        class: octodns_selectel.SelectelProvider
        token: $selectel_token
    ec:
        class: octodns_edgecenter.EdgeCenterProvider
        token: $ec_token
        token_type: APIKey
zones:
    '*':
        sources:
            - selectel
        processors:
            - no-root-ns
        targets:
            - ec
EOL
current_dir=$(pwd)
path_to_venv="$current_dir/octo_venv/bin/activate"
path_to_conf="$current_dir/config/config.yaml"
cat > auto_update.sh <<EOL
#!/bin/bash 
# Активируем виртуальное окружение Python
source $path_to_venv
# Выполняем octodns-sync
octodns-sync --config-file=$path_to_conf --doit
EOL
chmod +x auto_update.sh
./auto_update.sh
