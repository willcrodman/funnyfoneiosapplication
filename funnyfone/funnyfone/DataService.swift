//
//  JokeList.swift
//  funnyfone
//
//  Created by William Rodman on 6/12/17.
//  Copyright © 2017 William Rodman. All rights reserved.
//

import Foundation
import CoreData

class DataSerivce {
    
    static var instance = DataSerivce()
    
    func loadJokes() -> [String] {
        var arrayOfJokes: [String]?
        do {
            if let path = Bundle.main.path(forResource: "Funny Fone Jokes (Txt. DataSerice)", ofType: "txt"){
                let jokes = try String(contentsOfFile:path, encoding: String.Encoding.utf16)
                arrayOfJokes = jokes.components(separatedBy: "\n")
                print("WCR loading txt. file into joke array")
            }
        } catch let error as NSError {
            let errorHandeler = "An Error Occurred 😬: \(error)"
            print("WCR  error loading txt. file to joke array")
            return [errorHandeler]
        }
        return arrayOfJokes!
    }
}
