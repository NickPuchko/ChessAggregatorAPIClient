//
//  ViewController.swift
//  alamofire
//
//  Created by Administrator on 29.01.2021.
//
//

import UIKit
import Foundation
import SwiftKeychainWrapper


class ViewController: UIViewController {
    
    var apiClient = APIClient()

    let userReg: UserReg = UserReg(
        profile: Profile(
            surname: "Doe", name: "Ivan", patronymic: nil,
            sex: Sex.male.rawValue, birthdate: "1970-01-01", latinName: nil,
            fideId: 24176214, frcId: 1606),
        email: "mail114@gmail.com", isOrganizer: true, password: "python300")
    
    var newEvent: TournamentReg?


    override func viewDidLoad() {
        super.viewDidLoad()



        newEvent = TournamentReg(name: "Moscow open \(arc4random())",
                location: "Москва",
                openDate: "2021-03-08", closeDate: "2021-03-10",
                url: "https://git-scm.com/docs/gitignore", prizeFund: 100_000, fee: 5_000, tours: 9,
                ratingType: "FIDE", mode: "Блиц",
                minutes: 5, seconds: 0, increment: 0)
		apiClient.signIn(email: userReg.email, password: userReg.password) { result in
			switch result {
			case .failure(let error):
				print(error.localizedDescription)
			case .success(let isTokenSaved):
				self.apiClient.createEvent(event: self.newEvent!) { res in
					print(res)
				}
			}
		}

    }
	
}


