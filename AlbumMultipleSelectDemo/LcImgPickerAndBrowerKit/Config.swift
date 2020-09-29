//
//  Config.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import Foundation
import UIKit

/// 是否开启print信息打印
public var kPhotoAlbumEnableDebugOn = false

/// 导航条高度（不包含状态栏高度）默认44
public var kNavigationHeight: CGFloat = 44

let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width
let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height
let kIsiPhoneX: Bool = UIScreen.instancesRespond(to: #selector(getter: UIScreen.currentMode)) && UIScreen.main.currentMode!.size == CGSize(width: 1125, height: 2436)
let kStatusBarHeight: CGFloat = kIsiPhoneX ? 44 : 20
let kNavigationTotalHeight: CGFloat = kStatusBarHeight + kNavigationHeight
let kHomeBarHeight: CGFloat = kIsiPhoneX ? 34 : 0
