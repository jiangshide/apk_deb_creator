#!/bin/bash
# 1: apk文件 2: 中文名 3. 英文名

if [ ! -d apkcreator/home ]; then
    mkdir -p apkcreator/home/compat/data-compat
fi

if [ ! -d apkcreator/usr ]; then
    mkdir -p apkcreator/usr/share/applications
    mkdir -p apkcreator/usr/share/icons/hicolor/apps
fi

if [ $# -lt 4 ]; then
    echo "参数1: apk文件名 \
          参数2: 应用的中文名 \
          参数3: 应用的英文名 \
          参数4: 版本"
    echo ""
    exit 1
fi

apk_file=$1
apk_basename=$(basename $apk_file .apk)
echo ${apk_basename}

if [ ! -f ${apk_basename}.png ]; then
	echo "没有图标"
	exit 1
fi

desktop_file=${apk_basename}.desktop
echo ${desktop_file}

echo " \
[Desktop Entry]
Name=$2
Name[zh_CN]=$2
Name[en_GB]=$3
Version=$4
Icon=${apk_basename}.png
Categories=Android
" > apkcreator/usr/share/applications/${desktop_file}

echo "\
Package: ${apk_basename}
Version: $4
Maintainer: maintainer@jingos.com
Architecture: arm64
Description: $2, Android 应用
Depends: jingsideproxy(>=1.0), androidcompat(>=1.0)
" > apkcreator/DEBIAN/control

echo "\
lxc-attach -P /home/compat/lxc -n androidcompat -- pm install ${apk_file}
exit 0\
" > apkcreator/DEBIAN/postinst

cp ${apk_basename}.png apkcreator/usr/share/icons/hicolor/apps/
cp ${apk_file} apkcreator/home/compat/data-compat/

deb_file=${apk_basename}_$4_aarch64.deb
dpkg-deb --build apkcreator ${deb_file}

# clean
rm -f apkcreator/home/compat/data-compat/*
rm -f apkcreator/usr/share/applications/*.desktop
rm -f apkcreator/usr/share/icons/hicolor/apps/*.png

scp ${deb_file} image:~/workspace/deb/
echo -n "是否需要删除输入文件及生成的 deb？"
read ans
case ${ans} in
    (Y | y)
        rm *.deb *.png *.apk;;
    (*)
        echo "什么也不做"
esac
