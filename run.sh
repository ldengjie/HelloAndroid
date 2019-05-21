#!/bin/bash

set -e

ANDROID_SDK_PATH="/opt/android-sdk"
BUILD_TOOLS_PATH=$ANDROID_SDK_PATH"/build-tools/26.0.1"
PLATFORM_PATH=$ANDROID_SDK_PATH"/platforms/android-19"
TOOLS_PATH=$ANDROID_SDK_PATH"/tools"

AAPT=$BUILD_TOOLS_PATH"/aapt"
DX=$BUILD_TOOLS_PATH"/dx"
ZIPALIGN=$BUILD_TOOLS_PATH"/zipalign"
APKSIGNER=$BUILD_TOOLS_PATH"/apksigner" # /!\ version 26
PLATFORM=$PLATFORM_PATH"/android.jar"
SDKMANAGER=$TOOLS_PATH"/bin/sdkmanager"

KEY=$ANDROID_SDK_PATH"/lidj.keystore"
ADB=$ANDROID_SDK_PATH"/platform-tools/adb"

function build(){
    echo "Generating R.java file..."
    $AAPT package -f -m -J src -M AndroidManifest.xml -S res -I $PLATFORM

    echo "Compiling..."
    javac -d obj -classpath src -bootclasspath $PLATFORM  src/com/example/helloandroid/*.java

    echo "Translating in Dalvik bytecode..."
    $DX --dex --output=classes.dex obj

    echo "Making APK..."
    $AAPT package -f -m -F bin/hello.unaligned.apk -M AndroidManifest.xml -S res -I $PLATFORM
    $AAPT add bin/hello.unaligned.apk classes.dex

    echo "Aligning and signing APK..."
    $ZIPALIGN -f 4 bin/hello.unaligned.apk bin/hello.apk
    $APKSIGNER sign --ks $KEY bin/hello.apk
}

function clean(){
    echo "Cleaning..."
    rm -rf classes.dex
    rm -rf bin/*
    rm -rf obj/*
    rm -rf src/com/example/helloandroid/R.java
}

function program(){
	echo "Launching..."
    $ADB install -r bin/hello.apk
	$ADB shell am start -n com.example.helloandroid/.MainActivity
}

function tool(){
    #mkdir some dir
    mkdir -p bin
    mkdir -p obj
    mkdir -p libs

    #export JAVA_OPTS='-XX:+IgnoreUnrecognizedVMOptions --add-modules java.se.ee'

    if [ ! -d $ANDROID_SDK_PATH ]; then 
        #download tool
        echo "> download tool...."
        wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
        mkdir -p $ANDROID_SDK_PATH
        unzip sdk-tools-linux-3859397.zip -d $ANDROID_SDK_PATH
        rm -rf sdk-tools-linux-3859397.zip
        sudo chmod -R 777 $ANDROID_SDK_PATH
    fi

    #install sdk build-tools platform
    echo "> install sdk build-tools platform...."
    $SDKMANAGER "platform-tools" "platforms;android-19"
    $SDKMANAGER "platform-tools" "build-tools;26.0.1" 
    $SDKMANAGER --list

    if [ ! -e $KEY ]; then 
        keytool -genkeypair -validity 365 -keystore $KEY -keyalg RSA -keysize 2048
    fi
}

if [ "$1" == "all" ]; then
    clean
    build
    program
elif [ "$1" == "clean" ]; then
    clean
elif [ "$1" == "build" ]; then
    build
elif [ "$1" == "program" ]; then
    program
elif [ "$1" == "tool" ]; then
    tool
else
    echo "error"
fi
