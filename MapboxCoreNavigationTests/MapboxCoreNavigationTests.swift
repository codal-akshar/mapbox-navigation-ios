import XCTest
import MapboxDirections
@testable import MapboxCoreNavigation

let response = Fixture.JSONFromFileNamed(name: "route")
let jsonRoute = (response["routes"] as! [AnyObject]).first as! [String : Any]
let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
let directions = Directions(accessToken: "pk.feedCafeDeadBeefBadeBede")
let route = Route(json: jsonRoute, waypoints: [waypoint1, waypoint2], routeOptions: RouteOptions(waypoints: [waypoint1, waypoint2]))

let waitForInterval: TimeInterval = 5

class MapboxCoreNavigationTests: XCTestCase {
    
    func testDepart() {
        let navigation = RouteController(along: route, directions: directions)
        navigation.resume()
        let depart = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165), altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 0, speed: 10, timestamp: Date())
        
        self.expectation(forNotification: RouteControllerAlertLevelDidChange.rawValue, object: navigation) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 2)
            
            let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as? RouteProgress
            let userDistance = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
            
            return routeProgress != nil && routeProgress?.currentLegProgress.alertUserLevel == .depart && round(userDistance) == 384
        }
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [depart])
        
        waitForExpectations(timeout: waitForInterval)
    }
    
    func testLowAlert() {
        let navigation = RouteController(along: route, directions: directions)
        navigation.resume()
        let user = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.789118, longitude: -122.432209), altitude: 1, horizontalAccuracy: 1, verticalAccuracy: 1, course: 171, speed: 10, timestamp: Date())
        
        self.expectation(forNotification: RouteControllerAlertLevelDidChange.rawValue, object: navigation) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 2)
            
            let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as? RouteProgress
            let userDistance = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
            
            return routeProgress?.currentLegProgress.alertUserLevel == .low && routeProgress?.currentLegProgress.stepIndex == 2 && round(userDistance) == 1758
        }
        
        navigation.routeProgress.currentLegProgress.stepIndex = 2
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [user])
        
        waitForExpectations(timeout: waitForInterval)
    }
    
    func testShouldReroute() {
        let navigation = RouteController(along: route, directions: directions)
        navigation.resume()
        
        let reroutePoint1 = CLLocation(latitude: 38, longitude: -123)
        let reroutePoint2 = CLLocation(latitude: 38, longitude: -124)
        
        self.expectation(forNotification: RouteControllerWillReroute.rawValue, object: navigation) { (notification) -> Bool in
            XCTAssertEqual(notification.userInfo?.count, 1)
            
            let location = notification.userInfo![RouteControllerNotificationLocationKey] as? CLLocation
            return location == reroutePoint2
        }
        
        navigation.locationManager(navigation.locationManager, didUpdateLocations: [reroutePoint1])
        
        _ = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { timer in
            navigation.locationManager(navigation.locationManager, didUpdateLocations: [reroutePoint2])
        }
        
        waitForExpectations(timeout: waitForInterval)
    }
}
