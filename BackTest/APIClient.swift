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
    var request: Alamofire.Request?
    
    private lazy var sessionManager: Session = {
        var config = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 30
        return Session(configuration: config, interceptor: self)
    }()
    
    private let retryLimit: Int = 3
    
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
            request?.cancel()
            request = sessionManager.upload(data,
                      to: url)
                .validate()
                .response { [weak self] response in
                switch response.result {
                case .success(let json):
                    guard let jsonUnwrapped = json else {
                        completion(.failure(RequestError.network))
                        return
                    }
                    
                    do {
                        guard let userGet = try self?.decoder.decode(UserGet.self, from: jsonUnwrapped) else {
                            completion(.failure(RequestError.decoding))
                            return
                        }
                        completion(.success(userGet))
                    } catch let error {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    guard let status = response.response?.statusCode else {
                        completion(.failure(error))
                        return
                    }
                    switch status {
                    case 400:
                        completion(.failure(RequestError.emailInUse))
                        return
                    case 500..<600:
                        completion(.failure(RequestError.serverInternal))
                        return
                    default:
                        completion(.failure(error))
                        return
                    }
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
            request?.cancel()
            request = sessionManager.upload(patch,
                      to: url,
                      method: .patch)
                .validate()
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
            let data = try encoder.encode(Credential(email: email, password: password))
            request?.cancel()
            request = sessionManager.upload(data, to: url)
                .validate()
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
    
    func requestUser(completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/auth/users/me/") else {
            completion(.failure(RequestError.url))
            return
        }
        request?.cancel()
        request = sessionManager.request(url)
            .validate()
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
        request?.cancel()
        request = sessionManager.request(url)
            .validate()
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
            request?.cancel()
            request = sessionManager.upload(data, to: url)
                .validate()
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
        
        request?.cancel()
        request = sessionManager.request(url, parameters: parameters)
            .validate()
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
        
        request?.cancel()
        request = sessionManager.request(url)
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
            request?.cancel()
            request = sessionManager.upload(patch, to: url, method: .patch)
                .validate()
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
            request?.cancel()
            request = sessionManager.upload(data, to: url)
                .validate()
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

        request?.cancel()
        request = sessionManager.request(url, method: .post)
            .validate()
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


extension APIClient: RequestInterceptor {
    func refreshToken(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = makeURL(path: "/api/v1/auth/jwt/refresh/") else {
            completion(.failure(RequestError.url))
            return
        }
        do {
            guard let refreshToken = KeychainWrapper.standard.string(forKey: "refreshToken") else {
                completion(.failure(RequestError.keychain))
                return
            }
            let refresh = try encoder.encode(["refresh" : refreshToken])
            sessionManager.upload(refresh, to: url)
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

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        if request.url?.absoluteString.hasSuffix("/refresh/") == false {
            let accessHeader = HTTPHeader(name: "Authorization", value: "JWT \(KeychainWrapper.standard.string(forKey: "accessToken") ?? "")")
            request.headers.update(accessHeader)
        }
        let contentTypeHeader = HTTPHeader(name: "Content-Type", value: "application/json")
        request.headers.update(contentTypeHeader)
        completion(.success(request))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard request.retryCount < retryLimit else {
            completion(.doNotRetry)
            return
        }

        refreshToken { result in
            switch result {
            case .success(_):
                return completion(.retry)
            case .failure(_):
                return completion(.doNotRetry) // TODO: do not retry - sign in
            }
        }
    }
}
