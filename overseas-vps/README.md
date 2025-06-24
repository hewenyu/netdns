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

2.  **获取SSL证书**:
    *   为您的域名申请SSL证书，并将证书和私钥文件放入本目录下的 `openresty/ssl/` 文件夹中。

3.  **修改配置**:
    *   **MosDNS**: 打开 `mosdns/config.yaml`，找到 `upstream "remote_cn_doh"` 部分，将其中的 `url` 修改为您**国内VPS的DoH地址** (`https://<您的国内DoH域名>/dns-query`)。
    *   **OpenResty**: 打开 `openresty/conf.d/default.conf`，将 `server_name` 修改为您的域名，并确认SSL证书文件名正确。
    *   **AdGuardHome**: 首次启动后，访问 `http://<您的海外VPS_IP>:3001` 进行初始化设置。在"上游DNS服务器"处填写 `172.16.233.3` (即MosDNS在内部Docker网络中的地址)，并根据向导完成后续配置。
    *   **自定义规则**: 如需添加自定义的直连或代理域名，请直接编辑 `mosdns/rules/force-cn.txt` 和 `mosdns/rules/force-nocn.txt` 文件，每行一个域名。规则会在下次自动更新时被整合。

4.  **启动服务**:
    *   在本目录下 (`overseas-vps/`) 执行命令：
        ```bash
        docker-compose up -d
        ```

5.  **终端用户配置**:
    *   所有配置完成后，您需要提供给最终用户的DoH地址为：`https://<您的海外域名>/dns-query`。
    *   将此地址配置到路由器、浏览器或操作系统中，即可开始使用。

6.  **验证**:
    *   执行 `nslookup qq.com https://<您的海外域名>/dns-query` 和 `nslookup google.com https://<您的海外域名>/dns-query`，检查返回的IP地址是否符合预期（国内/国外）。
    *   检查各容器日志确保无异常：`docker-compose logs -f`。 