[![Build and publish image](https://github.com/funwukong/ysp-live/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/funwukong/ysp-live/actions/workflows/docker-publish.yml)
[![Release](https://img.shields.io/github/v/release/funwukong/ysp-live)](https://github.com/funwukong/ysp-live/releases)

# ysp-live v11.3：央视频全频道直播服务

纯 Python 标准库，零第三方依赖。AES-256-GCM / RSA-OAEP-SHA256 都是自带实现，不需要 `cryptography`。
推荐 Docker 部署，也可以直接 `python3 ysp-live.py` 跑。

## 版本说明（v11.3）

v11.3 是**纯 YSPTP 单栈**重写，和 v9.x 的 JCE + Resolve 设备协议双栈不是一个代码库：

- 设备协议：`App start` → 云注册 → `live/v1` → `vdn getstream`，纯标准库自实现 TLS 之外的全部密码学
- 1080p 线路：`bkliveinfo` + TEA cKey 签名（`H.264 1080p`）
- 回看：JCE `PidTimeShift`，`catchup="append"`，7 天
- 频道表：64 路（央视 30 + 卫视 34），其中 26 路高码率频道按需走设备协议

本仓库在 v11.3 上游代码基础上做了三处**本地韧性补丁**（业务语义不变，只提升可用率）：

1. `relay_live_playlist`：起播分片预热失败不再作废整个地址（原来单次 403 就把有效 m3u8 判死）
2. `bk_refresh`：CDN 边缘节点返回截断响应（`Content-Length N`、实际 0 字节）时对同一地址重试一次
3. `bk_refresh`：任意失败都会进入第二轮并重新签发 `bk_urls`（原来只在传输错误且未复用地址时才重签）

这三处修复解决了「卫视频道大面积 503」：吉林/陕西/内蒙古/云南/山西/甘肃/西藏/新疆/国学 等频道从稳定 503 恢复到 200。

## 快速开始

### 方式一：拉取预构建镜像（推荐）

镜像由 GitHub Actions 自动构建发布到 GHCR，amd64 / arm64 都有：

```bash
docker pull ghcr.io/funwukong/ysp-live:11.3
docker run -d --name ysp-live --restart unless-stopped \
  -e TZ=Asia/Shanghai -p 8767:8767 \
  ghcr.io/funwukong/ysp-live:11.3
```

### 方式二：从源码构建

```bash
git clone https://github.com/funwukong/ysp-live.git
cd ysp-live
docker compose up -d
```

启动后访问 http://localhost:8767/ ，聚合订阅是 http://localhost:8767/all.m3u 。

## 常用参数

```bash
python3 ysp-live.py 8767                 # 端口
python3 ysp-live.py 8767 --bind 0.0.0.0  # 监听地址
python3 ysp-live.py 8767 --data-dir /data # 状态持久化目录（默认 YSP_DATA_DIR 或脚本目录）
python3 ysp-live.py 8767 --no-4k         # 关闭设备协议，全频道 1080p
python3 ysp-live.py 8767 --only-4k       # 仅 4K/8K 走设备协议
python3 ysp-live.py 8767 --links-per-device 6   # 单设备并发配额（0=不限）
python3 ysp-live.py 8767 --zap-debounce 0       # 换台升码率等待（默认 0）
python3 ysp-live.py 8767 --cache-mb 200         # TS 分片内存缓存
python3 ysp-live.py 8767 --no-engine            # 不进伴生 WASM 引擎
```

Docker 下用环境变量：`PORT`、`YSP_DATA_DIR`、`YSP_LINKS_PER_DEVICE`、`YSP_ZAP_DEBOUNCE`、`YSP_ENGINE_PORT`，
命令行追加参数用 `YSP_EXTRA_ARGS`（例如 `--no-4k`）。

## 接口

| 路径 | 说明 |
| --- | --- |
| `/` | 首页 |
| `/all.m3u` | 全频道订阅 |
| `/all.m3u?group=卫视` | 按分组订阅 |
| `/all.m3u?k4=1` | 仅 4K/8K 频道 |
| `/<slug>.m3u8` | 单频道直播清单（如 `/cctv1.m3u8`、`/bjws.m3u8`） |
| `/<slug>.m3u8?playseek=起-止` | 7 天回看，格式 `yyyyMMddHHmmss` |
| `/proxy.ts?=<token>` | 设备协议分片中继（签名播放头） |
| `/live-segment.ts` | 1080p 分片中继 |
| `/replay-segment.ts` | 回看分片中继 |
| `/health` | 健康探针（容器 healthcheck 用） |
| `/diag` | 每路频道的模式、刷新时间、错误 |

## 状态文件

持久化在 `--data-dir`（默认脚本目录，Docker 下 `/data`）：

- `device-state-rs.json`：设备身份，删掉会重新注册新设备
- `proxy-cache-state-rs.json`：播放列表缓存

## 已知上游限制

- 回看接口 `jacc.ysp.cctv.cn` 近期对任意频道/任意时间窗都返回空地址，引擎会报 `empty m3u8`；
  这是上游服务侧问题，直播线路不受影响。
- 部分 CDN 边缘节点会间歇返回截断响应或 403，本仓库的补丁会自动重签换路。

## 来源

- 上游代码：ysp-live v11.3（作者发布渠道见 `/`）
- cKey / 频道表：上游项目内置
