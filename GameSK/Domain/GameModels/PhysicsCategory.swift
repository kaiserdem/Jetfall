import Foundation

enum PhysicsCategory {
    static let none: Int = 0
    static let player: Int = 0b1
    static let playerBullet: Int = 0b10
    static let enemy: Int = 0b100
    static let fuelPickup: Int = 0b1000
}
