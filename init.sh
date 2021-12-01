# Initialization file that partitions and mounts a disk.
# It then places a file in the partition and launches an Apache web server.

# Disk partition and mounting
sudo parted /dev/sdc --script mklabel gpt mkpart xfspart xfs 0% 100%
sudo mkfs.xfs /dev/sdc1
sudo partprobe /dev/sdc1
sudo mkdir /mnt/sdc
sudo mount /dev/sdc1 /mnt/sdc/

# Ensures the disk will mount on reboot
p1="#!"
p2="/bin/sh\nsudo mount /dev/sdc1 /mnt/sdc/"
printf "$p1$p2\n" | sudo tee /etc/init.d/mountsdc.sh
sudo chmod +x /etc/init.d/mountsdc.sh
sudo update-rc.d mountsdc.sh defaults

# Apache server
sudo apt install apache2 -y && sudo systemctl start apache2
echo "<h1><center>Hello GR World</center></h1>" | sudo tee -a /mnt/sdc/index.html
sudo chmod 755 /mnt/sdc/index.html
sudo rm /var/www/html/index.html
sudo ln -s /mnt/sdc/index.html /var/www/html/index.html