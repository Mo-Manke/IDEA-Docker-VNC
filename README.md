# IDEA Docker VNC

通过 Docker 在浏览器中运行 IntelliJ IDEA Ultimate 2024，基于 VNC + noVNC 技术实现。

> 本项目借鉴了 [JetBrains/projector-docker](https://github.com/JetBrains/projector-docker) 的思路，但由于 Projector 项目已停止维护且不支持 IDEA 2022+，故采用 VNC + noVNC 方案进行二次开发，以支持最新版本的 JetBrains IDE。

## 特性

- 支持 **IntelliJ IDEA Ultimate 2024** 及更新版本
- 通过**浏览器**访问完整 IDE（noVNC）
- **自动激活**，无需手动输入激活码
- 数据**持久化**，重启不丢失
- 支持**中文**显示
- 一键 Docker Compose 部署

## 快速开始

```bash
# 1. 构建并启动
docker compose up -d --build

# 2. 浏览器访问
http://localhost:6080/vnc.html

# 3. VNC 密码: idea123
```

双击桌面 **IntelliJ IDEA** 图标启动，已自动激活。

## 配置

编辑 `.env` 文件：

```bash
IDE_DOWNLOAD_URL=https://download.jetbrains.com/idea/ideaIU-2024.3.1.1.tar.gz
VNC_PASSWORD=idea123
NOVNC_PORT=6080
```

## 常用命令

```bash
docker compose up -d          # 启动
docker compose logs -f        # 日志
docker compose down           # 停止
docker compose down -v        # 清理数据
docker compose up -d --build  # 重建
```

## 致谢

- [JetBrains/projector-docker](https://github.com/JetBrains/projector-docker)
- [noVNC](https://novnc.com/)
- [TigerVNC](https://tigervnc.org/)

## License

[Apache 2.0](LICENSE.txt)
