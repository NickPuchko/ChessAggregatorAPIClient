//
//  APIClient.swift
//  BackTest
//
//  Created by Administrator on 12.02.2021.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper

class APIClient {
    
    private lazy var accessHeader: HTTPHeader = HTTPHeader(name: "Authorization", value: "JWT \(KeychainWrapper.standard.string(forKey: "accessToken") ?? "")")
    
    private lazy var contentTypeHeader: HTTPHeader = HTTPHeader(name: "Content-Type", value: "application/json")
    
    private lazy var encoder: JSONEncoder = {
        var result = JSONEncoder()
        result.keyEncodingStrategy = .convertToSnakeCase
        return result
    }()
    
    private lazy var decoder: JSONDecoder = {
        var result = JSONDecoder()
        result.keyDecodingStrategy = .convertFromSnakeCase
        return result
    }()
    
    private func makeURL(path: String) -> URL? {
        var baseComponents = URLComponents()
        baseComponents.scheme = "https"
        baseComponents.host = "c0e68695777c.ngrok.io" // update before use
        baseComponents.path = path
        return baseComponents.url
    }
}

extension APIClient {
    func createUser(user: UserReg, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            let data = try encoder.encode(user)
//            let credentional = URLCredential(user: email, password: password, persistence: .permanent)
            let url = makeURL(path: "/api/v1/auth/users/")!
            let headers: HTTPHeaders = [contentTypeHeader]

            AF.upload(data, to: url, headers: headers)
//                .authenticate(with: credentional)
                .responseString { response in
                print(response.response?.statusCode as Any)
                switch response.result {
                case .success(let json):
                    print(json) 
                    completion(.success(true))
                case .failure(let error):
                    print("User creation request error: \(error)")
                }

            }
        }
        catch let error {
            print("User encoding error: \(error)")
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            let headers: HTTPHeaders = [contentTypeHeader]
            let data = try encoder.encode(Credential(email: email, password: password))
            let url = makeURL(path: "/api/v1/auth/jwt/create/")!
            AF.upload(data, to: url, headers: headers).responseJSON { response in
                print(response.response?.statusCode as Any)
                switch response.result {
                case .success(let tokens):
                    if let dict = tokens as? [String: String] {
                        if let access = dict["access"],
                           let refresh = dict["refresh"] {
                            let savingResult = KeychainWrapper.standard.set(access, forKey: "accessToken")
                                && KeychainWrapper.standard.set(refresh, forKey: "refreshToken")
                            completion(.success(savingResult))
                        }
                    } else {
                        print("Tokens decoding error")
                    }
                case .failure(let error):
                    print("Signing request error: \(error)")
                }
            }
        } catch let error {
            print("Credential encoding error: \(error)")
        }
    }

    func refresh(completion: @escaping () -> Void) {

    }
    
    func requestUser(completion: @escaping (Result<User, Error>) -> Void) {
        let url = makeURL(path: "/api/v1/auth/users/me/")!
        let headers: HTTPHeaders = [accessHeader, contentTypeHeader] // may require validate()
        AF.request(url, headers: headers).responseString { [weak self] response in
            print(response.response?.statusCode as Any)
            switch response.result {
                case .success(let json):
                    do {
                        let data = json.data(using: .utf16)!
                        let parsedUser = try self?.decoder.decode(User.self, from: data)
                        completion(.success(parsedUser!))
                    } catch let error {
                        print("User decoding error: \(error)")
                    }
                case .failure(let error):
                    print("User request error: \(error)")
                }
            }
    }
    
    func requestUser(id: Int, completion: @escaping (Result<UserReg, Error>) -> Void) {
        let url = makeURL(path: "/api/v1/auth/users/\(id)/")!
        AF.request(url, headers: [accessHeader])
            .validate(contentType: ["application/json"])
            .responseString { [weak self] response in
                print(response.response?.statusCode as Any)
                switch response.result {
                case .success(let json):
                    let parsedUser = try! self?.decoder.decode(UserReg.self, from: json.data(using: .utf16)!)
                    completion(.success(parsedUser!))
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
    }
}

extension APIClient {
    func createEvent(event: TournamentReg) {
        do {
            let data = try encoder.encode(event)
            let url = makeURL(path: "/api/v1/tournaments/")!
            let headers: HTTPHeaders = [accessHeader, contentTypeHeader]
            
            AF.upload(data, to: url, headers: headers)
                .response { [weak self] response in
                    switch response.result {
                    case .success(let json):
                        let parsedEvent = try! self?.decoder.decode(TournamentGet.self, from: json!)
                        print(Tournament(eventResponse: parsedEvent!))
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
            }
        } catch let error {
            print("Event encoding error: \(error)")
        }
    }
    
    func getEvents(for status: EventStatus, completion: @escaping (Result<[Tournament], Error>) -> Void) {
        let url = makeURL(path: "/api/v1/tournaments/")!
        AF.request(url, parameters: ["status" : status.rawValue], headers: [accessHeader, contentTypeHeader]).response { [weak self] response in
            print(response.response?.statusCode as Any)
            switch response.result {
            case .success(let json):
                do {
                    let eventList: [TournamentGet] = try self!.decoder.decode([TournamentGet].self, from: json!)
                    let events: [Tournament] = eventList.map { event in
                        Tournament(eventResponse: event)
                    }
                    completion(.success(events))
                } catch let error {
                    print("Event list decoding error occurred: \(error)")
                }
            case .failure(let error):
                print("Get events request error: \(error)")
                completion(.failure(error))
            }
        }
    }
}


