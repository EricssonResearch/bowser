Bowser
======

A WebRTC browser for iOS developed in the open.

## Extension of UIWebView
Bowser is based on the official `UIWebView` provided by the platform and the [WebRTC](http://www.w3.org/2011/04/webrtc/) API's are implemented with JavaScript that is injected into web pages as they load, the injected JavaScript code is using remote procedure calls to control the [OpenWebRTC](/EricssonResearch/openwebrtc) backend.

The plan is to move to the `WKWebView`, introduced in iOS 8, as soon as possible.  

## Video
Mobile Safari on iPhone displays `<video>` elements only in fullscreen. This severely limits the UI of your apps, especially when designing video communication apps using WebRTC. Bowser goes beyond that and allows you to fully customise and manipulate `<video>` elements using CSS and JavaScript.
