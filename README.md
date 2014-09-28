Bowser
======

A WebRTC browser for iOS developed in the open. Bowser is built on top of [OpenWebRTC](https://github.com/EricssonResearch/openwebrtc).

![Bowser logo](http://static.squarespace.com/static/53f1eedee4b0439bf8d480c5/t/53f25022e4b0cca46a383183/1408389154850/?format=500w "Bowser logo")

### Extension of UIWebView
Bowser is based on the official `UIWebView` provided by the platform and the [WebRTC](http://www.w3.org/2011/04/webrtc/) API's are implemented with JavaScript that is injected into web pages as they load, the injected JavaScript code is using remote procedure calls to control the [OpenWebRTC](https://github.com/EricssonResearch/openwebrtc) backend.

The [plan](https://github.com/EricssonResearch/bowser/issues/1) is to move to the `WKWebView`, introduced in iOS 8, as soon as possible.  

### Video
Mobile Safari on iPhone displays `<video>` elements only in fullscreen. This severely limits the UI of your apps, especially when designing video communication apps using WebRTC. Bowser goes beyond that and allows you to fully customise and manipulate `<video>` elements using CSS and JavaScript.

### Background
Bowser was originally developed by Ericsson Research and released in October of 2012, for both iOS and Android devices. Back then Bowser was the world's first WebRTC-enabled browser for mobile devices. Bowser was later removed from the Apple App Store and Google Play but was resurrected and released as Open Source together with OpenWebRTC.
