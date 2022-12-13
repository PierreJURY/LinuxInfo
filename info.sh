#!/bin/bash

# Pierre JURY
# https://github.com/PierreJURY

if [[ $# -ne 0 ]]; then
	echo "Utilisation : $0" >&2
	exit 1
fi

if ! echo "$OSTYPE" | grep -iq "linux"; then
	echo "Erreur : le script doit être éxecuter sur Linux" >&2
	exit 1
fi

toiec() {
	echo "$(printf "%'d" $(( $1 / 1024 ))) Mb$([[ $1 -ge 1048576 ]] && echo " ($(numfmt --from=iec --to=iec-i "${1}K")b)")"
}

tosi() {
	echo "$(printf "%'d" $(( (($1 * 1024) / 1000) / 1000 ))) Mb$([[ $1 -ge 1000000 ]] && echo " ($(numfmt --from=iec --to=si "${1}K")b)")"
}

. /etc/os-release

echo -e "\nDistribution :\t\t\t${PRETTY_NAME:-$ID-$VERSION_ID}"

file=/sys/class/dmi/id # /sys/devices/virtual/dmi/id
if [[ -d "$file" ]]; then
	if [[ -r "$file/sys_vendor" ]]; then
		MODEL=$(<"$file/sys_vendor")
	elif [[ -r "$file/board_vendor" ]]; then
		MODEL=$(<"$file/board_vendor")
	elif [[ -r "$file/chassis_vendor" ]]; then
		MODEL=$(<"$file/chassis_vendor")
	fi
	if [[ -r "$file/product_name" ]]; then
		MODEL+=" $(<"$file/product_name")"
	fi
	if [[ -r "$file/product_version" ]]; then
		MODEL+=" $(<"$file/product_version")"
	fi
elif [[ -r /sys/firmware/devicetree/base/model ]]; then
	read -r -d '' MODEL </sys/firmware/devicetree/base/model
fi
if [[ -n "$MODEL" ]]; then
	echo -e "Modèle de l'ordinateur :\t\t\t$MODEL"
fi

HOSTNAME_FQDN=$(hostname -f)
echo -e "Nom de l'ordinateur :\t\t$HOSTNAME_FQDN"

echo -e "Nom de l'ordinateur :\t\t$HOSTNAME"

mapfile -t CPU < <(sed -n 's/^Nom du modèle[[:blank:]]*: *//p' /proc/cpuinfo | uniq)
if [[ -z "$CPU" ]]; then
	mapfile -t CPU < <(lscpu | grep -i '^Nom du modèle' | sed -n 's/^.\+:[[:blank:]]*//p' | uniq)
fi
if [[ -n "$CPU" ]]; then
	echo -e "Processeur (CPU) :\t\t${CPU[0]}$([[ ${#CPU[*]} -gt 1 ]] && printf '\n\t\t\t\t%s' "${CPU[@]:1}")"
fi

CPU_THREADS=$(nproc --all)
CPU_CORES=$(lscpu -ap | grep -v '^#' | awk -F, '{ print $2 }' | sort -nu | wc -l)
CPU_SOCKETS=$(lscpu | grep -i '^socket(s)' | sed -n 's/^.\+:[[:blank:]]*//p')
echo -e "CPU Sockets/Coeurs/Threads :\t$CPU_SOCKETS/$CPU_CORES/$CPU_THREADS"

ARCHITECTURE=$(getconf LONG_BIT)
echo -e "Architecture :\t\t\t$HOSTTYPE (${ARCHITECTURE}-bit)"²

if [[ -n "$GPU" ]]; then
	echo -e "Carte graphique :\t${GPU[0]}$([[ ${#GPU[*]} -gt 1 ]] && printf '\n\t\t\t\t%s' "${GPU[@]:1}")"
fi

MEMINFO=$(</proc/meminfo)
TOTAL_PHYSICAL_MEM=$(echo "$MEMINFO" | awk '/^MemTotal:/ {print $2}')
echo -e "RAM :\t\t\t\t$(toiec "$TOTAL_PHYSICAL_MEM") ($(tosi "$TOTAL_PHYSICAL_MEM"))"

TOTAL_SWAP=$(echo "$MEMINFO" | awk '/^SwapTotal:/ {print $2}')
echo -e "Swap :\t\t\t\t$(toiec "$TOTAL_SWAP") ($(tosi "$TOTAL_SWAP"))"

DISKS=$(lsblk -dbn 2>/dev/null | awk '$6=="disk"')
if [[ -n "$DISKS" ]]; then
	DISK_NAMES=( $(echo "$DISKS" | awk '{print $1}') )
	DISK_SIZES=( $(echo "$DISKS" | awk '{print $4}') )
	echo -e -n "Espaces disques :\t\t\t"
	for i in "${!DISK_NAMES[@]}"; do
		echo -e "$([[ $i -gt 0 ]] && echo "\t\t\t\t")${DISK_NAMES[i]}: $(printf "%'d" $(( (DISK_SIZES[i] / 1024) / 1024 ))) MiB$([[ ${DISK_SIZES[i]} -ge 1073741824 ]] && echo " ($(numfmt --to=iec-i "${DISK_SIZES[i]}")B)") ($(printf "%'d" $(( (DISK_SIZES[i] / 1000) / 1000 ))) MB$([[ ${DISK_SIZES[i]} -ge 1000000000 ]] && echo " ($(numfmt --to=si "${DISK_SIZES[i]}")B)"))"
	done
fi

for lspci in lspci /sbin/lspci; do
	if command -v $lspci >/dev/null; then
		mapfile -t GPU < <($lspci 2>/dev/null | grep -i 'vga\|3d\|2d' | sed -n 's/^.*: //p')
		break
	fi
done

mapfile -t IPv4_ADDRESS < <(ip -o -4 a show up scope global | awk '{print $2,$4}')
if [[ -n "$IPv4_ADDRESS" ]]; then
	IPv4_INERFACES=( $(printf '%s\n' "${IPv4_ADDRESS[@]}" | awk '{print $1}') )
	IPv4_ADDRESS=( $(printf '%s\n' "${IPv4_ADDRESS[@]}" | awk '{print $2}') )
	echo -e -n "Adresse$([[ ${#IPv4_ADDRESS[*]} -gt 1 ]] && echo "s") IPv4 :\t\t\t"
	for i in "${!IPv4_INERFACES[@]}"; do
		echo -e "$([[ $i -gt 0 ]] && echo "\t\t\t\t")${IPv4_INERFACES[i]}: ${IPv4_ADDRESS[i]%/*}"
	done
fi
mapfile -t IPv6_ADDRESS < <(ip -o -6 a show up scope global | awk '{print $2,$4}')
if [[ -n "$IPv6_ADDRESS" ]]; then
	IPv6_INERFACES=( $(printf '%s\n' "${IPv6_ADDRESS[@]}" | awk '{print $1}') )
	IPv6_ADDRESS=( $(printf '%s\n' "${IPv6_ADDRESS[@]}" | awk '{print $2}') )
	echo -e -n "Adresse$([[ ${#IPv6_ADDRESS[*]} -gt 1 ]] && echo "s") IPv6 :\t\t\t"
	for i in "${!IPv6_INERFACES[@]}"; do
		echo -e "$([[ $i -gt 0 ]] && echo "\t\t\t\t")${IPv6_INERFACES[i]}: ${IPv6_ADDRESS[i]%/*}"
	done
fi

INERFACES=( $(ip -o a show up primary scope global | awk '{print $2}' | uniq) )
NET_INERFACES=()
NET_ADDRESSES=()
for inerface in "${INERFACES[@]}"; do
	file="/sys/class/net/$inerface"
	if [[ -r "$file/address" ]]; then
		NET_INERFACES+=( "$inerface" )
		NET_ADDRESSES+=( "$(<"$file/address")" )
	fi
done
if [[ -n "$NET_INERFACES" ]]; then
	echo -e -n "Adresse$([[ ${#NET_INERFACES[*]} -gt 1 ]] && echo "s") MAC :\t\t\t"
	for i in "${!NET_INERFACES[@]}"; do
		echo -e "$([[ $i -gt 0 ]] && echo "\t\t\t\t")${NET_INERFACES[i]}: ${NET_ADDRESSES[i]}"
	done
fi

echo
