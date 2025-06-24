# 国内VPS (Domestic VPS) 部署指南

## 角色与目标

国内VPS在此架构中扮演一个**专用的、安全的上游DNS解析器**。它的核心任务是：

-   **高效解析国内域名**：通过接入如AliDNS、DNSPod等国内高速DNS服务，为国内域名提供最准确、最低延迟的解析结果。
-   **提供安全的DoH服务**：将解析服务通过DoH（DNS-over-HTTPS）协议暴露出来，仅供我们的海外VPS调用。
-   **访问隔离**：此服务器不直接对公网用户提供服务，通过IP白名单等安全措施，确保其解析能力不被滥用。

## 部署步骤

1.  **准备环境**:
    *   一台位于中国大陆的VPS。
    *   一个域名，并将其A记录指向此VPS的IP地址。
    *   安装好 `docker` 和 `docker-compose`。

2.  **获取SSL证书**:
    *   使用 `acme.sh` 或 `certbot` 为您的域名申请SSL证书。
    *   将获取到的证书文件 (`fullchain.cer` 或 `fullchain.pem`) 和私钥文件 (`private.key` 或 `privkey.pem`) 放入本目录下的 `openresty/ssl/` 文件夹中。

3.  **配置环境变量**:
    *   (此项目暂无特定环境变量，所有配置均在文件中完成)。

4.  **修改配置**:
    *   **OpenResty**: 打开 `openresty/conf.d/default.conf`，将 `server_name` 修改为您的域名，并确认SSL证书文件名正确。**重要**：在 `location /dns-query` 块中，将 `allow` 后面的IP地址修改为您**海外VPS**的公网IP，并保留 `deny all;`，以实现访问控制。
    *   **AdGuardHome**: 首次启动后，访问 `http://<您的国内VPS_IP>:3000` 进行初始化设置。在"上游DNS服务器"处填写 `172.16.233.2` (即SmartDNS在内部Docker网络中的地址)，并根据向导完成后续配置。
    *   **SmartDNS**: `smartdns/smartdns.conf` 已配置好国内常用上游，通常无需修改。

5.  **启动服务**:
    *   在本目录下 (`domestic-vps/`) 执行命令：
        ```bash
        docker-compose up -d
        ```

6.  **验证**:
    *   在您的**海外VPS**上，执行 `curl -v https://<您的国内DoH域名>/dns-query`。如果配置正确，应能看到来自OpenResty的响应。
    *   检查各容器日志确保无异常：`docker-compose logs -f`。 