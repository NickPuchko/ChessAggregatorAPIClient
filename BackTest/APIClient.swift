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
        baseComponents.host = "vast-crag-23566.herokuapp.com"
        baseComponents.path = path
        return baseComponents.url
    }
}

extension APIClient {
    func createUser(user: UserReg, completion: @escaping (Result<UserGet, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/auth/users/") else {
            completion(.failure(RequestError.url))
            return
        }
        do {
            let data = try encoder.encode(user)
            AF.upload(data,
                      to: url,
                      headers: [contentTypeHeader])
                .response { [weak self] response in
                switch response.result {
                case .success(let json):
                    guard let status = response.response?.statusCode,
                          let jsonUnwrapped = json else {
                        completion(.failure(RequestError.network))
                        return
                    }
                    print(status)
                    switch status {
                    case 400:
                        completion(.failure(RequestError.emailInUse))
                        return
                    case 500..<600:
                        completion(.failure(RequestError.serverInternal))
                        return
                    case 201:
                        do {
                            guard let userGet = try self?.decoder.decode(UserGet.self, from: jsonUnwrapped) else {
                                completion(.failure(RequestError.decoding))
                                return
                            }
                            completion(.success(userGet))
                        } catch let error {
                            completion(.failure(error))
                        }
                    default:
                        completion(.failure(RequestError.network))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        catch let error {
            completion(.failure(error))
        }
    }
    
    func editUser(user: User, newuser: UserEdit, completion: @escaping (Result<UserGet, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/auth/users/\(user.id)/") else {
            completion(.failure(RequestError.url))
            return
        }
        do {
            let patch = try encoder.encode(newuser)
            AF.upload(patch,
                      to: url,
                      method: .patch,
                      headers: [accessHeader, contentTypeHeader])
                .response { [weak self] response in
                    switch response.result {
                    case .success(let json):
                        guard let jsonUnwrapped = json else {
                            completion(.failure(RequestError.network))
                            return
                        }
                        do {
                            guard let editedUser = try self?.decoder.decode(UserGet.self, from: jsonUnwrapped) else {
                                completion(.failure(RequestError.decoding))
                                return
                            }
                            completion(.success(editedUser))
                        } catch let error {
                            completion(.failure(error))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
        } catch let error {
            completion(.failure(error))
        }
    }
    
    // TODO: fix response & url
    func signIn(email: String, password: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/auth/jwt/create/") else {
            completion(.failure(RequestError.url))
            return
        }
        
        do {
            let headers: HTTPHeaders = [contentTypeHeader]
            let data = try encoder.encode(Credential(email: email, password: password))
            AF.upload(data,
                      to: url,
                      headers: headers)
                .responseJSON { response in
                switch response.result {
                case .success(let tokens):
                    guard let dict = tokens as? [String: String] else {
                        completion(.failure(RequestError.network))
                        return
                    }
                    guard let access = dict["access"],
                          let refresh = dict["refresh"] else {
                        completion(.failure(RequestError.decoding))
                        return
                    }
                    let savingResult = KeychainWrapper.standard.set(access, forKey: "accessToken")
                            && KeychainWrapper.standard.set(refresh, forKey: "refreshToken")
                    completion(.success(savingResult))
                    return
                case .failure(let error):
                    completion(.failure(error))
                    return
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }

    func refresh(completion: @escaping (Result<Bool, Error>) -> Void) {
        // TODO: alamofire retrier
        guard let url = makeURL(path: "/api/v1/auth/jwt/refresh/") else {
            completion(.failure(RequestError.url))
            return
        }
        do {
            guard let accessToken = KeychainWrapper.standard.string(forKey: "accessToken") else {
                completion(.failure(RequestError.keychain))
                return
            }
            let access = try encoder.encode(accessToken)
            AF.upload(access,
                      to: url,
                      headers: [contentTypeHeader])
                .responseJSON { response in
                switch response.result {
                case .success(let json):
                    guard let tokenDict = json as? [String: String],
                          let access = tokenDict["access"] else {
                        completion(.failure(RequestError.decoding))
                        return
                    }
                    completion(.success(KeychainWrapper.standard.set(access, forKey: "accessToken")))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch let error {
            completion(.failure(error))
            return
        }
    }
    
    func requestUser(completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/auth/users/me/") else {
            completion(.failure(RequestError.url))
            return
        }
        let headers: HTTPHeaders = [accessHeader, contentTypeHeader] // may require validate()
        AF.request(url,
                   headers: headers)
            .response { [weak self] response in
            switch response.result {
                case .success(let json):
                    do {
                        guard let jsonUnwrapped = json else {
                            completion(.failure(RequestError.network))
                            return
                        }

                        guard let parsedUser = try self?.decoder.decode(UserGet.self, from: jsonUnwrapped) else {
                            completion(.failure(RequestError.decoding))
                            return
                        }
                        completion(.success(User(userResponse: parsedUser)))
                    } catch let error {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // TODO: fix response
    func requestUser(id: Int, completion: @escaping (Result<UserGet, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/auth/users/\(id)/") else {
            completion(.failure(RequestError.url))
            return
        }
        AF.request(url,
                   headers: [accessHeader, contentTypeHeader])
            .response { [weak self] response in
                switch response.result {
                case .success(let json):
                    do {
                        guard let jsonUnwrapped = json else {
                            completion(.failure(RequestError.network))
                            return
                        }
                        guard let parsedUser = try self?.decoder.decode(UserGet.self, from: jsonUnwrapped) else {
                            completion(.failure(RequestError.decoding))
                            return
                        }
                        completion(.success(parsedUser))
                    } catch let error {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}

extension APIClient {
    func createEvent(event: TournamentReg, completion: @escaping (Result<TournamentGet, Error>) -> Void) {
        do {
            let data = try encoder.encode(event)
            guard let url = makeURL(path: "/api/v1/tournaments/") else {
                completion(.failure(RequestError.url))
                return
            }
            
            AF.upload(data,
                      to: url,
                      headers: [accessHeader, contentTypeHeader])
                .response { [weak self] response in
                switch response.result {
                case .success(let data):
                    guard let json = data else {
                        completion(.failure(RequestError.network))
                        return
                    }
                    do {
                        guard let parsedEvent = try self?.decoder.decode(TournamentGet.self, from: json) else {
                            completion(.failure(RequestError.decoding))
                            return
                        }
                        completion(.success(parsedEvent))
                    } catch let error {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func getEvents(status: EventStatus? = nil, completion: @escaping (Result<[Tournament], Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/tournaments/") else {
            completion(.failure(RequestError.url))
            return
        }
        var parameters: Parameters?
        if let status = status {
            parameters = ["status" : status.rawValue]
        }
        AF.request(url,
                   parameters: parameters,
                   headers: [accessHeader, contentTypeHeader])
            .response { [weak self] response in
            switch response.result {
            case .success(let json):
                do {
                    guard let jsonUnwrapped = json else {
                        completion(.failure(RequestError.decoding))
                        return
                    }
                    let eventList: [TournamentGet]? = try self?.decoder.decode([TournamentGet].self, from: jsonUnwrapped)
                    guard let eventsUnwrapped = eventList else {
                        completion(.failure(RequestError.decoding))
                        return
                    }
                    let events: [Tournament] = eventsUnwrapped.map { event in
                        Tournament(eventResponse: event)
                    }
                    completion(.success(events))
                } catch let error {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }


        }
    }
}

extension APIClient {
    func getParticipants(id: Int, completion: @escaping (Result<[Participant], Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/tournaments/\(id)/participants/") else {
            completion(.failure(RequestError.url))
            return
        }
        
        AF.request(url,
                   headers: [accessHeader, contentTypeHeader])
            .response { [weak self] response in
            switch response.result {
            case .success(let json):
                guard let jsonUnwrapped = json else {
                    completion(.failure(RequestError.network))
                    return
                }
                do {
                    guard let participants = (try self?.decoder.decode([Participant].self, from: jsonUnwrapped)) else {
                        completion(.failure(RequestError.decoding))
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
            completion(.failure(RequestError.url))
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
                        completion(.failure(RequestError.network))
                        return
                    }
                    do {
                        guard let updatedParticipant = try self?.decoder.decode(Participant.self, from: jsonUnwrapped) else {
                            completion(.failure(RequestError.decoding))
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
    
    func addParticipant(eventID: Int, participant: ManualParicipant, completion: @escaping (Result<Participant, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/tournaments/\(eventID)/anonymous_participants/") else {
            completion(.failure(RequestError.network))
            return
        }
        do {
            let data = try encoder.encode(participant)
            AF.upload(data,
                      to: url,
                      method: .post,
                      headers: [accessHeader, contentTypeHeader])
                .response { [weak self] response in
                    switch response.result {
                    case .success(let data):
                        do {
                            guard let json = data else {
                                completion(.failure(RequestError.network))
                                return
                            }
                            guard let player = try self?.decoder.decode(Participant.self, from: json) else {
                                completion(.failure(RequestError.decoding))
                                return
                            }
                            completion(.success(player))
                        } catch let error {
                            completion(.failure(error))
                            return
                        }
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    }
                }
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func addParticipant(eventID: Int, completion: @escaping (Result<Participant, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/tournaments/\(eventID)/participants/") else {
            completion(.failure(RequestError.url))
            return
        }
        AF.request(url,
                   method: .post,
                   headers: [accessHeader, contentTypeHeader])
            .response { [weak self] response in
                switch response.result {
                case .success(let data):
                    guard let json = data else {
                        completion(.failure(RequestError.network))
                        return
                    }
                    do {
                        guard let participant = try self?.decoder.decode(Participant.self, from: json) else {
                            completion(.failure(RequestError.decoding))
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
