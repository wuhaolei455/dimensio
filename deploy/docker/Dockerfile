# Dimensio Docker 镜像
FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 配置国内镜像源（可选，国内用户取消注释）
# Debian 镜像源
ARG USE_CN_MIRROR=true
RUN if [ "$USE_CN_MIRROR" = "true" ]; then \
    sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's/security.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources; \
    fi

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js（用于构建前端）
# 国内用户可以使用清华镜像
RUN if [ "$USE_CN_MIRROR" = "true" ]; then \
        curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/nodesource/deb_18.x/setup_18.x | bash -; \
    else \
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -; \
    fi && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# 配置 npm 镜像源
RUN if [ "$USE_CN_MIRROR" = "true" ]; then \
        npm config set registry https://registry.npmmirror.com; \
    fi

# 复制项目文件
COPY .. /app/

# 配置 pip 镜像源
RUN if [ "$USE_CN_MIRROR" = "true" ]; then \
        pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple; \
    fi

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir -r api/requirements.txt \
    && pip install --no-cache-dir gunicorn

# 构建前端
WORKDIR /app/front
RUN npm install && npm run build

# 回到工作目录
WORKDIR /app

# 创建必要的目录
RUN mkdir -p /app/data /app/result /app/logs

# 暴露端口
EXPOSE 5000

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=api/server.py
ENV FLASK_ENV=production

# 启动命令
CMD ["gunicorn", "--bind", "0.0.0.0:5000", \
     "--workers", "4", \
     "--threads", "2", \
     "--timeout", "600", \
     "--access-logfile", "/app/logs/access.log", \
     "--error-logfile", "/app/logs/error.log", \
     "api.server:app"]
