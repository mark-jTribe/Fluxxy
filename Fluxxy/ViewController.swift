//
//  ViewController.swift
//  Fluxxy
//
//  Created by Mark Robinson on 5/09/2015.
//  Copyright © 2015 mrrobinson. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    var initialVal: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialVal = Int(numberLabel.text!)!
        let numberStore = NumberStore()
        
        stepper.rx_controlEvents(UIControlEvents.TouchUpInside)
            .doOn(next: {
                let newTemp = Int(self.stepper.value)
                self.numberLabel.text = "\(newTemp)"
            })
            .debounce(0.5, scheduler: MainScheduler.sharedInstance)
            .subscribeNext({ self.setTemperature(self.stepper) })
        
        numberStore.numberAsObservable().subscribe { (event: Event<Int>) in
            if let newTemp = event.value {
                NSLog("new temp is: %i", newTemp)
                self.numberLabel.text = "\(newTemp)"
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setTemperature(stepper: UIStepper) {
        NumberActionsCreator.setTemperature(Int(stepper.value))
    }
}

struct NumberStore {
    let v: Variable<Int> = Variable.init(20)
    init() {
        Dispatcher.toObservable(NumberAction.self).subscribeNext { action in
            if let change = action.data["change"] as? Int {
                let num = self.v.value + change
                self.v.sendNext(num)
            }
            
            if let temp = action.data["temp"] as? Int {
                self.v.sendNext(temp)
            }
        }
    }
    
    func numberAsObservable() -> Observable<Int> {
        return v.asObservable()
    }
}

struct Dispatcher {
    private static let dispatcher = PublishSubject<Action>()
    
    static func dispatch(action: Action) {
        dispatcher.on(.Next(action))
    }
    
    static func toObservable<T : Action>(actionType: T.Type) -> Observable<Action> {
        return dispatcher.asObservable().filter( { (nextAction: Action) in nextAction is T })
    }
}

struct NumberActionsCreator {
    static func increase() {
        let action = NumberAction(type: .Increase, data: ["change" : 1])
        Dispatcher.dispatch(action)
    }
    
    static func setTemperature(temp: Int) {
        let action = NumberAction(type: .SetTemperature, data: ["temp" : temp])
        Dispatcher.dispatch(action)
    }
    
    static func decrease() {
        let action = NumberAction(type: .Decrease, data: ["change" : -1])
        Dispatcher.dispatch(action)
    }
}

struct NumberAction : Action {
    let type: ActionType
    let data: Dictionary <String, AnyObject>
    
    init(type: NumberActionType, data: Dictionary <String, Int>) {
        self.type = type
        self.data = data
    }
}

enum NumberActionType : ActionType {
    case Increase, Decrease, SetTemperature
}

protocol ActionType {
//    var description: String { get }
}

protocol Action {
    var type: ActionType { get }
    var data: Dictionary <String, AnyObject> { get }
}
