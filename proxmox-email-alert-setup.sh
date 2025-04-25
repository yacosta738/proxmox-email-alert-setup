#!/bin/bash

# Script para configurar alertas de correo electrónico en Proxmox usando Gmail/G Suite
# Basado en el tutorial de Techno Tim: https://technotim.live/posts/proxmox-alerts/
# IMPORTANTE: Ejecuta este script con sudo o como root.

# --- Comprobación de privilegios ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ejecutarse como root o con sudo." >&2
  exit 1
fi

# --- Salir en caso de error ---
set -e

# --- Variables (puedes modificarlas si lo deseas) ---
POSTFIX_MAIN_CONF="/etc/postfix/main.cf"
POSTFIX_SASL_PASSWD="/etc/postfix/sasl_passwd"
POSTFIX_HEADER_CHECKS="/etc/postfix/smtp_header_checks"
GMAIL_SMTP_SERVER="smtp.gmail.com"
GMAIL_SMTP_PORT="587"

# --- Inicio de la Configuración ---
echo "--- Iniciando la configuración de alertas de correo electrónico para Proxmox ---"

# --- 1. Instalar dependencias ---
echo "--- Paso 1: Actualizando lista de paquetes e instalando dependencias (libsasl2-modules, mailutils, postfix-pcre) ---"
apt update
apt install -y libsasl2-modules mailutils postfix-pcre
echo "--- Dependencias instaladas correctamente ---"
echo

# --- 2. Configurar contraseña de aplicación de Google ---
echo "--- Paso 2: Configuración de la cuenta de Google ---"
echo "Necesitarás una 'Contraseña de aplicación' de tu cuenta de Google."
echo "Si no tienes una, créala aquí: https://myaccount.google.com/apppasswords"
read -p "Introduce tu dirección de correo electrónico de Gmail/G Suite: " GMAIL_USER
read -sp "Introduce tu Contraseña de Aplicación de Google: " GMAIL_APP_PASSWORD
echo # Nueva línea después de la entrada de contraseña
echo

# --- 3. Configurar Postfix ---
echo "--- Paso 3: Configurando Postfix ---"

# Crear/actualizar archivo de contraseñas SASL
echo "Creando el archivo de contraseñas SASL..."
echo "[${GMAIL_SMTP_SERVER}]:${GMAIL_SMTP_PORT} ${GMAIL_USER}:${GMAIL_APP_PASSWORD}" > "${POSTFIX_SASL_PASSWD}"

# Establecer permisos correctos
echo "Estableciendo permisos para ${POSTFIX_SASL_PASSWD}..."
chmod 600 "${POSTFIX_SASL_PASSWD}"

# Hashear el archivo de contraseñas
echo "Hasheando el archivo de contraseñas SASL..."
postmap hash:"${POSTFIX_SASL_PASSWD}"

# Comprobar si se creó el archivo .db (opcional, informativo)
if [ -f "${POSTFIX_SASL_PASSWD}.db" ]; then
    echo "Archivo ${POSTFIX_SASL_PASSWD}.db creado correctamente."
else
    echo "¡ADVERTENCIA! No se pudo encontrar ${POSTFIX_SASL_PASSWD}.db." >&2
fi

# Hacer copia de seguridad y actualizar main.cf
echo "Haciendo copia de seguridad de ${POSTFIX_MAIN_CONF} a ${POSTFIX_MAIN_CONF}.bak..."
cp "${POSTFIX_MAIN_CONF}" "${POSTFIX_MAIN_CONF}.bak"

echo "Añadiendo configuración de Gmail a ${POSTFIX_MAIN_CONF}..."
# Eliminar configuraciones antiguas si existen para evitar duplicados (opcional pero recomendado)
sed -i '/^# google mail configuration/,+9 d' "${POSTFIX_MAIN_CONF}"
sed -i '/^smtp_header_checks = .*/d' "${POSTFIX_MAIN_CONF}"
# Eliminar la línea existente de relayhost para evitar conflictos
sed -i '/^relayhost = /d' "${POSTFIX_MAIN_CONF}"

# Añadir nueva configuración
cat << EOF >> "${POSTFIX_MAIN_CONF}"

# google mail configuration - añadido por script
relayhost = [${GMAIL_SMTP_SERVER}]:${GMAIL_SMTP_PORT}
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:${POSTFIX_SASL_PASSWD}
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
# Las siguientes líneas pueden variar o no ser necesarias en todas las configuraciones, pero se incluyen según el tutorial
# smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache
# smtp_tls_session_cache_timeout = 3600s
EOF

