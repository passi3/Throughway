//
//  CreatePostFeature.swift
//  Throughway
//
//  Created by passi on 5/11/26.
//

import Foundation

enum CreatePostFeature {

    struct State: BaseState {
        var postId: String? = nil
        var existingFilePaths: [String] = []
        var country: String? = nil
        var category: String? = nil
        var title: String = ""
        var content: String = ""
        var selectedImageData: [Data] = []
        var latitude: Double? = nil
        var longitude: Double? = nil
        var isSubmitting: Bool = false
        var error: String? = nil
        var didFinish: Bool = false
    }

    enum Intent: BaseIntent {
        case countryChanged(String)
        case categoryChanged(String)
        case titleChanged(String)
        case contentChanged(String)
        case photosSelected([Data])
        case removePhoto(Int)
        case removeExistingPhoto(Int)
        case submit
    }
}
