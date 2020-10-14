//
//  NSProgressIndicator+SetTintColor.swift
//  RecognizingSpeechInLiveAudio_macOS
//
//  Created by HIROKI IKEUCHI on 2020/10/14.
//  Copyright © 2020 hikeuchi. All rights reserved.
//

import Cocoa

extension NSProgressIndicator {
    // [berkcebi/progress\-indicator\-spinning\-color\.swift](https://gist.github.com/berkcebi/e0f09d5ea3b95ad3230b0995435ec151)
    func set(tintColor: NSColor) {
        guard let adjustedTintColor = tintColor.usingColorSpace(.deviceRGB) else {
            contentFilters = []

            return
        }

        let tintColorRedComponent = adjustedTintColor.redComponent
        let tintColorGreenComponent = adjustedTintColor.greenComponent
        let tintColorBlueComponent = adjustedTintColor.blueComponent

        let tintColorMinComponentsVector = CIVector(x: tintColorRedComponent, y: tintColorGreenComponent, z: tintColorBlueComponent, w: 0.0)
        let tintColorMaxComponentsVector = CIVector(x: tintColorRedComponent, y: tintColorGreenComponent, z: tintColorBlueComponent, w: 1.0)

        let colorClampFilter = CIFilter(name: "CIColorClamp")!
        colorClampFilter.setDefaults()
        colorClampFilter.setValue(tintColorMinComponentsVector, forKey: "inputMinComponents")
        colorClampFilter.setValue(tintColorMaxComponentsVector, forKey: "inputMaxComponents")

        contentFilters = [colorClampFilter]
    }
}
