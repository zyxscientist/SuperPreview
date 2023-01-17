//
//  ImageDebug.swift
//  SuperPreview
//
//  Created by admin on 2023/1/17.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import Foundation
import SwiftUI

// 检查图像资源规范，例如当Image("")时，会报错并且指向对应页面

#if DEBUG
    extension Image {
        init(_ str: String) {
            guard let img = UIImage(named: str) else {
                print(str)
                fatalError("found an image that doesn't exist, see: https://stackoverflow.com/a/63006278/11161266")
            }
            self.init(uiImage: img)
        }
        init(systemName sys: String) {
            guard let img = UIImage(systemName: sys) else {
                print(sys)
                fatalError("found an image that doesn't exist, see: https://stackoverflow.com/a/63006278/11161266")
            }
            self.init(uiImage: img)
        }
        
    }
#endif
