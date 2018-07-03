Developing the react-native-audio-toolkit library
=================================================

It is recommended to use the [demo application (ExampleApp)](/ExampleApp)
also for library development purposes, and to implement any new features in it
for others to easily try.

Unfortunately it seems that library development for react-native is still a bit
of a hassle. The react-native packager [does not support
symlinks](https://github.com/facebook/watchman/issues/105), which would
otherwise enable us to use `npm link` to symlink the library we're developing
into an example application.

Here is workaround fix `npm link`

```
react-native-audio-toolkit$ npm link
react-native-audio-toolkit/ExapleApp$ npm install
.
.
react-native-audio-toolkit/ExapleApp$ npm link @ybrain/react-native-audio-toolkit
react-native-audio-toolkit/ExapleApp$ node react-native-start-with-link.js 
```

Library structure
=================

The library consists of two parts:

* Native code that implements the device specific media APIs
* JavaScript code that exposes the native methods to React Native developers

The main JavaScript file that exports all library classes is at
[index.js](/index.js). The class implementations are available in [src/](/src)

Native code is available in the [android/](/android) and [ios/](/ios)
directories for respective platforms.

Try to avoid having platform specific code in the JavaScript where possible,
instead abstract these away in the platform specific native code. Other than
that, try to keep as much of the logic as possible in JavaScript.
