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
    *   确保您的终端拥有 `bash` 环境 (例如 Git Bash on Windows, or native shell on Linux)。

2.  **生成自签名证书 (首次部署需要)**:
    *   为了屏蔽所有未绑定域名的访问，需要一个默认的自签名证书。请在项目根目录执行：
        ```bash
        chmod +x ./scripts/generate-self-signed-cert.sh
        ./scripts/generate-self-signed-cert.sh
        ```

3.  **配置域名**:
    *   在本目录下 (`domestic-vps/`)，执行域名修改脚本，将配置文件中的占位符替换为您的域名：
        ```bash
        chmod +x rename-domain.sh
        ./rename-domain.sh your-cn-domain.com
        ```
    *   请将 `your-cn-domain.com` 替换为您自己的域名。

4.  **申请SSL证书**:
    *   执行证书申请脚本。此脚本会自动处理证书的申请、安装和续期配置。
        ```bash
        chmod +x issue-cert.sh
        ./issue-cert.sh your-cn-domain.com
        ```
    *   **重要**: 此脚本会先停止正在运行的服务（如果有），以使用standalone模式申请证书，请确保在执行此操作前没有重要任务正在运行。

5.  **启动服务**:
    *   证书申请成功后，执行以下命令启动所有服务：
        ```bash
        docker-compose up -d
        ```
    *   请确保您的VPS防火墙已放行 `80` 和 `443` 端口。OpenResty服务现在将使用刚刚申请到的证书。

6.  **配置AdGuardHome**:
    *   首次启动后，访问 `http://<您的国内VPS_IP>:3000` 进行初始化设置。
    *   在"上游DNS服务器"处填写 `172.16.232.2` (即SmartDNS在内部Docker网络中的地址)。
    *   在"DNS服务器"处，AdGuardHome会监听 `172.16.232.4`，这是正确的。
    *   完成向导。

7.  **验证**:
    *   在您的**海外VPS**上，执行 `curl -v https://<您的国内DoH域名>/dns-query`。如果配置正确，应能看到来自OpenResty的响应和有效的SSL证书信息。
    *   检查各容器日志确保无异常：`docker-compose logs -f`。 