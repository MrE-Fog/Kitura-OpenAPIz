/**
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import XCTest
import Kitura
@testable import KituraOpenAPI

// To allow the openAPI generation to work, a codable route must be registered.

// This handler is needed for the get codable route. 
func getPearHandler(completion: (Pear?, RequestError?) -> Void ) -> Void {                                           
    let pear = Pear(id: "1", name: "a pear")
    completion(pear, nil)                                                                                             
}                                                                                                                    
                                                                                                                         
final class KituraOpenAPITests: KituraTest {

    static var allTests = [
        ("testDefaultAPIPAth", testDefaultAPIPath),
        ("testDefaultSwaggerUIPath", testDefaultSwaggerUIPath),
        ("testCustomAPIPath", testCustomAPIPath),
        ("testCustomSwaggerUIPath", testCustomSwaggerUIPath),
    ]
    
    override class func tearDown() {
        guard var sourcesDirectory = Utils.localSourceDirectory else {
            XCTFail("Could not locate local source directory")
            return
        }
        
        sourcesDirectory += "/swaggerui/index.html"
        let fileURL = URL(fileURLWithPath: sourcesDirectory)
        let fm = FileManager.default
        do {
           try fm.removeItem(at: fileURL)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    func testDefaultAPIPath() {
        let router = Router()
        KituraOpenAPI.addEndpoints(to: router)

        router.get("/me/pear", handler: getPearHandler)

        performServerTest(router, sslOption: .httpOnly) { expectation in
            self.performRequest("get", path: "/openapi", callback: { response in
                if let response = response {
                    if let json = (try? response.readString()).flatMap({ $0 }) {
                        let regex = try? NSRegularExpression(pattern: "\"description\" *: *\"Generated by Kitura\"")
                        XCTAssertEqual(regex?.numberOfMatches(in: json, range: NSRange(location: 0, length: json.count)), 1, "Kitura swagger is incorrect")
                    } else {
                        XCTFail("Swagger was not returned from \"/openapi\"")
                    }
                }
                expectation.fulfill()
            })
        }
    }

    func testDefaultSwaggerUIPath() {
        let router = Router()
        KituraOpenAPI.addEndpoints(to: router)

        router.get("/me/pear", handler: getPearHandler)

        performServerTest(router, sslOption: .httpOnly) { expectation in
            self.performRequest("get", path: "/openapi/ui", callback: { response in
                if let response = response {
                    if let html = (try? response.readString()).flatMap({ $0 }) {
                        XCTAssertTrue(html.contains("<title>Kitura Swagger UI</title>"), "Kitura swagger ui was not served.")
                        XCTAssertTrue(html.contains("url: \"/openapi\","), "Kitura swagger ui data source is incorrect")
                    }
                }
                expectation.fulfill()
            })
        }
    }

    func testCustomAPIPath() {
        let router = Router()
        let config = KituraOpenAPIConfig(apiPath: "cheese", swaggerUIPath: "toasty")
        KituraOpenAPI.addEndpoints(to: router, with: config)

        router.get("/me/pear", handler: getPearHandler)

        performServerTest(router, sslOption: .httpOnly) { expectation in
            self.performRequest("get", path: "/cheese", callback: { response in
                if let response = response {
                    if let json = (try? response.readString()).flatMap({ $0 }) {
                        let regex = try? NSRegularExpression(pattern: "\"description\" *: *\"Generated by Kitura\"")
                        XCTAssertEqual(regex?.numberOfMatches(in: json, range: NSRange(location: 0, length: json.count)), 1, "Kitura swagger is incorrect")
                    } else {
                        XCTFail("Swagger was not returned from \"/toasty\"")
                    }
                }
                expectation.fulfill()
            })
        }
    }

    func testCustomSwaggerUIPath() {
        let router = Router()
        let config = KituraOpenAPIConfig(apiPath: "cheese", swaggerUIPath: "toasty")
        KituraOpenAPI.addEndpoints(to: router, with: config)

        router.get("/me/pear", handler: getPearHandler)

        performServerTest(router, sslOption: .httpOnly) { expectation in
            self.performRequest("get", path: "/toasty", callback: { response in
                if let response = response {
                    if let html = (try? response.readString()).flatMap({ $0 }) {
                        XCTAssertTrue(html.contains("<title>Kitura Swagger UI</title>"), "Kitura swagger ui was not served.")
                        XCTAssertTrue(html.contains("url: \"/cheese\","), "Kitura swagger ui data source is incorrect")
                    }
                }
                expectation.fulfill()
            })
        }
    }
}
