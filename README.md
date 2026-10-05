# ysp-live：央视频全频道直播服务

纯 Python 标准库，无第三方依赖。推荐 Docker 部署，也可以直接 python3 ysp-live.py 跑。

## 频道

63 路公开频道：央视 21 + CGTN 6 + 剧场 3 + 卫视 31 + CETV-1 + 国学。

- 52 路走 JCE PidTimeShift 协议（jacc.ysp.cctv.cn），1080p H.264
- 11 路（CCTV-11/12/14/15/16/17、16-4K、4K、风云/第一/怀旧剧场）JCE 返回坏域名，自动切换 bkliveinfo + cKey 备用协议

**注意**：匿名接口最高 1080p。真 4K（HEVC）需要带设备注册签名的协议，本脚本不包含。

## 使用

### Docker（推荐）

```bash
# 构建并启动（后台）
docker compose up -d

# 换宿主端口，比如 8080
PORT=8080 docker compose up -d

# 日志 / 停止 / 重启
docker compose logs -f
docker compose down
docker compose restart
```

启动后：

- 首页：http://localhost:8766/
- 聚合订阅：http://localhost:8766/all.m3u（63 路一次导入播放器）
- 健康探针：http://localhost:8766/health（容器 healthcheck 用这个）
- 诊断：http://localhost:8766/diag（看每路的 mode 和报错）

镜像基于 python:3.12-alpine，纯标准库无第三方依赖，构建完约 60 MB。
端口和监听地址由 PORT / HOST 环境变量控制，容器内默认 0.0.0.0:8766。
改容器内端口时要同步改 docker-compose.yml 里的 healthcheck 和端口映射。

不用 compose 也行：

```bash
docker build -t ysp-live .
docker run -d --name ysp-live -p 8766:8766 --restart unless-stopped ysp-live
```

### 直接跑（不装 Docker）

```bash
# 启动（默认端口 8766）
python3 ysp-live.py

# 指定端口
python3 ysp-live.py 8080

# 指定监听地址和端口
python3 ysp-live.py 8080 --host 127.0.0.1
```

## 原理

播放器直连央视 CDN 拉视频分片，本机只下发 m3u8 清单，不跑视频流量。

- JCE：调央视频时移接口，截取近实时窗口转成直播流，延迟约 20 秒
- bkliveinfo：央视备用直播接口，需要 TEA cKey 签名（已移植为纯 Python）

## Mac 开机自启（可选）

```bash
# 复制 plist 到 LaunchAgents（改里面的路径为你的实际路径）
cp com.user.ysp-live.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.ysp-live.plist
```

## 来源

- JCE 协议：sophomoresty/mediago
- 频道表/cKey：akiralereal/iptv
