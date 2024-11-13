## automation page

This is the automation center for iot system. It can create, edit, delete, enable, disable, view, and run automation rules.

## automation rule

The rules are written in IoTLang, a domain-specific language for IoT automation. The rules are executed by the gateway's dsl engine.

## automation rule editor

In order to make it both friendly and powerful, the automation rule editor is designed to be a block-based editor. It is based on Blockly, a library developed by Google.

## 注意事项

构建安卓端的时候好像只能用openjdk17，我用openjdk21构建的时候会报错：

```bash
FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':shared_preferences_android:compileReleaseJavaWithJavac'.
> Could not resolve all files for configuration ':shared_preferences_android:androidJdkImage'.
   > Failed to transform core-for-system-modules.jar to match attributes {artifactType=_internal_android_jdk_image, org.gradle.libraryelements=jar, org.gradle.usage=java-runtime}.
      > Execution failed for JdkImageTransform: /opt/android-sdk/platforms/android-34/core-for-system-modules.jar.
         > Error while executing process /usr/lib/jvm/java-21-openjdk/bin/jlink with arguments {--module-path /home/xeonds/.gradle/caches/transforms-3/10ea4caf7cd1923f84a0f290ba7344f4/transformed/output/temp/jmod --add-modules java.base --output /home/xeonds/.gradle/caches/transforms-3/10ea4caf7cd1923f84a0f290ba7344f4/transformed/output/jdkImage --disable-plugin system-modules}
```

换openjdk17就好了。
