# Proxmox Email Alert Setup

Este repositorio contiene un script para configurar fácilmente alertas por correo electrónico en servidores Proxmox utilizando Gmail/G Suite.

## 📋 Características

- Configuración automatizada de Postfix para el envío de correos
- Soporte para autenticación SMTP con Gmail/G Suite
- Personalización del nombre y dirección del remitente
- Prueba de envío de correo para verificar la configuración
- Instrucciones paso a paso para la configuración completa de las alertas en Proxmox

## 🚀 Uso rápido

Para ejecutar el script directamente desde GitHub:

```bash
bash -c "$(curl -fsS https://raw.githubusercontent.com/yacosta738/proxmox-email-alert-setup/main/proxmox-email-alert-setup.sh)"
```

> ⚠️ **Importante**: Reemplaza `yacosta738` con tu nombre de usuario de GitHub después de hacer fork o clonar este repositorio.

## ⚙️ Requisitos previos

Antes de ejecutar el script, necesitarás:

1. Un servidor Proxmox VE instalado y funcionando
2. Acceso root o sudo al servidor
3. Una cuenta de Gmail/G Suite
4. Una "Contraseña de aplicación" de Google (no tu contraseña normal)
   - Para crear una, visita [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)

## 📥 Instalación manual

Si prefieres una instalación manual:

1. Clona este repositorio o descarga el script:

   ```bash
   git clone https://github.com/yacosta738/proxmox-email-alert-setup.git
   cd proxmox-email-alert-setup
   ```

2. Haz el script ejecutable:

   ```bash
   chmod +x proxmox-email-alert-setup.sh
   ```

3. Ejecuta el script con permisos de root:

   ```bash
   sudo ./proxmox-email-alert-setup.sh
   ```

## 🔍 ¿Qué hace el script?

1. **Instala dependencias necesarias**:
   - `libsasl2-modules`: Soporte para autenticación SASL
   - `mailutils`: Herramientas para enviar correos
   - `postfix-pcre`: Soporte para expresiones regulares en Postfix

2. **Configura la autenticación SMTP** para Gmail/G Suite:
   - Crea y configura el archivo de contraseñas SASL
   - Actualiza la configuración de Postfix para usar TLS

3. **Personaliza el remitente** de los correos electrónicos:
   - Permite especificar un nombre y dirección de correo personalizada

4. **Prueba la configuración** enviando un correo electrónico de prueba

5. **Proporciona instrucciones** para completar la configuración en la interfaz web de Proxmox

## 🛠️ Configuración adicional en Proxmox

Después de ejecutar el script, debes completar la configuración en la interfaz web de Proxmox:

1. **Configurar destinatario de alertas**:
   - Ve a `Datacenter` -> `Opciones` -> `Notificaciones por Correo Electrónico`
   - Configura la dirección de correo del destinatario

2. **Habilitar alertas específicas**:
   - **Backups**: En la configuración de tus trabajos de backup
   - **SMART**: En la sección de discos de tu nodo
   - **ZFS**: Se envían automáticamente si las notificaciones generales están configuradas

## 📝 Solución de problemas

Si encuentras problemas:

1. Revisa los logs de Postfix:

   ```bash
   tail -f /var/log/mail.log
   ```

2. Verifica que la "Contraseña de aplicación" de Google sea correcta

3. Asegúrate de que tu cuenta de Google no tenga restricciones que impidan el acceso de aplicaciones menos seguras

4. Si utilizas Gmail, verifica que el acceso a aplicaciones menos seguras esté habilitado (o usa una Contraseña de aplicación si tienes habilitada la autenticación de dos factores)

## ⭐ Basado en

Este script está basado en el excelente tutorial de [Techno Tim](https://technotim.live/posts/proxmox-alerts/).

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 🤝 Contribuir

Las contribuciones son bienvenidas. Si encuentras algún problema o tienes una mejora, no dudes en abrir un issue o enviar un pull request.
