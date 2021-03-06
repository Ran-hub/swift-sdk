import Foundation
import CommonCrypto

class RolloutEvaluator {
    func evaluate<Value>(json: Any?, key: String, user: User?) -> Value? {
        guard let json = json as? [String: Any] else {
            return nil
        }
        
        guard let user = user else {
            return json["Value"] as? Value
        }
        
        if let rules = json["RolloutRules"] as? [[String: Any]] {
            for rule in rules {
                if let comparisonAttribute = rule["ComparisonAttribute"] as? String,
                    let comparisonValue = rule["ComparisonValue"] as? String,
                    let comparator = rule["Comparator"] as? Int,
                    let userValue = user.getAttribute(for: comparisonAttribute) {
                    
                    if comparisonValue.isEmpty || userValue.isEmpty {
                        continue
                    }
                    
                    switch comparator {
                    case 0:
                        let splitted = comparisonValue.components(separatedBy: ",")
                            .map {val in val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)}
                        
                        if splitted.contains(userValue) {
                            return rule["Value"] as? Value
                        }
                    case 1:
                        let splitted = comparisonValue.components(separatedBy: ",")
                            .map {val in val.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)}
                        
                        if !splitted.contains(userValue) {
                            return rule["Value"] as? Value
                        }
                    case 2:
                        if userValue.contains(comparisonValue) {
                            return rule["Value"] as? Value
                        }
                    case 3:
                        if !userValue.contains(comparisonValue) {
                            return rule["Value"] as? Value
                        }
                    default:
                        continue
                    }
                }
            }
        }
        
        if let rules = json["RolloutPercentageItems"] as? [[String: Any]] {
            
            if(rules.count > 0){
                let hashCandidate = key + user.identifier
                if let hash = hashCandidate.sha1hex?.prefix(7) {
                    let hashString = String(hash)
                    if let num = Int(hashString, radix: 16) {
                        let scaled = num % 100
                        
                        var bucket = 0
                        for rule in rules {
                            if let percentage = rule["Percentage"] as? Int {
                                bucket += percentage
                                if scaled < bucket {
                                    return rule["Value"] as? Value
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return json["Value"] as? Value
    }
}

fileprivate extension String {
    var sha1hex: String? {
        if let utf8Data = data(using: .utf8, allowLossyConversion: false) {
            return utf8Data.digestSHA1.hexString
        }
        return nil
    }
}

fileprivate extension Data {
    var digestSHA1: Data {
        var bytes: [UInt8] = Array(repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(count), &bytes)
        }
        return Data(bytes: bytes)
    }
    
    var hexString: String {
        return map { String(format: "%02x", UInt8($0)) }.joined()
    }
}