echo "Configuración de relayhost añadida."
echo

# --- 4. Personalizar el nombre del remitente ---
echo "--- Paso 4: Personalizando el nombre del remitente del correo ---"
read -p "Introduce el nombre del remitente deseado (ej: Servidor Proxmox PVE1): " FROM_NAME
read -p "Introduce la dirección de correo electrónico del remitente deseado (puede ser la misma de Gmail o una diferente, ej: pve1-alert@tu_dominio.com): " FROM_EMAIL

# Crear/actualizar archivo smtp_header_checks
echo "Creando ${POSTFIX_HEADER_CHECKS}..."
echo "/^From:.*/ REPLACE From: ${FROM_NAME} <${FROM_EMAIL}>" > "${POSTFIX_HEADER_CHECKS}"

# Hashear el archivo
echo "Hasheando ${POSTFIX_HEADER_CHECKS}..."
postmap hash:"${POSTFIX_HEADER_CHECKS}"

# Comprobar si se creó el archivo .db (opcional, informativo)
if [ -f "${POSTFIX_HEADER_CHECKS}.db" ]; then
    echo "Archivo ${POSTFIX_HEADER_CHECKS}.db creado correctamente."
else
    echo "¡ADVERTENCIA! No se pudo encontrar ${POSTFIX_HEADER_CHECKS}.db." >&2
fi

# Añadir la configuración a main.cf
echo "Añadiendo la configuración de smtp_header_checks a ${POSTFIX_MAIN_CONF}..."
echo "smtp_header_checks = pcre:${POSTFIX_HEADER_CHECKS}" >> "${POSTFIX_MAIN_CONF}"
echo "Configuración de personalización del remitente añadida."
echo

# --- 5. Recargar Postfix ---
echo "--- Paso 5: Recargando el servicio Postfix ---"
systemctl reload postfix
echo "Postfix recargado."
echo

# --- 6. Enviar correo de prueba ---
echo "--- Paso 6: Prueba de envío de correo ---"
read -p "¿Deseas enviar un correo de prueba a ${GMAIL_USER}? (s/N): " SEND_TEST_EMAIL
if [[ "$SEND_TEST_EMAIL" =~ ^[Ss]$ ]]; then
    echo "Enviando correo de prueba a ${GMAIL_USER}..."
    if echo "Este es un mensaje de prueba enviado desde Postfix en tu servidor Proxmox (${HOSTNAME})" | mail -s "Correo de Prueba desde Proxmox (${HOSTNAME})" "${GMAIL_USER}"; then
        echo "Correo de prueba enviado. Revisa tu bandeja de entrada (y la carpeta de spam)."
    else
        echo "¡Error al enviar el correo de prueba! Revisa la configuración y los logs de Postfix (/var/log/mail.log)." >&2
    fi
else
    echo "Omitiendo envío de correo de prueba."
fi
echo

# --- 7. Pasos Finales (Manuales) ---
echo "--- ¡Configuración básica completada! ---"
echo
echo "--- Pasos Finales Importantes (Manuales en la GUI de Proxmox): ---"
echo "1.  **Configurar Destinatario de Notificaciones:**"
echo "    Ve a 'Datacenter' -> 'Opciones' -> 'Notificaciones por Correo Electrónico'."
echo "    Establece la 'Dirección de correo electrónico del destinatario' a donde quieres que lleguen las alertas."
echo "    Puedes necesitar configurar también 'Dirección de correo electrónico del remitente' aquí si no personalizaste el remitente antes o si Proxmox lo requiere."
echo
echo "2.  **Habilitar Alertas Específicas:**"
echo "    * **Alertas de Backup:** En la configuración de tus trabajos de backup ('Datacenter' -> 'Backup'), asegúrate de que la opción 'Enviar correo electrónico a' esté configurada con la dirección deseada y selecciona cuándo enviar correos (ej: 'Siempre' o 'En caso de fallo')."
echo "    * **Alertas SMART:** Ve a 'Tu Nodo' -> 'Discos' -> 'SMART'. Habilita el monitoreo SMART para tus discos si aún no lo has hecho. Las alertas deberían usar la configuración global de notificaciones."
echo "    * **Alertas ZFS:** Si usas ZFS, Proxmox monitoriza el estado del pool. Asegúrate de que las notificaciones generales estén configuradas como se indicó en el paso 1. Puedes probar forzando un error (¡CON PRECAUCIÓN!) como se muestra en el video tutorial."
echo
echo "Recuerda revisar los logs de Postfix (/var/log/mail.log) si encuentras problemas."
echo "--- Script finalizado ---"

exit 0