//
//  SettingsVC.swift
//  funnyfone
//
//  Created by William Rodman. 2017.
//  Copyright © 2017 William Rodman. All rights reserved.
//  All assets and graphics are not for permitted use or distribution.
//

import UIKit
import UserNotifications
import CoreData

class SettingsVC: UIViewController {
    
    //temp
    @IBOutlet weak var tempLoadingLbl: UILabel!
    @IBOutlet weak var tempActivitySpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var setSelectedTimeBtnRef: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var pickerViewHeaderLbl: UILabel!
    @IBOutlet weak var resetBtnRef: UIButton!
    
    var notifAuthStatus: Bool!
    var jokesAreActive: Bool!
    var didSelectDate: Bool!
    var selectedDate: String!
    var popUpMessageSender: String!
    var cd = [CoreData]()
    let jokes: [String] = DataSerivce.instance.loadJokes()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppUtility.lockOrientation(.portrait)
        DispatchQueue.main.async {
            self.viewActivationLoading(loading: false)
        }
        fetchData()
        if jokesAreActive != nil {
            screenSettingTrans(jokesAreActive: jokesAreActive)
        }
        self.datePicker.addTarget(self, action: #selector(SettingsVC.configSelectedUIDate(datePicker:)), for: UIControlEvents.valueChanged)
        requestNotifAuth()
        didSelectDate = false
    }
    
    @IBAction func setSelectedTimeBtn(sender: UIButton) {
        requestNotifAuth()
        if didSelectDate == false  {
            popUpAlert(title: "You didn't select a time.", message: "Toggle the time picker on the screen to choose a time you want to receive daily jokes.", sender: "_")
        }
        guard notifAuthStatus != true || didSelectDate != true else {
            jokesAreActive = true
            selectedDate = configSelectedUIDate(datePicker: datePicker)
            viewActivationLoading(loading: true)
            screenSettingTrans(jokesAreActive: jokesAreActive)
            activateNotifications(completion: {
                DispatchQueue.main.async {
                    self.viewActivationLoading(loading: false)
                }
                self.pickerViewHeaderLbl.text = "Currently sending jokes at \(self.configDateForUI(date: self.selectedDate))"
                self.popUpAlert(title: "Activation Successful!", message: "We will send you jokes daily at \( self.configDateForUI(date: self.selectedDate)) starting now.", sender: "_")
            })
            
            storeData()
            return print("WCR  activate btn pressed. Time Selected : \(configSelectedUIDate(datePicker: datePicker)))")
        }
    }
    
    @IBAction func resetBtn(_ sender: UIButton) {
        popUpAlert(title: "Are you sure?", message: "Resetting Funny Fone will allow you to change the time you selected and receive all previous sent jokes.", sender: "resetBtn")
    }
    
