# 部署故障排查指南

## 目录
- [Scipy 构建失败 - Meson 错误](#scipy-构建失败---meson-错误)
- [Scipy 构建失败 - Pythran 错误](#scipy-构建失败---pythran-错误)
- [其他常见问题](#其他常见问题)

---

## Scipy 构建失败 - Pythran 错误

### 错误信息
```
TypeError: 'module' object is not callable
File ".../pythran/optimizations/pattern_transform.py", line 327, in visit
    matcher = pattern()
```

### 原因
这是 **Python 3.11+ 与 pythran 编译器的兼容性问题**。pythran 是 scipy 用来优化代码的工具，在 Python 3.11 上存在已知的兼容性问题。

### 解决方案（按推荐顺序）

#### 🚀 方案 1: 使用自动修复脚本（最简单）

```bash
cd /var/www/dimensio/deploy
sudo ./fix-scipy-pythran.sh
```

这个脚本会自动：
- 检测 Python 版本
- 为 Python 3.11+ 安装预编译包
- 为 Python 3.10- 从源码编译
- 验证安装结果

#### 💡 方案 2: 手动安装预编译包（Python 3.11+）

```bash
cd /var/www/dimensio
rm -rf venv
python3 -m venv venv
source venv/bin/activate

# 升级 pip
pip install --upgrade pip setuptools wheel

# 使用预编译的二进制包（避免编译）
pip install "numpy>=1.24.0,<1.27.0"
pip install "scipy>=1.11.0,<1.12.0"

# 安装其他依赖
pip install scikit-learn pandas matplotlib seaborn
pip install -r requirements.txt
pip install -r api/requirements.txt
```

**为什么这样可以？**
- 跳过从源码编译 scipy
- 使用官方提供的预编译二进制包
- 这些版本对 Python 3.11 有良好支持

#### 🔧 方案 3: 降级到 Python 3.10（推荐生产环境）

Python 3.10 与 scipy 的兼容性最好：

```bash
# 安装 Python 3.10
sudo apt update
sudo apt install -y python3.10 python3.10-venv python3.10-dev

# 使用 Python 3.10 创建虚拟环境
cd /var/www/dimensio
rm -rf venv
python3.10 -m venv venv
source venv/bin/activate

# 正常安装所有依赖
pip install --upgrade pip
pip install -r requirements.txt
pip install -r api/requirements.txt
```

#### 🐳 方案 4: 使用 Docker（最稳定）

Docker 镜像使用 Python 3.9，避免了所有兼容性问题：

```bash
cd deploy/docker
docker-compose up -d
```

#### 🛠️ 方案 5: 修复 Pythran 版本（高级）

如果必须从源码编译，固定兼容的依赖版本：

```bash
source venv/bin/activate

# 安装兼容版本的构建依赖
pip install --upgrade \
    'pythran>=0.12.0,<0.15.0' \
    'beniget==0.4.1' \
    'gast==0.5.4'

# 清理缓存
pip cache purge

# 重新安装 scipy
pip install --no-cache-dir scipy
```

### 验证修复

```bash
source venv/bin/activate

python << 'EOF'
import numpy as np
import scipy
print(f"✅ NumPy {np.__version__}")
print(f"✅ SciPy {scipy.__version__}")
print("修复成功！")
EOF
```

---

## Scipy 构建失败 - Meson 错误

### 错误信息
```
ERROR: Failed to build 'scipy' when getting requirements to build wheel
subprocess.CalledProcessError: Command '['meson', 'setup', ...]' returned non-zero exit status 1.
```

### 原因
scipy 从 1.9.0 版本开始使用 meson 构建系统，需要额外的系统依赖：
- BLAS/LAPACK 数学库
- Fortran 编译器（gfortran）
- 其他构建工具

### 解决方案

#### 方案 1: 安装系统依赖（推荐）

##### Ubuntu/Debian:
```bash
# 安装所有必需的构建依赖
sudo apt update
sudo apt install -y \
    python3-dev \
    build-essential \
    gfortran \
    libopenblas-dev \
    liblapack-dev \
    pkg-config \
    cmake

# 然后重新尝试安装
cd /var/www/dimensio
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

##### CentOS/RHEL/Rocky Linux:
```bash
sudo yum install -y \
    python3-devel \
    gcc \
    gcc-c++ \
    gcc-gfortran \
    openblas-devel \
    lapack-devel \
    pkgconfig \
    cmake

# 然后重新尝试安装
cd /var/www/dimensio
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

#### 方案 2: 使用预编译的二进制包（最快）

```bash
# 清理旧的环境
cd /var/www/dimensio
rm -rf venv
python3 -m venv venv
source venv/bin/activate

# 升级 pip 到最新版本（重要！）
pip install --upgrade pip setuptools wheel

# 安装依赖时优先使用二进制包
pip install --only-binary :all: -r requirements.txt

# 如果某些包没有二进制版本，单独处理
pip install --no-binary numpy,scipy numpy scipy
```

#### 方案 3: 修改 requirements.txt 使用旧版本

编辑 `requirements.txt`，指定兼容的版本：

```bash
# 修改 requirements.txt
cd /var/www/dimensio
nano requirements.txt
```

将相关行改为：
```txt
numpy>=1.19.0,<1.24.0
scipy<1.9.0  # 使用不依赖 meson 的旧版本
scikit-learn>=0.24.0,<1.2.0
```

然后重新安装：
```bash
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

#### 方案 4: 使用 Conda（替代方案）

如果上述方法都不行，使用 Conda 环境：

```bash
# 安装 Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3
source $HOME/miniconda3/bin/activate

# 创建环境
conda create -n dimensio python=3.9 -y
conda activate dimensio

# 使用 conda 安装科学计算包
conda install -y numpy scipy scikit-learn pandas matplotlib seaborn

# 安装其他依赖
pip install -r requirements.txt
```

### 推荐的完整安装流程

```bash
#!/bin/bash
# 完整的依赖安装脚本

# 1. 安装系统依赖
sudo apt update
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    gfortran \
    libopenblas-dev \
    liblapack-dev \
    pkg-config \
    cmake \
    git \
    curl

# 2. 创建虚拟环境
cd /var/www/dimensio
rm -rf venv  # 如果之前安装失败，清理旧环境
python3 -m venv venv
source venv/bin/activate

# 3. 升级基础工具
pip install --upgrade pip setuptools wheel

# 4. 分步安装依赖（更稳定）
# 先安装 numpy（很多包依赖它）
pip install "numpy>=1.19.0,<2.0.0"

# 安装科学计算核心库
pip install scipy scikit-learn

# 安装其他依赖
pip install pandas matplotlib seaborn

# 安装项目特定依赖
pip install ConfigSpace==0.6.1 shap openbox

# 安装 API 依赖
pip install Flask flask-cors gunicorn

# 5. 验证安装
python -c "import numpy; print(f'numpy: {numpy.__version__}')"
python -c "import scipy; print(f'scipy: {scipy.__version__}')"
python -c "import sklearn; print(f'sklearn: {sklearn.__version__}')"

echo "依赖安装完成！"
```

### 验证安装

安装完成后，验证关键包：

```bash
source venv/bin/activate

# 测试导入
python << EOF
import numpy as np
import scipy
import sklearn
import pandas as pd
from dimensio import Compressor
print("所有关键包导入成功！")
EOF
```

### 如果仍然失败

如果上述所有方法都不行，使用我提供的预配置 Docker 方案：

```bash
cd deploy/docker
docker-compose up -d
```

Docker 方案已经包含了所有编译好的依赖，不会有构建问题。

---

## 其他常见问题

### 问题: `numpy` 版本冲突

**错误信息**:
```
ERROR: pip's dependency resolver does not currently take into account all the packages that are installed...
```

**解决方案**:
```bash
# 重新创建虚拟环境
cd /var/www/dimensio
rm -rf venv
python3 -m venv venv
source venv/bin/activate

# 按顺序安装
pip install --upgrade pip
pip install "numpy>=1.19.0,<2.0.0"
pip install -r requirements.txt
```

### 问题: `ConfigSpace` 安装失败

**解决方案**:
```bash
pip install "ConfigSpace==0.6.1" --no-cache-dir
```

### 问题: 权限错误

**错误信息**:
```
PermissionError: [Errno 13] Permission denied
```

**解决方案**:
```bash
# 不要使用 sudo pip！
# 确保使用虚拟环境
cd /var/www/dimensio
source venv/bin/activate

# 如果目录权限有问题
sudo chown -R $USER:$USER venv
```

### 问题: 内存不足

**错误信息**:
```
Killed
```

**解决方案**:
```bash
# 增加交换空间
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 永久生效
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 然后重新安装
```

### 问题: pip 版本太旧

**解决方案**:
```bash
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

---

## 快速诊断脚本

```bash
#!/bin/bash
# 环境诊断脚本

echo "=== 系统信息 ==="
lsb_release -a 2>/dev/null || cat /etc/os-release
echo ""

echo "=== Python 信息 ==="
python3 --version
pip --version 2>/dev/null || pip3 --version
echo ""

echo "=== 系统依赖检查 ==="
for pkg in gcc g++ gfortran make cmake pkg-config; do
    if command -v $pkg &> /dev/null; then
        echo "✓ $pkg: $(command -v $pkg)"
    else
        echo "✗ $pkg: 未安装"
    fi
done
echo ""

echo "=== BLAS/LAPACK 检查 ==="
dpkg -l | grep -E "openblas|lapack" || echo "未找到 BLAS/LAPACK 包"
echo ""

echo "=== Python 开发包检查 ==="
dpkg -l | grep python3-dev || echo "未找到 python3-dev"
echo ""

echo "=== 内存信息 ==="
free -h
echo ""

echo "=== 磁盘空间 ==="
df -h /
```

保存为 `diagnose.sh` 并运行：
```bash
chmod +x diagnose.sh
./diagnose.sh
```
