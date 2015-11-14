import UIKit
import CoreLocation
import AVFoundation

class ViewController: UIViewController, UIScrollViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {

    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var imageview: UIImageView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    var plotImage: UIImageView? = nil
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollview.minimumZoomScale = 1.0
        self.scrollview.maximumZoomScale = 5.0
        
        self.imageview.userInteractionEnabled = true
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        
        imageview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "imageClicked:"))
        displayCurrentUser()
    }
    
    func imageClicked(gesture: UIGestureRecognizer){
        let location = gesture.locationInView(gesture.view)
        
        let actionType = getActionValue(location.x, y: location.y)
        
        if actionType != "" {
            getBuildingDetails(actionType)
        }else{
            let alert = UIAlertController(title: "Details Not Available", message: "Sorry, we don't have any details for this location.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageview
    }
    
    func getActionValue(x: CGFloat, y: CGFloat) -> String{
        var action = "";
        if (x>=11.0 && x<=63.0 && y>=222.0 && y<=297.0){
            action = "KING"
        }else if (x>=144.0 && x<=202.0 && y>=94.0 && y<=190.0){
            action = "ENG"
        }else if (x>=177.0 && x<=243.0 && y>=419.0 && y<=509.0){
            action = "SPG"
        }else if (x>=70.0 && x<=107.0 && y>=385.0 && y<=439.0){
            action = "YUH"
        }else if (x>=270.0 && x<=306.0 && y>=148.0 && y<=194.0){
            action = "BBC"
        }else if (x>=174.0 && x<=225.0 && y>=175.0 && y<=230.0){
            action = "SU"
        }
        return action
    }
    
    func getBuildingLocation(actionType: String) -> String{
        var buildingLocation = "";
        
        if(actionType == "KING"){
            buildingLocation = "37.335455,-121.884565"
        }else if(actionType == "ENG"){
            buildingLocation = "37.337139,-121.881321"
        }else if(actionType == "YUH"){
            buildingLocation = "37.333753,-121.882766"
        }else if(actionType == "SU"){
            buildingLocation = "37.336310,-121.880675"
        }else if(actionType == "BBC"){
            buildingLocation = "37.336496,-121.878341"
        }else if(actionType == "SPG"){
            buildingLocation = "37.333062,-121.880221"
        }
        
        return buildingLocation
    }
    
    func getCurrentUserLocation() -> String{
        var userLocation = ""
        
        let currentLocation = locationManager.location
        var longi: Double = -121.883407
        var latti: Double = 37.335182
        if currentLocation != nil{
            longi = currentLocation!.coordinate.longitude
            latti = currentLocation!.coordinate.latitude
        }else{
            self.locationManager.startUpdatingLocation()
            func LocationManagers(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
                longi = manager.location!.coordinate.latitude
                latti = manager.location!.coordinate.longitude
            }
        }
        
        let userLongitude = "\(longi)"
        let userLattitude = "\(latti)"
        userLocation = userLattitude+","+userLongitude
        
        return userLocation
    }
    
    func getBuildingDetails(actionType: String){
        let userLocation = getCurrentUserLocation()
        let buildingLocation = getBuildingLocation(actionType)
        
        var distance = ""
        var duration = ""
        
        let customUrl = "https://maps.googleapis.com/maps/api/distancematrix/json?origins="+userLocation+"&destinations="+buildingLocation+"&key=AIzaSyBY7jPTJvAsFYoRFwDTShq55fakY73h0-Y"
        
        let url = NSURL(string: customUrl)
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            do{
                let jsonResult = try (NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary)
                let rowArray = jsonResult["rows"] as! NSArray
                
                for row in rowArray {
                    
                    let obj = row as! NSDictionary
                    
                    for (_, value) in obj {
                        let elementArray = value as! NSArray
                        for element in elementArray{
                            let innerObj = element as! NSDictionary
                            
                            for(key2, value2) in innerObj{
                                let name = key2 as! String
                                if(name == "distance"){
                                    let distanceObj = value2 as! NSDictionary
                                    for(key3, value3) in distanceObj{
                                        let keyName = key3 as! String
                                        if(keyName == "text"){
                                            distance = value3 as! String
                                        }
                                    }
                                }
                                
                                if(name == "duration"){
                                    let durationObj = value2 as! NSDictionary
                                    for(key3, value3) in durationObj{
                                        let keyName = key3 as! String
                                        if(keyName == "text"){
                                            duration = value3 as! String
                                        }
                                    }
                                }
                            }
                            
                            self.startNewScreen(actionType, distance: distance, duration: duration)
                        }
                    }
                    
                }
            }catch{
                print(error)
            }
        }
        
        task.resume()
    }
    
    func startNewScreen(actionType: String, distance: String, duration: String){
        dispatch_async(dispatch_get_main_queue()){
            let vc = self.storyboard!.instantiateViewControllerWithIdentifier("BuildingDetailsPage") as! BuildingDetailsView
            vc.useraction = actionType
            vc.travelDistance = distance
            vc.travelDuration = duration
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func saveDataClicked(sender: AnyObject) {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(self.scrollview.zoomScale, forKey: "zoomDefaultLevel")
        defaults.synchronize()
    }
    
    @IBAction func loadDataClicked(sender: AnyObject) {
        
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if let defaultZoomLevel = defaults.objectForKey("zoomDefaultLevel") as? CGFloat {
            self.scrollview.zoomScale = defaultZoomLevel
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if(plotImage != nil){
            plotImage!.removeFromSuperview()
            plotImage = nil
        }
        
        let searchText = searchBar.text?.lowercaseString
        
        if(searchText == "king library"){
            let scrollPoint = CGPointMake(-35, 1000)
            plotImage = UIImageView(frame:CGRectMake(36, 262, 15, 15))
            zoomImage(scrollPoint)
        }else if(searchText == "engineering building"){
            let scrollPoint = CGPointMake(680, 445)
            plotImage = UIImageView(frame:CGRectMake(176, 142, 15, 15))
            zoomImage(scrollPoint)
        }else if (searchText == "yoshihiro uchida hall"){
            let scrollPoint = CGPointMake(250, 1800)
            plotImage = UIImageView(frame:CGRectMake(89, 421, 15, 15))
            zoomImage(scrollPoint)
        }else if(searchText == "student union"){
            let scrollPoint = CGPointMake(820, 740)
            plotImage = UIImageView(frame:CGRectMake(200, 200, 15, 15))
            zoomImage(scrollPoint)
        }else if (searchText == "bbc"){
            let scrollPoint = CGPointMake(1300, 530)
            plotImage = UIImageView(frame:CGRectMake(293, 170, 15, 15))
            zoomImage(scrollPoint)
        }else if (searchText == "south parking garage"){
            let scrollPoint = CGPointMake(850, 2030)
            plotImage = UIImageView(frame:CGRectMake(207, 467, 15, 15))
            zoomImage(scrollPoint)
        }else{
            let alertController = UIAlertController(title: "Search Failed", message:"Wrong Search. Choose from King Library, Engineering Building, Yoshihiro Uchida Hall, Student Union, BBC, South Parking Garage", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default,handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
    }
    
    func zoomImage(scrollPoint: CGPoint){
        scrollview.setZoomScale(5, animated: false)
        scrollview.setContentOffset(scrollPoint, animated: false)
        plotImage!.image = UIImage(named:"green.png")
        self.imageview.addSubview(plotImage!)
    }
    
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        if(plotImage != nil){
            plotImage!.removeFromSuperview()
            plotImage = nil
        }
        let scrollPoint = CGPointMake(0, 0)
        scrollview.setZoomScale(1, animated: false)
        scrollview.setContentOffset(scrollPoint, animated: false)
        searchBar.text = ""
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    func displayCurrentUser(){
        
        let currentLocation = locationManager.location
        var longi: Double = -121.883407
        var latti: Double = 37.335182
        if currentLocation != nil{
            longi = currentLocation!.coordinate.longitude
            latti = currentLocation!.coordinate.latitude
        }else{
            self.locationManager.startUpdatingLocation()
            func LocationManagers(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
                longi = manager.location!.coordinate.latitude
                latti = manager.location!.coordinate.longitude
            }
        }
        plotUser(latti,userLongitude: longi)
    }
    
    func plotUser(userLatitude: Double, userLongitude: Double) {
        let bounds = UIScreen.mainScreen().bounds
        let width = bounds.size.width
        let height = bounds.size.height
        let imageHeight = height
        let imageWidth = width
        
        let x_new = Double (imageWidth) * (fabs(userLongitude)  - 121.886478) / (121.876243 - 121.886478)
        let y_new = Double( imageHeight) - (Double( imageHeight) * (fabs(userLatitude)-37.331361)/(37.338800-37.331361))
        var pinImageView : UIImageView
        
        pinImageView = UIImageView(frame: CGRectMake(CGFloat(x_new), CGFloat( y_new), 15, 15))
        
        pinImageView.image = UIImage(named: "red.png")
        self.imageview.addSubview(pinImageView)
        
    }
}