    func activateNotifications(completion: @escaping () -> () ) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.subtitle = "Time for your daily dosage of jokes!"
        for jInx in 0 ..< jokes.count {
            notificationContent.body = formatJokeForNotifs(string: jokes[jInx])
            let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: notificationTimeInterval(index: jInx), repeats: false)
            let notificationRequest = UNNotificationRequest(identifier: "FFNotif\(jokes[jInx])", content: notificationContent, trigger: notificationTrigger)
            print("WCR  Joke no. \(jInx) set countdown time : \(notificationTimeInterval(index: jInx))")
            print("WCR  Joke no. \(jInx) : \(notificationContent.body)")
            UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                if error != nil {
                    self.popUpAlert(title: "An Error Occurred 😬", message: "Funny Fone's jokes notifications could not be activated. Delete this app, then reinstall Funny Fone and try again.", sender: "_")
                    print("WCR  notifs did not push : \(error.debugDescription)")
                } else {
                    if jInx == (self.jokes.count - 1) {
                        completion()
                    }
                    print("WCR  joke no. \(jInx) notif request sent")
                }
            }
        }
    }
    
    func screenSettingTrans(jokesAreActive: Bool) {
        self.setSelectedTimeBtnRef.isHidden = jokesAreActive
        self.datePicker.isHidden = jokesAreActive
        if jokesAreActive == true {
            self.pickerViewHeaderLbl.text = "Currently sending jokes at \(self.configDateForUI(date: self.selectedDate))"
        } else {
            self.pickerViewHeaderLbl.text = "Select time you want to receive jokes."
        }
    }
    
    func popUpAlert(title: String, message: String, sender: String) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.alert)
        popUpMessageSender = sender
        switch popUpMessageSender {
        case "resetBtn":
            let resetBtn = UIAlertAction(title: "Reset", style: UIAlertActionStyle.destructive, handler: { (_) in
                self.reset()
            })
            let cancelBtn = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(cancelBtn)
            alertController.addAction(resetBtn)
            break
        case "_":
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
            break
        default:
            alertController.addAction(UIAlertAction(title: sender, style: UIAlertActionStyle.default, handler: nil))
            break
        }
        self.present(alertController, animated: true, completion: nil)
    }
    
    func configSelectedUIDate(datePicker: UIDatePicker) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        let _selectedDate: String = formatter.string(from: datePicker.date)
        pickerViewHeaderLbl.text = "Time selected: \(configDateForUI(date: _selectedDate))"
        didSelectDate = true
        print("WCR  datepicker time : \(_selectedDate)")
        return _selectedDate
    }
    
    func notificationTimeInterval(index: Int) -> Double {
        let oneDay: Double = 86400
        let selectedDate: Double = datePicker.date.timeIntervalSinceReferenceDate
        let currentDate: Double = NSDate().timeIntervalSinceReferenceDate
        if selectedDate > currentDate {
            let notifDate = ((selectedDate - currentDate) + (oneDay * Double(index)))
            return notifDate
        } else {
            let notifDate = (oneDay + (selectedDate - currentDate) + (oneDay * Double(index)))
            return notifDate
        }
    }
    
    func reset() {
        let coreData = CoreData(context: contex)
        coreData.jokesAreActive = false
        coreData.selectedDate = nil
        jokesAreActive = false
        selectedDate = nil
        screenSettingTrans(jokesAreActive: jokesAreActive)
        print("WCR  reset fuction is called")
    }
    
    func requestNotifAuth() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound]) { (granted, error) in
            if granted {
                self.notifAuthStatus = true
                print("WCR  acsses to user notifs is : \(granted)")
            } else {
                self.popUpAlert(title: "Notifications Are Required", message: "IOS notifications are required to send you jokes. To allow Funny Phone to use notifications go to: Settings >> Notifications >> Funny Fone >> Allow Notifications.", sender: "_")
                print("WCR  acsses to user notifs denied : \(error.debugDescription)")
            }
        }
    }
    
    func formatJokeForNotifs(string: String) -> String {
        let stringMod = string.description.replacingOccurrences(of: "\"", with: "")
        return stringMod
    }
    
    func fetchData() {
        do {
            cd = try contex.fetch(CoreData.fetchRequest())
            for data in cd {
                guard (data.jokesAreActive == false) || (data.selectedDate == nil) else {
                    jokesAreActive = data.jokesAreActive
                    selectedDate = data.selectedDate
                    return print("WCR data caught from cd : selected date (\(String(describing: data.selectedDate))) and joke are active stat (\(data.jokesAreActive))")
                }
            }
        } catch {
            popUpAlert(title: "An Error Occurred 😬", message: "There was a problem retriving your informations. Delete this app, then reinstall Funny Fone and try again.", sender: "_")
            print("An Error Occurred 😬: \(cd.debugDescription)")
        }
    }
    
    func storeData() {
        let coreData = CoreData(context: contex)
        guard jokesAreActive == nil || selectedDate == nil else {
            coreData.jokesAreActive = jokesAreActive
            coreData.selectedDate = selectedDate
            return print("WCR  data saved to to cd: selected date (\(String(describing: coreData.selectedDate))) and joke are active stat (\(coreData.jokesAreActive)) ")
        }
    }
    
    func viewActivationLoading(loading: Bool) {
        //        let loadingViewAssets = ["black loading background img", "Loading Pop-Up"]
        //        let loadingBackgroundImg = UIImage(named: loadingViewAssets[0])
        //        let loadingMessageImg = UIImage(named: loadingViewAssets[1])
        //        let loadingWheelStyle = UIActivityIndicatorViewStyle.gray
        //        let loadingBackground = UIImageView(image: loadingBackgroundImg)
        //        let loadingMessage = UIImageView(image: loadingMessageImg)
        //        let loadingWheel = UIActivityIndicatorView(activityIndicatorStyle: loadingWheelStyle)
        //        let screenViewWidth = self.view.bounds.size.width
        //        let screenViewHeight = self.view.bounds.height
        if loading == true {
            
            //temp
            tempActivitySpinner.startAnimating()
            tempLoadingLbl.isHidden = false
            
            //            loadingBackground.frame = CGRect(x: 0 , y: 0, width: screenViewWidth, height: screenViewHeight)
            //            loadingMessage.frame = CGRect(x: (screenViewWidth / 2) - 125, y: (screenViewHeight / 2) - 150, width: 250, height: 300)
            //            loadingWheel.frame = CGRect(x: 0 , y: 0, width: screenViewWidth, height: screenViewHeight)
            //            loadingBackground.alpha = 0.75
            //            view.addSubview(loadingBackground)
            //            loadingBackground.addSubview(loadingMessage)
            //            loadingBackground.addSubview(loadingWheel)
            //            loadingWheel.startAnimating()
            //            loadingWheel.isHidden = false
            //            loadingMessage.isHidden = false
            //            loadingBackground.isHidden = false
            //            resetBtnRef.isUserInteractionEnabled = false
            //            self.view.updateConstraints()
        } else {
            
            //temp
            tempActivitySpinner.stopAnimating()
            tempLoadingLbl.isHidden = true
            
            //            loadingWheel.stopAnimating()
            //            loadingWheel.isHidden = true
            //            loadingMessage.isHidden = true
            //            loadingBackground.isHidden = true
            //            loadingBackground.removeFromSuperview()
            //            view.willRemoveSubview(loadingBackground)
            //            self.resetBtnRef.isUserInteractionEnabled = true
            //            self.view.updateConstraints()
        }
    }
    
    func configDateForUI(date: String) -> String {
        let dateMod1 = date.description.replacingOccurrences(of: "Optional(", with: "")
        let dateMod2 = dateMod1.description.replacingOccurrences(of: "((", with: "")
        let dateMod3 = dateMod2.description.replacingOccurrences(of: ")", with: "")
        let dateMod4 = dateMod3.description.replacingOccurrences(of: "))", with: "")
        let dateMod5 = dateMod4.description.replacingOccurrences(of: "\"", with: "")
        return dateMod5
    }
}
