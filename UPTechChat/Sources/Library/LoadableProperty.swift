//
//  LoadableProperty.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/13/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import ReactiveSwift
import Result

struct LoadableProperty<Value, Error: Swift.Error> {
    let property: Property<Value?>
    let isLoading: Property<Bool>
    let errors: Signal<Error, NoError>
}
