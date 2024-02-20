#!/bin/bash

# Função para enviar uma mensagem ao chat do Minecraft usando rcon-cli
send_message() {
    echo "Sending message to Minecraft chat: $1"
    docker exec minecraft_server_minecraft-server_1 rcon-cli tellraw @a "{\"text\":\"$1\",\"color\":\"green\"}"
}


# Função para verificar se o servidor está em autopause
is_autopause() {
    autopause_status=$(docker exec minecraft_server_minecraft-server_1 ls -a | grep ".paused")
    if [ -z "$autopause_status" ]; then
        return 1  # O servidor está em autopause
    else
        return 0  # O servidor não está em autopause
    fi
}

# Função para verificar se o servidor está em execução
is_container_up() {
    local nome_do_container="minecraft_server_minecraft-server_1"

    if docker ps --format '{{.Names}}' | grep -q "$nome_do_container"; then
        return 0  # O contêiner está em execução
    else
        return 1  # O contêiner não está em execução
    fi
}

if is_container_up; then
    echo "O contêiner do Minecraft está em execução."
    if is_autopause; then
        echo "O servidor está em modo Auto-pause. O backup não será realizado."
    else

        send_message "Iniciando o backup... O autosave será desativado."

        # Desative o autosave no servidor Minecraft
        docker exec minecraft_server_minecraft-server_1 rcon-cli save-off

        # Força o save do mapa
        docker exec minecraft_server_minecraft-server_1 rcon-cli save-all

        # Execute o backup com tar
        tar -cpzvf "root/minecraft_server/backups/worlds_backup_$(date +"%Y-%m-%d_%H-%M-%S").tar.gz" /root/minecraft_server/data/world/ /root/minecraft_server/data/world_nether/ /root/minecraft_server/data>

        # Limpando os backups com mais de dois dias de existência
        find /root/minecraft_server/backups/ -type f -mtime +2 -delete


        send_message "Backup concluído! O autosave foi reativado."

        # Reative o autosave no servidor Minecraft
        docker exec minecraft_server_minecraft-server_1 rcon-cli save-on

        # Gerar log
        echo "Backup concluído em $(date +\%Y-\%m-\%d-\%H_\%M_\%S)" >> /root/minecraft_server/minecraft_backup.log
    fi
