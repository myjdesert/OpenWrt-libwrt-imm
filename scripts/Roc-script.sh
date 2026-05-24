#!/bin/bash

# 修改默认IP
sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate
# 固件名称
sed -i "s/hostname='.*'/hostname='OpenWrt'/g" package/base-files/files/bin/config_generate

# 移除luci-app-attendedsysupgrade软件包
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 移除要替换的冲突包
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/applications/luci-app-wechatpush
rm -rf feeds/luci/applications/luci-app-appfilter
rm -rf feeds/luci/applications/luci-app-watchcat
rm -rf feeds/luci/applications/luci-app-frpc
rm -rf feeds/luci/applications/luci-app-frps
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/packages/net/open-app-filter
rm -rf feeds/packages/net/ariang
rm -rf feeds/packages/net/frp
rm -rf feeds/packages/lang/golang
rm -rf feeds/packages/utils/watchcat

# Git稀疏克隆函数
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# 基础组件克隆与归位
mv -f package/luci-app-frpc feeds/luci/applications/luci-app-frpc
mv -f package/luci-app-frps feeds/luci/applications/luci-app-frps
git_sparse_clone openwrt-23.05 https://github.com/immortalwrt/packages utils/watchcat
mv -f package/watchcat feeds/packages/utils/watchcat
git_sparse_clone openwrt-23.05 https://github.com/immortalwrt/luci applications/luci-app-watchcat
mv -f package/luci-app-watchcat feeds/luci/applications/luci-app-watchcat
git_sparse_clone main https://github.com/VIKINGYFY/packages luci-app-wolplus

# 主题与高频常用插件拉取
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon feeds/luci/themes/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config feeds/luci/applications/luci-app-argon-config
git clone --depth=1 https://github.com/eamonxg/luci-theme-aurora feeds/luci/themes/luci-theme-aurora
git clone --depth=1 https://github.com/eamonxg/luci-app-aurora-config feeds/luci/applications/luci-app-aurora-config
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/luci-app-lucky
git clone --depth=1 https://github.com/tty228/luci-app-wechatpush package/luci-app-wechatpush

# 其他特定依赖包
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-momo package/momo
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki package/nikki

# ==================== 1. 集客无线AC控制器 ====================
rm -rf package/luci-app-gecoosac package/openwrt-gecoosac
git clone --depth=1 https://github.com/lwb1978/openwrt-gecoosac package/openwrt-gecoosac

# ==================== 2. EasyTier 异地组网 ====================
rm -rf package/luci-app-easytier package/easytier
git clone --depth=1 https://github.com/thinktip/luci-app-easytier package/luci-app-easytier

# ==================== 3. 强行灌注的高版本 Golang 编译环境 ====================
# 彻底拔掉旧环境
rm -rf feeds/packages/lang/golang package/feeds/packages/lang/golang package/golang
# 克隆高版本 Go 独立包到原生 package 目录下
git clone --depth=1 https://github.com/sbwml/packages_lang_golang package/golang

# 【OpenWrt-CI 专属补丁】：在本地 package 和全局 feeds 目录同时建立物理文件夹与软链接
# 这将使 sing-box 寻找 ../../lang/golang/golang-package.mk 时，无论怎么跳目录都能 100% 成功。
mkdir -p package/lang
ln -sf ../golang package/lang/golang
mkdir -p feeds/packages/lang
ln -sf ../../../package/golang feeds/packages/lang/golang

# ==================== 4. PassWall 及其核心依赖 ====================
rm -rf package/luci-app-passwall package/passwall-packages package/passwall-packages-temp
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}

# 提取最新的现代核心依赖
git clone --depth=1 https://github.com/immortalwrt/packages.git -b openwrt-23.05 package/passwall-packages-temp
mkdir -p package/passwall-packages
mv package/passwall-packages-temp/net/xray-core package/passwall-packages/
mv package/passwall-packages-temp/net/sing-box package/passwall-packages/
mv package/passwall-packages-temp/net/chinadns-ng package/passwall-packages/
rm -rf package/passwall-packages-temp

# 克隆无访问限制的 PassWall 前端控制面板
git clone --depth=1 https://github.com/openwrt-develop/luci-app-passwall.git package/luci-app-passwall

# ==================== 5. 替换为清华大学软件源 ====================
if [ -f feeds.conf.default ]; then
    sed -i 's#https://github.com/immortalwrt/packages#https://mirrors.tuna.tsinghua.edu.cn/git/immortalwrt/packages.git#g' feeds.conf.default
    sed -i 's#https://github.com/immortalwrt/luci#https://mirrors.tuna.tsinghua.edu.cn/git/immortalwrt/luci.git#g' feeds.conf.default
    sed -i 's#https://github.com/immortalwrt/routing#https://mirrors.tuna.tsinghua.edu.cn/git/immortalwrt/routing.git#g' feeds.conf.default
    sed -i 's#https://github.com/immortalwrt/telephony#https://mirrors.tuna.tsinghua.edu.cn/git/immortalwrt/telephony.git#g' feeds.conf.default
fi

find package/ feeds/ -type f \( -name "distfeeds.conf" -o -name "10_default_settings" -o -name "config_generate" -o -name "default_settings" \) | xargs sed -i 's#downloads.immortalwrt.org#mirrors.tuna.tsinghua.edu.cn/immortalwrt#g'
find package/ feeds/ -type f \( -name "distfeeds.conf" -o -name "10_default_settings" -o -name "config_generate" -o -name "default_settings" \) | xargs sed -i 's#mirrors.vsean.net/openwrt#mirrors.tuna.tsinghua.edu.cn/immortalwrt#g'
find package/ feeds/ -type f \( -name "distfeeds.conf" -o -name "10_default_settings" -o -name "config_generate" -o -name "default_settings" \) | xargs sed -i 's#mirror.ghproxy.com/https://raw.githubusercontent.com#mirrors.tuna.tsinghua.edu.cn/git/immortalwrt#g'

# 设置 Argon 主题为系统默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/modules/luci-base/root/etc/config/luci
