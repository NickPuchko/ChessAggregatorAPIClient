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

    let userReg: UserReg = UserReg(email: "mail228@gmail.com",
            surname: "Dofiga", name: "John", patronymic: nil,
            sex: "Мужчина", birthdate: "1970-01-01", latinName: "Doe John",
            fideId: 24176214, frcId: 1606, isOrganizer: true, password: "KekShrek123")
    

    override func viewDidLoad() {
        super.viewDidLoad()


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
            self?.apiClient.requestUser { (result) in
                switch result {
                case .success(let user):
                    let newUser = UserEdit(name: "John", patronymic: "Ivanovich")
                    self?.apiClient.editUser(user: user, newuser: newUser, completion: { (result) in
                        switch result {
                        case .success(let editedUser):
                            print(editedUser)
                        case .failure(let error):
                            print(error)
                        }
                    })
                case .failure(let error):
                    print(error)
                }
            }
        }
//            self?.apiClient.getEvents(for: .forthcoming) { result in
//                switch result {
//                case .success(let events):
//                    print(events)
////                    self?.apiClient.addParticipant(eventID: event.id, completion: { (result) in
////                        print(result)
////                    })
////                    self?.apiClient.getParticipants(id: event.id) { (result) in
////                        switch result {
////                        case .success(let participants):
////                            print(participants)
////                        case .failure(let error):
////                            print(error)
////                        }
////                    }
//                case .failure(let error):
//                    print("Some get events error occurred: \(error)")
//                }
//            }
//        }
//            let event = TournamentReg(name: "Moscow open \(arc4random())",
//                    location: "Москва",
//                    openDate: "2021-03-08", closeDate: "2021-03-10",
//                    url: "https://git-scm.com/docs/gitignore", prizeFund: 100_000, fee: 5_000, tours: 9,
//                    ratingType: "FIDE", mode: "Блиц",
//                    minutes: 5, seconds: 0, increment: 0)
//            self!.apiClient.createEvent(event: event)
        

//        apiClient.createUser(user: userReg) { result in
//            switch result {
//            case .success(_):
//                print("User has been created")
//            case .failure(_):
//                print("Creation error")
//            }
//        }
    }
}


