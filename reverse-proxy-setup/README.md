# Home Assistant Reverse Proxy Setup on Synology NAS

This documentation describes how to set up a **Reverse Proxy** on a **Synology NAS** to allow external access to **Home Assistant** via HTTPS, ensuring a secure connection. The steps include configuring the reverse proxy, setting up a Let's Encrypt wildcard certificate, and configuring Home Assistant to trust the reverse proxy.

## Prerequisites

- **Synology NAS** running DSM (DiskStation Manager).
- **Home Assistant** running in a VM on the NAS.
- Access to your router for port forwarding.
- A registered domain or a **Synology DDNS** domain (e.g., `user.synology.me`).

## Project Overview

We configured a reverse proxy to allow secure external access to **Home Assistant**. The steps include:

1. Setting up a reverse proxy on the **Synology NAS**.
2. Requesting and configuring a **Let's Encrypt Wildcard Certificate**.
3. Configuring **Home Assistant** to trust the reverse proxy.
4. Troubleshooting common issues (like the 400 Bad Request error).

---

## 1. Configure Reverse Proxy on Synology DSM

1. Log in to your Synology NAS and open the **Control Panel**.
2. Go to **Application Portal** → **Reverse Proxy**.
3. Create a new reverse proxy rule:
   - **Reverse Proxy Name**: `Home Assistant`
   - **Source**:
     - **Protocol**: HTTPS
     - **Hostname**: `homeassistant.your-domain.com` (or `homeassistant.your-synology-ddns.me`)
     - **Port**: 443
   - **Destination**:
     - **Protocol**: HTTP
     - **Hostname**: IP of Home Assistant VM (e.g., `192.168.178.33`)
     - **Port**: 8123 (Home Assistant default port)
4. In the **Custom Headers** section, set the following headers:
   - **Host**: `homeassistant.your-domain.com`

This will route external requests to your Home Assistant VM.

---

## 2. Set Up a Let's Encrypt Wildcard Certificate

1. In DSM, go to **Control Panel** → **Security** → **Certificates**.
2. Click on **Add** → **Get a certificate from Let's Encrypt**.
3. Enter your domain name (e.g., `*.your-domain.com`) to request a **Wildcard Certificate**.
   - If using Synology DDNS, the domain might be `*.synology.me`.
4. Ensure that port **80** is forwarded to the NAS for the verification process.
5. After successful issuance, assign the certificate to the **Reverse Proxy** service:
   - Go to **Control Panel** → **Security** → **Certificates**.
   - Click on **Action** → **Assign** and assign the certificate to the Home Assistant reverse proxy.

---

## 3. Configure Home Assistant to Trust the Reverse Proxy

To ensure that Home Assistant accepts requests from the reverse proxy, update the **`configuration.yaml`** file in Home Assistant to include trusted proxy settings.

1. In Home Assistant, open the **`configuration.yaml`** file.
2. Add the following configuration under the **`http:`** section:

   ```yaml
   http:
     use_x_forwarded_for: true
     trusted_proxies:
       - 192.168.178.32  # IP of Synology NAS
       - 192.168.178.33  # IP of Home Assistant VM
       - "IPv6 address of NAS"  # Add if your network uses IPv6
   ```

3. Save the file and **restart Home Assistant** to apply the changes.

---

## 4. Troubleshooting Common Issues

### Issue: "400 Bad Request" Error
If you encounter a **400 Bad Request** error when accessing Home Assistant via the domain, it's likely due to missing **trusted proxies** in the Home Assistant configuration.

#### Solution:
- Ensure that the **IP address of the NAS** and the **Home Assistant VM** are correctly listed in the `trusted_proxies` section of the `configuration.yaml`.
- If your NAS uses **IPv6**, ensure that the **IPv6 address** is added (without the subnet `/64`).

### Issue: Let's Encrypt Certificate Not Issuing
If Let's Encrypt cannot issue a certificate, ensure that:
- **Port 80** is forwarded on your router to the NAS.
- The domain correctly resolves to the NAS's public IP address.

---

## Conclusion

By setting up a reverse proxy with a **Let's Encrypt Wildcard Certificate**, you can securely access **Home Assistant** from anywhere using a custom domain and HTTPS. This setup enhances security and enables external access for automations based on geolocation or other external triggers.

---

## Useful Links

- [Home Assistant Documentation](https://www.home-assistant.io/docs/)
- [Synology Reverse Proxy Guide](https://kb.synology.com/en-global/DSM/tutorial/How_to_set_up_Reverse_Proxy_on_Synology_NAS)
- [Let's Encrypt](https://letsencrypt.org/)
