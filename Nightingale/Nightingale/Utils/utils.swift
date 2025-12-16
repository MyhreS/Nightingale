
func extractSoundCloudUserId(userId: String) -> String {
    userId.replacingOccurrences(of: "soundcloud:users:", with: "")
}
