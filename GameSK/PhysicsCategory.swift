import Foundation

enum PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let playerBullet: UInt32 = 0b10
    static let enemy: UInt32 = 0b100
}
