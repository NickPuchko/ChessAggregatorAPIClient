import Foundation

/// Helper at date formatting
class DateStringer {
    static let shared: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ru_RU")
        return dateFormatter
    }()
    private init() {}
}

struct UserReg: Codable {
    var profile: Profile
    var email: String
    var isOrganizer: Bool
    var password: String
}

struct Profile: Codable {
    var surname: String
    var name: String
    var patronymic: String?
    var sex: String
    var birthdate: String
    var latinName: String?
    var fideId: Int?
    var frcId: Int?
    var classicFideRating: Int?
    var rapidFideRating: Int?
    var blitzFideRating: Int?
    var classicFrcRating: Int?
    var rapidFrcRating: Int?
    var blitzFrcRating: Int?
}

struct UserGet: Codable {
    var profile: Profile
    var email: String
    var id: Int
    var isOrganizer: Bool
}

struct UserEdit: Codable {
    var surname: String?
    var name: String?
    var patronymic: String?
    var latinName: String?
    var sex: String?
    var fideId: Int?
    var frcId: Int?
    var isOrganizer: Bool?
}

struct Participant: Codable {
    var player: UserGet // player -> profile
    var status: ParticipantStatus
}

struct ManualParicipant: Codable {
    var email: String?
    var surname: String
    var name: String
    var patronymic: String?
    var sex: String
    var birthdate: String?
    var latinName: String?
    var fideId: Int?
    var frcId: Int?
}

struct TournamentReg: Codable {
    var name: String
    var location: String
    var openDate: String
    var closeDate: String
    var url: String?
    var prizeFund: Int
    var fee: Int
    var tours: Int
    var ratingType: String
    var mode: String
    var minutes: Int
    var seconds: Int
    var increment: Int
}

struct TournamentGet: Codable {
    var id: Int
    var organizer: Int
    var name: String
    var location: String
    var openDate: String
    var closeDate: String
    var url: String?
    var prizeFund: Int
    var fee: Int
    var tours: Int
    var ratingType: String
    var mode: String
    var status: String
    var minutes: Int
    var seconds: Int
    var increment: Int
}

enum RequestError: Error {
    case url
    case decoding
    case encoding
    case network
    case keychain
    case emailInUse
    case serverInternal
}
