# 海外VPS (Overseas VPS) 部署指南

## 角色与目标

海外VPS是整个DNS架构的**主入口和智能分流中枢**。最终用户唯一需要配置的就是本服务器提供的DoH服务地址。其核心任务是：

-   **提供统一DoH入口**：通过 `OpenResty` + `AdGuardHome` 提供对外的、具备广告过滤能力的DoH/DoT服务。
-   **智能域名分流**：通过 `MosDNS`，根据聚合的域名规则列表，精确地将DNS查询请求分发到最合适的上游。
    -   **国内域名**：转发至我们部署的**国内VPS DoH服务**进行解析。
    -   **其他域名**：转发至本地 `SmartDNS` 进行解析。
-   **解析境外域名**：通过 `SmartDNS` 连接Google、Cloudflare等权威DNS，处理非国内域名的解析请求。
-   **自动化规则更新**：利用GitHub Action自动更新`MosDNS`所使用的规则列表。

## 部署步骤

1.  **准备环境**:
    *   一台位于中国大陆以外的VPS。
    *   一个域名，并将其A记录指向此VPS的IP地址。
    *   安装好 `docker` 和 `docker-compose`。
    *   确保您的**国内VPS**已按其`README.md`部署完毕，并正常运行。
    *   确保您的终端拥有 `bash` 环境。

2.  **生成自签名证书 (首次部署需要)**:
    *   为了屏蔽所有未绑定域名的访问，需要一个默认的自签名证书。如果您在配置国内VPS时已经执行过此脚本，可以跳过此步。在项目根目录执行：
        ```bash
        chmod +x ./scripts/generate-self-signed-cert.sh
        ./scripts/generate-self-signed-cert.sh
        ```

3.  **配置域名**:
    *   在本目录下 (`overseas-vps/`)，执行域名修改脚本：
        ```bash
        chmod +x rename-domain.sh
        ./rename-domain.sh your-overseas-domain.com your-cn-doh-domain.com
        ```
    *   请将 `your-overseas-domain.com` 替换为您自己的**海外**域名。
    *   请将 `your-cn-doh-domain.com` 替换为您**国内VPS**的DoH域名。

4.  **申请SSL证书**:
    *   为您的海外域名执行证书申请脚本：
        ```bash
        chmod +x issue-cert.sh
        ./issue-cert.sh your-overseas-domain.com
        ```
    *   **重要**: 此脚本同样会先停止正在运行的服务来完成证书申请。

5.  **启动服务**:
    *   证书申请成功后，启动所有服务：
        ```bash
        docker-compose up -d
        ```
    *   请确保您的VPS防火墙已放行 `80` 和 `443` 端口。

6.  **证书续期**:
    *   Let's Encrypt 证书有效期为90天，您需要在此之前进行续期。
    *   执行续期脚本即可，此过程不会停止您的服务：
        ```bash
        chmod +x renew-cert.sh
        ./renew-cert.sh your-overseas-domain.com
        ```
    *   建议您设置一个 Cron Job 来自动执行此命令。例如，执行 `crontab -e` 添加以下行，即可每天凌晨3点检查续期：
        ```cron
        0 3 * * * cd /path/to/netdns/overseas-vps && /bin/bash ./renew-cert.sh your-overseas-domain.com >> /path/to/netdns/cert-renewal.log 2>&1
        ```
        **注意**: 请务必将 `/path/to/netdns/` 替换为您项目存放的绝对路径。

7.  **配置AdGuardHome**:
    *   首次启动后，访问 `http://<您的海外VPS_IP>:3001` 进行初始化设置。
    *   在"上游DNS服务器"处填写 `172.16.233.3` (即MosDNS在内部Docker网络中的地址)。
    *   完成向导。

8.  **终端用户配置**:
    *   所有配置完成后，您需要提供给最终用户的DoH地址为：`https://<您的海外域名>/dns-query`。
    *   将此地址配置到路由器、浏览器或操作系统中，即可开始使用。

9.  **验证**:
    *   执行 `nslookup qq.com https://<您的海外域名>/dns-query` 和 `nslookup google.com https://<您的海外域名>/dns-query`，检查返回的IP地址是否符合预期（国内/国外）。
    *   检查各容器日志确保无异常：`docker-compose logs -f`。 