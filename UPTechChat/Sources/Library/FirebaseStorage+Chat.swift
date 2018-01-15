//
//  FirebaseStorage+ReactiveSwift.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/15/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import FirebaseStorage
import ReactiveSwift

enum FirebaseUploadError: Swift.Error {
    case unknown
    case wrapped(Swift.Error)
}

enum FirebaseUploadingState {
    case uploading(progress: Double)
    case completed(metadata: StorageMetadata)
}

extension Reactive where Base: StorageReference {
    func putData(_ data: Data, metadata: StorageMetadata?) -> SignalProducer<FirebaseUploadingState, FirebaseUploadError> {
        return SignalProducer { observer, lifetime in
            let task = self.base.putData(data, metadata: metadata) { metadata, error in
                if let error = error {
                    observer.send(error: .wrapped(error))
                } else if let metadata = metadata {
                    observer.send(value: .completed(metadata: metadata))
                    observer.sendCompleted()
                } else {
                    observer.send(error: FirebaseUploadError.unknown)
                }
            }

            let handle = task.observe(.progress) { snapshot in
                if let progress = snapshot.progress?.fractionCompleted {
                    observer.send(value: .uploading(progress))
                }
            }

            lifetime.observeEnded {
                task.removeObserver(withHandle: handle)
                task.cancel()
            }
        }
    }
}
