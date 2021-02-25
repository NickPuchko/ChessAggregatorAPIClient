//
//  ViewController.swift
//  alamofire
//
//  Created by Administrator on 29.01.2021.
//
//

import UIKit
import Foundation


class ViewController: UIViewController {
    
    var apiClient = APIClient()

    let userReg: UserReg = UserReg(
        profile: Profile(
            surname: "Doe", name: "John", patronymic: nil,
            sex: Sex.male.rawValue, birthdate: "1970-01-01", latinName: nil,
            fideId: 24176214, frcId: 1606),
        email: "mail1187110587@gmail.com", isOrganizer: true, password: "python300")
    
    var event: Tournament?


    override func viewDidLoad() {
        super.viewDidLoad()

        let semaphore = DispatchSemaphore(value: 1)
        semaphore.wait()
        apiClient.signIn(email: userReg.email, password: userReg.password) { (result) in
            print(result)
            semaphore.signal()
        }
        
        view.backgroundColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
        
//        let queue = DispatchQueue(label: "NetworkQueue", qos: .utility)
//        let group = DispatchGroup()
//        group.enter()
//        queue.sync {
//            apiClient.signIn(email: userReg.email, password: userReg.password) { result in
//                switch result {
//                case .success(_):
//                    print("Signed successfully!")
//                case .failure(let error):
//                    print("Signing error: \(error)")
//                }
//                group.leave()
//            }
//        }
        
        
//        group.notify(queue: .global(qos: .utility)) { [weak self] in
//            self?.apiClient.requestUser(completion: { (result) in
//                print(result)
//            })
//            group.enter()
//            let event = TournamentReg(name: "Moscow open \(arc4random())",
//                    location: "Москва",
//                    openDate: "2021-03-08", closeDate: "2021-03-10",
//                    url: "https://git-scm.com/docs/gitignore", prizeFund: 100_000, fee: 5_000, tours: 9,
//                    ratingType: "FIDE", mode: "Блиц",
//                    minutes: 5, seconds: 0, increment: 0)
//            self?.apiClient.createEvent(event: event) { [weak self] (result) in
//                switch result {
//                case .failure(let error):
//                    print(error)
//                case .success(let eventGet):
//                    self?.event = Tournament(eventResponse: eventGet)
//                    group.leave()
//                }
//            }
//        }
        
        
//        group.notify(queue: .global()) { [weak self] in
//            let participant = ManualParicipant(email: "toppidor@gmail.com", surname: "Burov", name: "Pidor", patronymic: nil, sex: Sex.male.rawValue, birthdate: "1488-01-01", latinName: nil, fideId: 24679992, frcId: nil)
//            self?.apiClient.addParticipant(eventID: self?.event?.id ?? 4, participant: participant, completion: { (result) in
//                print(result)
//            })
//        }
        
        
        
//            self?.apiClient.addParticipant(eventID: 2, participant: participant, completion: { (result) in
//                switch result {
//                case .success(let user):
//                    print(user)
//                case .failure(let error):
//                    print(error)
//                }
//            })
            
            
//            self?.apiClient.getEvents(for: .forthcoming, completion: { (result) in
//                switch result {
//                case .success(let events):
//                    print(events)
//                case .failure(let error):
//                    print(error)
//                }
//            })
//            self?.apiClient.requestUser { (result) in
//                switch result {
//                case .success(let user):
//                    let newUser = UserEdit(name: "John", patronymic: "Ivanovich")
//                    self?.apiClient.editUser(user: user, newuser: newUser, completion: { (result) in
//                        switch result {
//                        case .success(let editedUser):
//                            print(editedUser)
//                        case .failure(let error):
//                            print(error)
//                        }
//                    })
//                case .failure(let error):
//                    print(error)
//                }
//            }
        
        
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


