//
//  ViewController.swift
//  alamofire
//
//  Created by Administrator on 29.01.2021.
//
//

import UIKit
import Alamofire
import Foundation
import SwiftKeychainWrapper


class ViewController: UIViewController {
    
    var apiClient = APIClient()

    let userReg: UserReg = UserReg(email: "mail1@gmail.com",
            surname: "Doe", name: "John", patronymic: nil,
            sex: "Мужчина", birthdate: "1970-01-01", latinName: "Doe John",
            fideID: 24176214, frcID: 1606, isOrganizer: true, password: "KekShrek123")
    

    //KeychainWrapper.standard.string(forKey: "accessToken")!


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white


//        apiClient.createUser(user: userReg) { result in
//            print(result)
//        }
        let queue = DispatchQueue(label: "NetworkQueue", qos: .utility)
        let group = DispatchGroup()
        group.enter()
        queue.sync {
            apiClient.signIn(email: userReg.email, password: userReg.password) { result in
                switch result {
                case .success(_):
                    print("Signed successfully!")
                case .failure(let error):
                    print("Signing error: \(error)")
                }
                group.leave()
            }
        }
        group.notify(queue: .global(qos: .utility)) { [weak self] in
            self!.apiClient.getEvents(for: .forthcoming) { result in
                switch result {
                case .success(let events):
                    print(events)
                case .failure(let error):
                    print("Some get events error occurred: \(error)")
                }
            }
//            let event = TournamentReg(name: "Moscow open \(arc4random())",
//                    location: "Москва",
//                    openDate: "2021-03-08", closeDate: "2021-03-10",
//                    url: "https://git-scm.com/docs/gitignore", prizeFund: 100_000, fee: 5_000, tours: 9,
//                    ratingType: "FIDE", mode: "Блиц",
//                    minutes: 5, seconds: 0, increment: 0)
//            self!.apiClient.createEvent(event: event)
        }

//        apiClient.createUser(user: user, email: user.email, password: password) { result in
//            switch result {
//            case .success(_):
//                print("User has been created")
//            case .failure(_):
//                print("Creation error")
//            }
    }
}

