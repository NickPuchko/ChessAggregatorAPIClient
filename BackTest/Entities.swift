//
//  Entities.swift
//  BackTest
//
//  Created by Administrator on 12.02.2021.
//

import Foundation


struct User: Codable {
    var id: Int
    var surname: String
    var name: String
    var patronymic: String?
    var birthdate: Date
    var sex: Sex
    var isOrganizer: Bool
    var player: Player

    init(userResponse: UserGet) {
        id = userResponse.id
        surname = userResponse.profile.surname
        name = userResponse.profile.name
        patronymic = userResponse.profile.patronymic
        birthdate = DateStringer.shared.date(from: userResponse.profile.birthdate) ?? Date()
        sex = Sex(rawValue: userResponse.profile.sex) ?? .male
        isOrganizer = userResponse.isOrganizer
        player = Player(latinName: userResponse.profile.latinName,
                        fideID: userResponse.profile.fideId,
                        classicFideRating: userResponse.profile.classicFideRating,
                        rapidFideRating: userResponse.profile.rapidFideRating,
                        blitzFideRating: userResponse.profile.blitzFideRating,
                        frcID: userResponse.profile.frcId,
                        classicFrcRating: userResponse.profile.classicFrcRating,
                        rapidFrcRating: userResponse.profile.rapidFrcRating,
                        blitzFrcRating: userResponse.profile.blitzFrcRating)
    }
}

struct Player: Codable {
    var latinName: String? 
    var fideID: Int?
    var classicFideRating: Int?
    var rapidFideRating: Int?
    var blitzFideRating: Int?
    var frcID: Int?
    var classicFrcRating: Int?
    var rapidFrcRating: Int?
    var blitzFrcRating: Int?
}

enum Sex: String, Codable, CaseIterable {
    case male = "Мужчина"
    case female = "Женщина"
}

struct Tournament: Identifiable, Equatable, Codable {
    var id: Int
    var organizerId: Int
    var name: String
    var mode: Mode
    var openDate: Date
    var closeDate: Date
    var location: String
    var ratingType: RatingType
    var tours: Int
    var minutes: Int
    var seconds: Int
    var increment: Int
    var prizeFund: Int
    var fee: Int
    var status: EventStatus
    var url: URL?

    init(eventResponse: TournamentGet) {
        id = eventResponse.id
        organizerId = eventResponse.organizer
        name = eventResponse.name
        mode = Mode(rawValue: eventResponse.mode) ?? .classic
        openDate = DateStringer.shared.date(from: eventResponse.openDate) ?? Date()
        closeDate = DateStringer.shared.date(from: eventResponse.closeDate) ?? Date()
        location = eventResponse.location
        ratingType = RatingType(rawValue: eventResponse.ratingType) ?? .without
        tours = eventResponse.tours
        minutes = eventResponse.minutes
        seconds = eventResponse.seconds
        increment = eventResponse.increment
        prizeFund = eventResponse.prizeFund
        fee = eventResponse.fee
        url = URL(string: eventResponse.url ?? "")
        status = EventStatus(rawValue: eventResponse.status) ?? .forthcoming
    }
}

enum Mode: String, Codable, CaseIterable{
    case classic = "Классика", rapid = "Рапид", blitz = "Блиц", bullet = "Пуля", fide = "Классика FIDE", chess960 = "Шахматы 960"
}

enum RatingType: String, Codable, CaseIterable{
    case fide = "FIDE", russian = "ФШР", without = "Без обсчёта"
}

enum ParticipantStatus: String, Codable, CaseIterable {
    case waiting, declined, accepted
}

enum EventStatus: String, Codable {
    case current, forthcoming, completed
}

struct Credential: Codable {
    let email: String
    let password: String
    
    func makeURLCredential() -> URLCredential {
        URLCredential(user: email, password: password, persistence: .synchronizable)
    }
}
