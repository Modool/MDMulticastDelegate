
# MDMulticastDelegate

[![](https://img.shields.io/travis/rust-lang/rust.svg?style=flat)](https://github.com/Modool)
[![](https://img.shields.io/badge/language-Object--C-1eafeb.svg?style=flat)](https://developer.apple.com/Objective-C)
[![](https://img.shields.io/badge/license-MIT-353535.svg?style=flat)](https://developer.apple.com/iphone/index.action)
[![](https://img.shields.io/badge/platform-iOS-lightgrey.svg?style=flat)](https://github.com/Modool)
[![](https://img.shields.io/badge/QQ群-662988771-red.svg)](http://wpa.qq.com/msgrd?v=3&uin=662988771&site=qq&menu=yes)

## Introduction

- This is multicast delegate.
- Support multiple threads and genericity.


- Add delegate

```
- (void)addDelegate:(DelegateType)delegate;
- (void)addDelegate:(DelegateType)delegate delegateQueue:(dispatch_queue_t)delegateQueue;
```

- Remove delegate

```
- (void)removeAllDelegates;
- (void)removeDelegate:(DelegateType)delegate;
- (void)removeDelegate:(DelegateType)delegate delegateQueue:(nullable dispatch_queue_t)delegateQueue;
```

## How To Get Started

* Download `MDMulticastDelegate ` and try run example app

## Installation


* Installation with CocoaPods

```
source 'https://github.com/Modool/cocoapods-specs.git'
platform :ios, '8.0'

target 'TargetName' do
pod 'MDMulticastDelegate'
end

```

* Installation with Carthage

```
github "Modool/MDMulticastDelegate"
```

* Manual Import

```
drag “MDMulticastDelegate” directory into your project

```


## Requirements
- Requires ARC

## Architecture

* `MDMulticastDelegate`

## Usage

* Demo FYI

## Update History

* 2017.12.27 Add README and adjust project class name.

## License
`MDMulticastDelegate ` is released under the MIT license. See LICENSE for details.


## Communication

<img src="https://github.com/Modool/Resources/blob/master/images/social/qq_300.png?raw=true" width=200><img style="margin:0px 50px 0px 50px" src="https://github.com/Modool/Resources/blob/master/images/social/wechat_300.png?raw=true" width=200><img src="https://github.com/Modool/Resources/blob/master/images/social/github_300.png?raw=true" width=200>