import SwiftUI
import Foundation
let root = CommandLine.arguments[1]
let bundle = Bundle(path: root + "/en.lproj")!
let category = "outcome"
let keyName = "success"
let dynamicKey = LocalizedStringKey("settings.localDiagnostics.\(category).\(keyName).label")
let rating = 0
let ratingKey = LocalizedStringKey("scoreStudy.feedback.rating.\(rating).label")
let concreteString: String = "settings.localDiagnostics.\(category).\(keyName).label"
let concreteKey = LocalizedStringKey(concreteString)
for (name,key) in [("diagnostic interpolation",dynamicKey),("rating interpolation",ratingKey),("explicit String",concreteKey)] {
 let storageKey = Mirror(reflecting:key).children.first { $0.label == "key" }!.value as! String
 print(name, "key:",storageKey,"localized:",bundle.localizedString(forKey: storageKey, value:nil, table:nil))
}
