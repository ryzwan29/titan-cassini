#!/bin/bash 

clear
echo -e "\033[1;32m
██████╗ ██╗   ██╗██████╗ ██████╗ ██████╗ ██████╗  █████╗ 
██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗╚════██╗██╔══██╗
██████╔╝ ╚████╔╝ ██║  ██║██║  ██║██║  ██║ █████╔╝╚██████║
██╔══██╗  ╚██╔╝  ██║  ██║██║  ██║██║  ██║██╔═══╝  ╚═══██║
██║  ██║   ██║   ██████╔╝██████╔╝██████╔╝███████╗ █████╔╝
╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝ ╚════╝ 
\033[0m"
echo -e "\033[1;34m==================================================\033[1;34m"
echo -e "\033[1;34m@Ryddd29 | Testnet, Node Runer, Developer, Retrodrop\033[1;34m"

sleep 4

# Prompt untuk menanyakan apakah pengguna ingin menginstal Docker
read -p $'\033[1;32m\033[1mApakah Anda ingin menginstal Docker? (y/n) [default: y]: \033[0m' USER_INPUT

# Default ke "y" jika tidak ada input yang diberikan
USER_INPUT=${USER_INPUT:-y}

if [[ "$USER_INPUT" =~ ^[Yy]$ ]]; then
  echo -e "\033[1;32m\033[1mMenginstal Docker...\033[0m"

  # Instal Docker
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose docker-compose-plugin

  echo -e "\033[1;32m\033[1mInstalasi Docker selesai dengan sukses!\033[0m"
else
  echo -e "\033[0;33mInstalasi Docker dilewati oleh pengguna.\033[0m"
fi

read -p "Masukkan kode identitas anda: " id

# Biarkan pengguna memasukkan jumlah container yang ingin dibuat 
read -p "Silakan masukkan jumlah node yang ingin dibuat. Satu IP dibatasi maksimal 5 node: " container_count

# Biarkan pengguna memasukkan batas ukuran hard disk setiap node (dalam GB) 
read -p "Silakan masukkan batas ukuran hard disk setiap node (dalam GB, misalnya: 1 mewakili 1GB, 2 mewakili 2GB) : " disk_size_gb 

# Tanyakan direktori penyimpanan volume data pengguna, dan tetapkan nilai default 
read -p "Silahkan masukkan direktori penyimpanan volume data [default: /mnt/docker_volumes]: " volume_dir
volume_dir=${volume_dir:-/mnt/docker_volumes}

apt update

# Periksa apakah Docker telah diinstal Instal 
if ! command -v docker &> /dev/null
then
    echo "Docker tidak terdeteksi, sedang menginstal. .."
    apt-get install ca-certificates curl gnupg lsb-release
    
    # Instal versi terbaru Docker 
    apt-get install docker.io -y
else
    echo "Docker telah diinstal."
fi

# Tarik gambar Docker 
docker pull nezha123/titan-edge

# Buat direktori penyimpanan file gambar 
mkdir -p $volume_dir

# Buat jumlah container yang ditentukan pengguna 
for i in $(seq 1 $container_count)
do
    disk_size_mb=$((disk_size_gb * 1024))
    
    # Buat sistem file gambar dengan ukuran tertentu untuk setiap kontainer 
    volume_path="$volume_dir/volume_$i.img"
    sudo dd if=/dev/zero of=$volume_path bs=1M count=$disk_size_mb
    sudo mkfs.ext4 $volume_path

    # Buat direktori dan pasang sistem berkas 
    mount_point="/mnt/my_volume_$i"
    mkdir -p $mount_point
    sudo mount -o loop $volume_path $mount_point

    # Akan dipasang Tambahkan informasi ke /etc/fstab 
    echo "$volume_path $mount_point ext4 loop,defaults 0 0" | sudo tee -a /etc/fstab

    # Jalankan container dan setel kebijakan mulai ulang ke selalu 
    container_id=$(docker run -d --restart always -v $mount_point:/root/.titanedge/storage --name "titan$i" nezha123/titan-edge)

    echo "node titan$i telah memulai ID containe $container_id"

    sleep 30
    
    # Masuk ke container dan lakukan pengikatan dan perintah lainnya 
    docker exec -it $container_id bash -c "\
        titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding"
done

echo "==============================Semua node sudah diatur dan dimulai===================================."
