#!/data/data/com.termux/files/usr/bin/bash

# Prints a message indicating the next operation.
echo '================ Verifying the architecture of the host machine ==================='

# Verify the architecture of the host machine.
case $(uname -m) in
  aarch64)   echo 'Architecture aarch64 detected. It is allowed. You can continue.' ;;
  arm)  dpkg --print-architecture | grep -q "arm64" && \
    echo 'Support for architecture aarch64 detected. It is allowed. You can continue' || \
    echo 'Not support for architecture aarch64 detected. Exiting now.' && exit 1  ;;
  *) echo 'Not architecture aarch64 or support for it detected. Exiting now.' && exit 1   ;;
esac

# Detecting the Android's version.
s_version=$(termux-info | grep -A1 "Android version" | grep -Po "\\d+")
version=$(($s_version+0))

# Verify android's version.
if (( $version < 9 )) then
	echo 'Unfortunately Android must be 9 or above.'
	exit 1
fi

# Variables.
full=0;sdk=0;minimal=0;

# Minimal installation.
while true; do
  read -p "Minimal installation just include required files for Android cross compilation (version r23c).\nDo you wish to install it? (y/n): " yn
  case $yn in
    [Yy]* ) minimal=0; break;;
    [Nn]* ) full=0; break;;
    * ) echo "Please answer y(yes) or n(no).";;
  esac
done

# Others installations.
if [ minimal == 0 ]; then

  # Full installation.
  while true; do
    read -p "Full NDK contains components for Android cross compilation (version r27b) and light version contains only components for arm64(aarch64) compilation (version r23c).\nDo you wish to install full NDK? (y/n): " yn
    case $yn in
      [Yy]* ) full=1; break;;
      [Nn]* ) full=0; break;;
      * ) echo "Please answer y(yes) or n(no).";;
    esac
  done

  # Installation of Android SDK.
  while true; do
    read -p "Do you wish to install SDK? It is for re-compile java for beginer useless (y/n): " yn
    case $yn in
      [Yy]* ) sdk=1; break;;
      [Nn]* ) sdk=0; break;;
      * ) echo "Please answer y(yes) or n(no).";;
    esac
  done
fi

# Install dependencies.
echo '================================================================'
echo '                     install dependencies'
echo '================================================================'
pkg update && pkg upgrade && pkg install aapt apksigner dx ecj openjdk-17 git wget

# Install Android SDK if requested.
if [ $sdk == 1 ]; then
  echo '================================================================'
  echo '                     download sdk.zip'
  echo '================================================================'
  cd ~ && wget https://github.com/Lzhiyong/termux-ndk/releases/download/android-sdk/android-sdk-aarch64.zip
  echo '================================================================'
  echo '                               unzip sdk.zip'
  echo '================================================================'
  cd ~ && unzip -qq android-sdk-aarch64.zip
  echo '================================================================'
  echo '                              tidy sdk.zip'
  echo '================================================================'
  cd ~ && rm android-sdk-aarch64.zip
fi

# Download Android NDK.
echo '================================================================'
echo '                     download ndk.zip'
echo '================================================================'
if [ $minimal == 1 ]; then
  cd ~ && wget https://github.com/DuilioPerez/MANFT/blob/main/android-ndk-r23c.tar.xz
else
  if [ $full == 1 ]; then 
    cd ~ && wget https://github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r27b-aarch64.zip
  else
    cd ~ && wget https://github.com/MatejMagat305/termux-ndk/releases/download/release/android-ndk-r23c-aarch64.zip
  fi
fi

echo '================================================================'
echo '                               unzip ndk.zip'
echo '================================================================'
if [ $minimal == 0 ]
  cd ~ && unzip -qq android-ndk-r23c-aarch64.zip
else
  cd ~ && tar -xJf android-ndk-r23c.tar.xz
fi

echo '================================================================'
echo '                               fix sh in ndk path'
echo '================================================================'
cd ~ && termux-fix-shebang /data/data/com.termux/files/home/android-ndk-r23c/toolchains/llvm/prebuilt/linux-aarch64/bin/*
echo '================================================================'
echo '                               tidy ndk.zip'
echo '================================================================'
cd ~ && rm android-ndk-r23c-aarch64.zip


echo '================================================================'
echo '                               set env variables'
echo '================================================================'
if [ $sdk == 1 ]; then 
  echo 'export ANDROID_HOME=/data/data/com.termux/files/home/android-sdk/' >> ~/../usr/etc/profile
fi
echo 'export ANDROID_NDK_HOME=/data/data/com.termux/files/home/android-ndk-r23c/' >> ~/../usr/etc/profile
echo 'export ANDROID_NDK_ROOT=$ANDROID_NDK_HOME' >> ~/../usr/etc/profile


echo '================================================================'
echo '                               install golang'
echo '================================================================'
pkg install golang
cd ~ && mkdir -p go/bin
echo 'export PATH=$PATH:/data/data/com.termux/files/home/go/bin/' >> ~/../usr/etc/profile

echo '================================================================'
echo '                               install fyne'
echo '================================================================'
cd ~ && git clone https://github.com/fyne-io/fyne.git && cd fyne && cd cmd/fyne && go build && chmod 1777 fyne && mv fyne /data/data/com.termux/files/home/go/bin/ && cd ~ && rm -rf fyne

echo '================================================================'
echo '                                 complete'
echo '================================================================'
echo ''
if [ $full == 1 ]; then 
  echo 'you can put "fyne package -os android -icon some_icon_name -name some_name -release -appID some_package_name" in fyne project'
else
  echo 'you can put "fyne package -os android/arm64 -icon some_icon_name -name some_name -release -appID some_package_name" in fyne project'
fi
echo 'put "source ~/../usr/etc/profile"'
