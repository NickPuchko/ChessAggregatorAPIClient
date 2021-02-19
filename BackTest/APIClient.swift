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
    
//    private lazy var refreshToken: String = KeychainWrapper.standard.string(forKey: "refreshToken") ?? ""

    
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
        baseComponents.host = "a35b8b46c4af.ngrok.io" // MARK: update before use
        baseComponents.path = path
        return baseComponents.url
    }
}

extension APIClient {
    func createUser(user: UserReg, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            let data = try encoder.encode(user)
            let url = makeURL(path: "/api/v1/auth/users/")!
            let headers: HTTPHeaders = [contentTypeHeader]

            AF.upload(data, to: url, headers: headers)
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
        // TODO: alamofire retrier
    }
    
    func requestUser(completion: @escaping (Result<User, Error>) -> Void) {
        let url = makeURL(path: "/api/v1/auth/users/me/")!
        let headers: HTTPHeaders = [accessHeader, contentTypeHeader] // may require validate()
        AF.request(url, headers: headers).responseString { [weak self] response in
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
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(RequestError.networkError))
                return
            }
            print(statusCode)
//            switch statusCode {
//            case 401:
//                self?.refresh {
//                    statusCode = 200
//                }
//            case 200..<300:
                switch response.result {
                case .success(let json):
                    do {
                        guard let jsonUnwrapped = json else {
                            completion(.failure(RequestError.decodingError))
                            return
                        }
                        let eventList: [TournamentGet]? = try self?.decoder.decode([TournamentGet].self, from: jsonUnwrapped)
                        guard let eventsUnwrapped = eventList else {
                            completion(.failure(RequestError.decodingError))
                            return
                        }
                        let events: [Tournament] = eventsUnwrapped.map { event in
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
//            default:
//                completion(.failure(RequestError.networkError))
//            }

        }
    }
}

extension APIClient {
    func getParticipants(id: Int, completion: @escaping (Result<[Participant], Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/tournaments/\(id)/participants/") else {
            completion(.failure(RequestError.urlError))
            return
        }
        
        AF.request(url, headers: [accessHeader, contentTypeHeader]).response { [weak self] response in
            switch response.result {
            case .success(let json):
                guard let jsonUnwrapped = json else {
                    completion(.failure(RequestError.networkError))
                    return
                }
                do {
                    let participantsGet: [Participant]? = (try self?.decoder.decode([Participant].self, from: jsonUnwrapped))
                    guard let participants = participantsGet else {
                        completion(.failure(RequestError.decodingError))
                        return
                    }
                    completion(.success(participants))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateParticipantStatus(eventID: Int, participantID: Int, status: ParticipantStatus, completion: @escaping (Result<Participant, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/tournaments/\(eventID)/participants/\(participantID)/") else {
            completion(.failure(RequestError.urlError))
            return
        }
        do {
            let patch = try self.encoder.encode(["status" : status.rawValue])
            AF.upload(patch,
                      to: url,
                      method: .patch,
                      headers: [accessHeader, contentTypeHeader])
                .response { [weak self] response in
                switch response.result {
                case .success(let json):
                    guard let jsonUnwrapped = json else {
                        completion(.failure(RequestError.networkError))
                        return
                    }
                    do {
                        guard let updatedParticipant = try self?.decoder.decode(Participant.self, from: jsonUnwrapped) else {
                            completion(.failure(RequestError.decodingError))
                            return
                        }
                        completion(.success(updatedParticipant))
                    } catch let error {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch let error {
            completion(.failure(error))
            return
        }
    }
    
    func addParticipant(eventID: Int, user: UserGet, completion: @escaping (Result<Participant, Error>) -> Void) {
        //TODO: manual addition
    }
    
    func addParticipant(eventID: Int, completion: @escaping (Result<Participant, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/tournaments/\(eventID)/participants/") else {
            completion(.failure(RequestError.urlError))
            return
        }
        AF.request(url,
                   method: .post,
                   headers: [accessHeader, contentTypeHeader])
            .response { [weak self] response in
                switch response.result {
                case .success(let data):
                    guard let json = data else {
                        completion(.failure(RequestError.networkError))
                        return
                    }
                    do {
                        guard let participant = try self?.decoder.decode(Participant.self, from: json) else {
                            completion(.failure(RequestError.decodingError))
                            return
                        }
                        completion(.success(participant))
                    } catch let error {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}



