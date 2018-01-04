//
//  Provider.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import Foundation
import FirebaseDatabase
import RxSwift

enum ProviderError: Error {
    case parsingFailed
}

class Provider<Model: FirebaseSerializable> {
    private let reference: DatabaseReference

    init(reference: DatabaseReference) {
        self.reference = reference
    }

    func fetch() -> Observable<[Model]> {
        return Observable.create { observer in
            let handle = self.reference.observe(DataEventType.value) { (snapshot) in
                guard let json = snapshot.value as? [String: Any] else {
                    observer.onError(ProviderError.parsingFailed)
                    return
                }

                do {
                    let models = try json
                        .map { (key, value) -> Model in
                            guard
                                let modelJson = value as? [String: Any],
                                let model = Model(identifier: key, json: modelJson)
                            else {
                                throw ProviderError.parsingFailed
                            }

                            return model
                        }

                    observer.onNext(models)
                } catch {
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                self.reference.removeObserver(withHandle: handle)
            }
        }
    }
}
