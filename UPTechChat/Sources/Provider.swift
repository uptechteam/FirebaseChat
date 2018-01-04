//
//  Provider.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import Foundation
import ObjectMapper
import FirebaseDatabase
import RxSwift

enum ProviderError: Error {
    case parsingFailed
}

struct FirebaseEntity<Model> {
    let identifier: String
    let model: Model
}

class Provider<Model: ImmutableMappable> {
    private let reference: DatabaseReference

    init(reference: DatabaseReference) {
        self.reference = reference
    }

    func fetch() -> Observable<[FirebaseEntity<Model>]> {
        return Observable.create { observer in
            let handle = self.reference.observe(DataEventType.value) { (snapshot) in
                guard let json = snapshot.value as? [String: Any] else {
                    observer.onNext([])
                    return
                }

                do {
                    let mapper = Mapper<Model>()
                    let firebaseModels = try json
                        .map { (key, value) -> FirebaseEntity<Model> in
                            let model = try mapper.map(JSONObject: value)
                            return FirebaseEntity(identifier: key, model: model)
                        }

                    observer.onNext(firebaseModels)
                } catch {
                    observer.onError(error)
                }
            }

            return Disposables.create {
                self.reference.removeObserver(withHandle: handle)
            }
        }
    }

    func post(model: Model) -> Observable<Void> {
        return Observable.create { observer in
            let mapper = Mapper<Model>()
            let json = mapper.toJSON(model)
            self.reference.childByAutoId().setValue(json, withCompletionBlock: { (error, _) in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            })

            return Disposables.create()
        }
    }
}
